# T3 Code Docker Container Image

[![Build Status](https://github.com/wodby/t3code/workflows/Build%20docker%20image/badge.svg)](https://github.com/wodby/t3code/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/wodby/t3code.svg)](https://hub.docker.com/r/wodby/t3code)

Runs the [T3 Code](https://github.com/pingdotgg/t3code) server, a web interface for coding agents.

## Docker Images

❗For better reliability we release images with stability tags (`wodby/t3code:0-rN`) which correspond to
[git tags](https://github.com/wodby/t3code/releases). We strongly recommend using images only with stability tags.

- Based on Debian Linux: T3 Code's release builds need glibc
- Base image: [node](https://hub.docker.com/_/node)
- [GitHub actions builds](https://github.com/wodby/t3code/actions)
- [Docker Hub](https://hub.docker.com/r/wodby/t3code)

Supported tags:

- `0`, `latest`

All images are built for `linux/amd64` and `linux/arm64`.

## Run it

```bash
docker run --rm -p 3773:3773 -v t3code:/data -e WODBY_PRIMARY_URL=http://localhost:3773 wodby/t3code:0
```

Sign in with a one-time link, which expires after 5 minutes:

```bash
docker exec <container> t3-pairing-link
```

The server is plain HTTP. Put it behind HTTPS before exposing it beyond your machine: the hosted
web app and mobile apps connect to HTTPS addresses only.

## Agents

| Agent | How it gets there |
| --- | --- |
| Codex (`codex`) | In the image |
| OpenCode (`opencode`) | In the image |
| Claude Code (`claude`) | Downloaded from Anthropic to the volume, in the background, on first start. Its license doesn't allow redistributing it in the image |

None of them is signed in. Sign in from T3 Code under **Settings → Providers** or inside the
container with `codex login`, `claude auth login` or `opencode auth login`. Logins stay on the volume.

To add another agent, such as Pi, or a command-line tool, such as `gh`, install it with
`npm install -g` or into `~/.local/bin`. Both stay on the volume and take priority over the image's
tools.

## Storage

`/data` is the home directory of the `node` user (uid 1000). Keep it on a volume: it holds T3 Code's
database, agent logins, Git credentials and `~/projects`, the default working directory.

Run one container per volume. T3 Code's database is a single SQLite file.

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `T3CODE_HOST` | `0.0.0.0` | Address to listen on |
| `T3CODE_PORT` | `3773` | Port to listen on |
| `T3CODE_TELEMETRY_ENABLED` | | Set to `false` to stop [T3 Code's product usage data](https://github.com/pingdotgg/t3code/blob/main/docs/user/telemetry.md) |
| `WODBY_PRIMARY_URL` | | Public address used in the links from `t3-pairing-link` |
| `DEBUG` | | Trace the entrypoint |

T3 Code also reads its own [`T3CODE_*` variables](https://github.com/pingdotgg/t3code). Agents inherit
the container's environment, so `ANTHROPIC_API_KEY` and `OPENAI_API_KEY` work as well.

## Sandboxing

Codex's **Supervised** and **Auto** modes run commands in a sandbox that needs unprivileged user
namespaces. Where the container runtime blocks them, use **Full access**, T3 Code's default for new
threads, or allow them for the container. **Full access** relies on the container as the boundary, so
keep credentials you don't want an agent to use out of it.
