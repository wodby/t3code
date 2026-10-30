#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

mkdir -p "${HOME}/projects"
cd "${HOME}/projects"

# The server must not wait for this download. T3 Code finds Claude Code once it is installed.
if ! command -v claude >/dev/null; then
    (install-claude-code &)
fi

exec "${@}"
