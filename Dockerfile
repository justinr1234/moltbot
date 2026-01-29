# molt base image
# Based on Ubuntu 24.04 LTS with security hardening

FROM ubuntu:24.04

# Prevent interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# System dependencies + security tools
RUN apt-get update && apt-get install -y \
    # Essential tools
    curl wget git vim nano htop tmux \
    # Build tools
    build-essential pkg-config \
    # Python
    python3 python3-pip python3-venv \
    # Network tools
    ca-certificates openssh-server \
    # Process management
    supervisor \
    # Security hardening
    fail2ban ufw rsyslog \
    # Misc
    jq unzip zip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install global npm packages
RUN npm install -g \
    pnpm \
    yarn \
    typescript \
    tsx

# Create molt user
RUN useradd -m -s /bin/bash molt \
    && echo "molt ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure SSH with security hardening
RUN mkdir -p /run/sshd \
    && ssh-keygen -A

# Harden SSH config (key-only auth, no root password login)
RUN echo '\n\
# Security hardening\n\
PasswordAuthentication no\n\
PermitRootLogin prohibit-password\n\
PubkeyAuthentication yes\n\
PermitEmptyPasswords no\n\
ChallengeResponseAuthentication no\n\
UsePAM yes\n\
X11Forwarding no\n\
MaxAuthTries 3\n\
LoginGraceTime 60\n\
ClientAliveInterval 300\n\
ClientAliveCountMax 2\n\
' >> /etc/ssh/sshd_config

# Configure fail2ban for SSH protection
RUN mkdir -p /etc/fail2ban/jail.d && echo '\
[sshd]\n\
enabled = true\n\
port = ssh\n\
filter = sshd\n\
logpath = /var/log/auth.log\n\
maxretry = 5\n\
bantime = 3600\n\
findtime = 600\n\
' > /etc/fail2ban/jail.d/sshd.local

# Note: UFW firewall not enabled in container (Fly.io handles network security)
# Fly.io only exposes ports defined in fly.toml (8080, 22)

# Create directories
RUN mkdir -p /etc/molt /var/log/molt

# Simple welcome page for testing
RUN mkdir -p /var/www && echo '<!DOCTYPE html><html><head><title>Molt</title><style>body{font-family:system-ui;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;background:#1a1a2e;color:#fff}h1{font-size:4rem;}.molt{color:#00d4ff;}</style></head><body><h1>🦞 <span class="molt">molt</span>.new</h1></body></html>' > /var/www/index.html

# Install simple HTTP server
RUN npm install -g serve

# Supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/molt.conf

# Entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
EXPOSE 8080 22

# Set working directory
WORKDIR /home/molt

# Entrypoint starts as root to init security services, then supervisor drops to molt
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
