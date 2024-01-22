#!/bin/bash
set -e

if ! [ -x "$(command -v nak)" ]; then
  echo 'Error: nak is not installed.' >&2
  echo 'Please install nak from https://github.com/fiatjaf/nak/tree/master'
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  echo 'Please install jq from https://stedolan.github.io/jq/download/'
fi

if ! [ -x "$(command -v pass)" ]; then
  echo 'Error: pass is not installed.' >&2
  echo 'Please install pass from https://www.passwordstore.org/'
fi

echo "Please insert you NSEC:"
read -s SK
DECODED=$(nak decode $SK)
PUBLIC_KEY=$(echo $DECODED | jq -r .pubkey)
PRIVATE_KEY=$(echo $DECODED | jq -r .private_key)
PASS_PATH="nostr/$PUBLIC_KEY"
{ echo $PRIVATE_KEY ; echo $PRIVATE_KEY ; } | pass insert $PASS_PATH

read -p "Provide path to git repository or press \"Enter\" to use curent directory:" GIT_REPO
GIT_REPO=${GIT_REPO:-.}

if [ ! -d "$GIT_REPO/.git" ]; then
  echo "$GIT_REPO is not a directory. Exiting..."
  exit 1
fi

HOOK=`cat <<'EOF'
#!/bin/sh\n
\n
url="$2"\n
commit=$(git rev-parse HEAD)\n
privKey=$(pass PASS_PATH)\n
EVENT="{\"content\":\"\",\"kind\":27235,\"created_at\":$(date +%s),\"tags\":[[\"u\",\"$url\"],[\"method\",\"push\"],[\"payload\",\"$commit\"]]}"\n
SIGNED=$(echo -n $EVENT | nak event -sec $privKey)\n
NOSTR_AUTH_HEADER=$(echo -n $SIGNED | base64 -w 0)\n
git config http.$url.extraHeader "X-Authorization: Nostr $NOSTR_AUTH_HEADER"\n
EOF
`
PASS_PATH=$(sed 's/\//\\\//g' <<< "$PASS_PATH")
PATTERN="s/PASS_PATH/$PASS_PATH/g"
HOOK=$(sed "$PATTERN" <<< "$HOOK")

echo "Installing git hooks..."
if [ -f "$GIT_REPO/.git/hooks/pre-push" ]; then
  echo "pre-push hook already exists. Skipping..."
else
  echo "Installing pre-push hook..."
  echo -e $HOOK >> $GIT_REPO/.git/hooks/pre-push
  chmod +x $GIT_REPO/.git/hooks/pre-push
fi

echo "Done!"
