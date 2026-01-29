# moltbot 🦞

Base VM image for [molt.new](https://molt.new) — per-second billed development environments.

## What's Inside

- **Ubuntu 24.04 LTS** with security hardening
- **Node.js 22 LTS** + pnpm, yarn, TypeScript, tsx
- **Python 3** + pip, venv
- **SSH** with key-only auth, fail2ban brute-force protection
- **Supervisor** process manager (sshd, fail2ban, rsyslog, web UI)
- **Welcome page** served on `:8080`

## Container Image

```bash
docker pull ghcr.io/justinr1234/moltbot:latest
```

## Run Locally

```bash
docker build -t moltbot .
docker run -p 8080:8080 -p 2222:22 moltbot
# Visit http://localhost:8080
```

## Deploy to Fly.io

```bash
fly launch --copy-config --name my-molt
fly deploy
```

## Security

See [SECURITY.md](./SECURITY.md) for hardening details.

## Ports

| Port | Service |
|------|---------|
| 8080 | Web UI (serve) |
| 22   | SSH |
