#!/bin/sh
set -e

command=($BASH_COMMAND)

if [[ command[0] -eq 'clone']] ; then
  echo "base64 of the following json:"
# {
#   "id": "<id>",
#   "pubkey": "<read pub key >",
#   "content": "",
#   "kind": 27235,
#   "created_at": $(date +%s),
#   "tags": [
#     ["u", $command[1]],
#     ["method", $command[0]],
#   ],
#   "sig": "<signature>"
# }

elif [[ command[0] -eq 'push' ]]; then
  commit=$(git rev-parse HEAD)
  echo "base64 of the following json:"
# {
#   "id": "<id>",
#   "pubkey": "<read pub key >",
#   "content": "",
#   "kind": 27235,
#   "created_at": $(date +%s),
#   "tags": [
#     ["u", $command[1]],
#     ["method", $command[0]],
#     ["payload", $commit],
#   ],
#   "sig": "<signature>"
# }
else
  echo "Error: command not supported" >&2
  exit 1
fi
