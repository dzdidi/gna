#!/bin/bash
set -e

if ! [ -x "$(command -v nak)" ]; then
  echo 'Error: nak is not installed.' >&2
  echo 'Please install nak from https://github.com/fiatjaf/nak/tree/master'
fi

HOOK=`cat <<'EOF'
#!/bin/sh\n
\n
url="$2"\n
zero=$(git hash-object --stdin </dev/null | tr '[0-9a-f]' '0')\n
commit=$(git rev-parse HEAD)\n
privKey=$(cat ~/.nostr/key | jq -r '.private_key')\n
EVENT="{\"content\":\"\",\"kind\":27235,\"created_at\":$(date +%s),\"tags\":[[\"u\",\"$url\"],[\"method\",\"push\"],[\"payload\",\"$commit\"]]}"\n
SIGNED=$(echo -n $EVENT | nak event -sec $privKey)\n
NOSTR_AUTH_HEADER=$(echo -n $SIGNED | base64 -w 0)\n
git config http.$url.extraHeader "X-Authorization: Nostr $NOSTR_AUTH_HEADER"\n
EOF
`


APP_HOME="$HOME/.nostr"
SK_PATH="$APP_HOME/key"

if [ -d $APP_HOME ]; then
  echo "$APP_HOME already exists. Skipping..."
else
  echo "Creating $APP_HOME"
  mkdir $APP_HOME
fi

if [ -f $SK_PATH ]; then
   echo "$SK_PATH already exists. Skipping..."
else
  echo "Please insert you NSEC:"
  read -s SK
  echo $(nak decode $SK) > $SK_PATH
fi

read -p "Provide path to git repository or press \"Enter\" to use curent directory:" GIT_REPO
GIT_REPO=${GIT_REPO:-.}

if [ ! -d "$GIT_REPO/.git" ]; then
  echo "$GIT_REPO is not a directory. Exiting..."
  exit 1
fi

echo "Installing git hooks..."
if [ -f "$GIT_REPO/.git/hooks/pre-push" ]; then
  echo "pre-push hook already exists. Skipping..."
else
  echo "Installing pre-push hook..."
  echo -e $HOOK >> $GIT_REPO/.git/hooks/pre-push
  chmod +x $GIT_REPO/.git/hooks/pre-push
fi

echo "Done!"

