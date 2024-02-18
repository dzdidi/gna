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

if ! [ -x "$(command -v awk)" ]; then
  echo 'Error: awk is not installed.' >&2
  echo 'Please install awk from https://www.gnu.org/software/gawk/'
fi

if ! [ -x "$(command -v age)" ]; then
  echo 'Error: age is not installed.' >&2
  echo 'Please install age from https://github.com/FiloSottile/age'
fi

echo "Please insert you NSEC:"
read -s SK
DECODED=$(nak decode $SK)
PUBLIC_KEY=$(echo $DECODED | jq -r .pubkey)
PRIVATE_KEY=$(echo $DECODED | jq -r .private_key)
mkdir -p ~/.nostr
PASS_PATH="~/.nostr/$PUBLIC_KEY"

echo $PRIVATE_KEY | age -e -o ~/.nostr/$PUBLIC_KEY -R ~/.ssh/id_rsa.pub -i ~/.ssh/id_rsa

read -p "Provide path to git repository or press \"Enter\" to use curent directory:" GIT_REPO
GIT_REPO=${GIT_REPO:-.}

if [ ! -d "$GIT_REPO/.git" ]; then
  echo "$GIT_REPO is not a directory. Exiting..."
  exit 1
fi

HOOK=`cat <<'EOF'
#!/bin/sh\n
COMMIT=$(git rev-parse HEAD)\n
\n
URLS=$(git remote -v | awk '/\(fetch\)/ {print $2} /\(push\)/ {print $3}' | awk -F' ' '{for(i=1;i<=NF;i++) if($i ~ /http/) print $i}')\n
\n
for url in $URLS; do\n
  privKey=$(age -d -i ~/.ssh/id_rsa PASS_PATH)\n
 EVENT="{\"content\":\"\",\"kind\":27235,\"created_at\":$(date +%s),\"tags\":[[\"u\",\"$url\"],[\"method\",\"push\"],[\"payload\",\"$COMMIT\"]]}"\n
\n
 SIGNED=$(echo -n $EVENT | nak event -sec $privKey)\n
 NOSTR_AUTH_HEADER=$(echo -n $SIGNED | base64 -w 0)\n
 git config http.$url.extraHeader "X-Authorization: Nostr $NOSTR_AUTH_HEADER"\n
done\n
\n
EOF
`
PASS_PATH=$(sed 's/\//\\\//g' <<< "$PASS_PATH")
PATTERN="s/PASS_PATH/$PASS_PATH/g"
HOOK=$(sed "$PATTERN" <<< "$HOOK")

echo "Installing git hooks..."
if [ -f "$GIT_REPO/.git/hooks/post-commit" ]; then
  echo "post-commit hook already exists. Skipping..."
else
  echo "Installing post-commit hook..."
  echo -e $HOOK >> $GIT_REPO/.git/hooks/post-commit
  chmod +x $GIT_REPO/.git/hooks/post-commit
fi

echo "Done!"
