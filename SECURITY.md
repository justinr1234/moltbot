# Molt VM Security Hardening

This document describes the security measures implemented in the Molt base image.

## SSH Hardening

### Authentication
- **Key-only authentication**: Password authentication is disabled
- **No root password login**: Root can only use SSH keys
- **Public key required**: `PubkeyAuthentication yes`
- **No empty passwords**: `PermitEmptyPasswords no`

### Connection Limits
- **Max auth tries**: 3 attempts before disconnect
- **Login grace time**: 60 seconds to authenticate
- **Client keepalive**: 300 seconds interval, 2 max failures
- **No X11 forwarding**: Disabled for reduced attack surface

### SSH Config (`/etc/ssh/sshd_config`)
```
PasswordAuthentication no
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
MaxAuthTries 3
LoginGraceTime 60
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
```

## fail2ban - Brute Force Protection

fail2ban monitors `/var/log/auth.log` and automatically bans IPs that fail authentication.

### Configuration (`/etc/fail2ban/jail.d/sshd.local`)
```
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5      # 5 failed attempts
bantime = 3600    # 1 hour ban
findtime = 600    # within 10 minute window
```

### Monitoring
```bash
# Check banned IPs
sudo fail2ban-client status sshd

# Unban an IP
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

## Network Security

Fly.io handles network-level firewall:
- Only ports defined in `fly.toml` are exposed (22, 8080)
- No direct internet access to other ports
- Fly.io Wireguard mesh for private networking

## Logging

- **rsyslog**: Runs in container for auth logging
- **Auth logs**: `/var/log/auth.log`
- **fail2ban logs**: `/var/log/molt/fail2ban.log`
- **SSH logs**: `/var/log/molt/sshd.log`

## Known Attack Patterns

Based on observed attacks (ref: @the_smart_ape):
- Automated SSH brute-force (11K+ attempts/24h from single IP)
- Chinese IP ranges targeting AI/dev servers
- Attempts to exfiltrate API keys and credentials

## Best Practices for Users

1. **Never commit secrets** to git
2. **Use environment variables** for API keys
3. **Review authorized_keys** periodically
4. **Check auth.log** for suspicious activity

## Supervisor Services

Security services managed by supervisor:
- `rsyslog` (priority 10) - Auth logging
- `fail2ban` (priority 50) - Brute force protection
- `sshd` (priority 100) - SSH server
- `webui` (priority 200) - Web interface (runs as molt user)
