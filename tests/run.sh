#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

cid="$(docker run -d -e WODBY_PRIMARY_URL=https://t3code.example.com --name "${NAME}" "${IMAGE}")"
trap "docker rm -vf ${cid} > /dev/null" EXIT

run() {
    docker exec "${cid}" "${@}"
}

echo -n "Waiting for the server... "
for _ in $(seq 1 30); do
    if run curl -fsS -o /dev/null http://localhost:3773/.well-known/t3/environment 2>/dev/null; then
        break
    fi
    sleep 1
done
run curl -fsS http://localhost:3773/.well-known/t3/environment | grep -q "\"serverVersion\":\"${T3CODE_VER}\""
echo "OK"

echo -n "Checking the server runs as a regular user... "
[[ "$(run id -u)" == "1000" ]]
[[ "$(run sh -c 'echo ${HOME}')" == "/data" ]]
echo "OK"

echo -n "Checking the session API requires pairing... "
run curl -fsS http://localhost:3773/api/auth/session | grep -q '"authenticated":false'
echo "OK"

echo -n "Checking the pairing link uses the primary URL... "
run t3-pairing-link | grep -q "https://t3code.example.com/pair#token="
echo "OK"

echo -n "Checking agent tools... "
run git --version > /dev/null
run codex --version > /dev/null
run opencode --version > /dev/null
echo "OK"

echo -n "Checking a login shell keeps tools on the volume first... "
run bash -lc 'echo ${PATH}' | grep -q '^/data/.local/bin:'
echo "OK"
