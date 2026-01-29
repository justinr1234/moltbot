#!/bin/bash
set -e

# Initialize molt workspace on first run
if [ ! -f /home/molt/.molt/initialized ]; then
    echo "Initializing molt workspace..."
    mkdir -p /home/molt/.molt
    mkdir -p /home/molt/workspace
    
    # Create welcome README
    cat > /home/molt/workspace/README.md << 'EOF'
# Welcome to your Molt! 🦞

Your per-second billed development environment is ready.

## Getting Started

1. This workspace is persisted to `/home/molt/workspace`
2. SSH available on port 22
3. Web UI available on port 8080
4. Node.js 22, Python 3, and common tools are pre-installed

## Commands

```bash
# Check node version
node --version

# Check python version
python3 --version

# Install a project
git clone https://github.com/yourname/project
cd project
npm install
```

## Auto-suspend

Your molt will auto-suspend after 1 minute of inactivity to save costs.
It will automatically wake up when you reconnect.

Happy coding!
EOF
    
    touch /home/molt/.molt/initialized
    echo "Molt workspace initialized"
fi

# Security services are started by supervisor
# UFW is configured but not enabled in container (Fly.io handles firewall)

# Execute the main command (supervisor starts as root, manages all services)
exec "$@"
