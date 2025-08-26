#!/bin/bash

# Raspberry Pi SSH hardening and user setup
# This script ensures the primary user is 'jannisreufsteck', configures SSH, key-based auth, firewall, and enables the ssh service.
# Safe to run multiple times (idempotent where possible).

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "${EUID}" -ne 0 ]; then
  err "Please run with sudo/root"
  exit 1
fi

PRIMARY_USER="jannisreufsteck"
PRIMARY_HOME="/home/${PRIMARY_USER}"
SSH_DIR="${PRIMARY_HOME}/.ssh"
AUTH_KEYS="${SSH_DIR}/authorized_keys"

info "Ensuring user '${PRIMARY_USER}' exists and has sudo access..."
if id -u "${PRIMARY_USER}" >/dev/null 2>&1; then
  info "User ${PRIMARY_USER} already exists"
else
  # Create user with home directory and bash shell
  adduser --disabled-password --gecos "" "${PRIMARY_USER}"
  info "User ${PRIMARY_USER} created"
fi

# Ensure user is in sudo group
if id -nG "${PRIMARY_USER}" | grep -qE '(sudo)'; then
  info "User ${PRIMARY_USER} already in sudo group"
else
  usermod -aG sudo "${PRIMARY_USER}"
  info "Added ${PRIMARY_USER} to sudo group"
fi

# Optional: lock the default 'pi' user if present for security
if id -u pi >/dev/null 2>&1; then
  warn "Locking default 'pi' user (still present)."
  usermod -L pi || true
  usermod -s /usr/sbin/nologin pi || true
fi

info "Ensuring SSH service is installed, enabled, and running..."
apt-get update
apt-get install -y openssh-server ufw
systemctl enable ssh
systemctl restart ssh

info "Setting up SSH directory and authorized_keys for ${PRIMARY_USER}..."
mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
chown -R "${PRIMARY_USER}:${PRIMARY_USER}" "${SSH_DIR}"

echo ""
echo "If you have a public key on this machine, paste it now. Otherwise, leave empty to skip."
echo "Example key starts with 'ssh-ed25519' or 'ssh-rsa'"
read -r -p "Paste public key (single line), or press Enter to skip: " PUBKEY || true
if [ -n "${PUBKEY:-}" ]; then
  grep -qxF "${PUBKEY}" "${AUTH_KEYS}" 2>/dev/null || echo "${PUBKEY}" >> "${AUTH_KEYS}"
fi

# Ensure permissions
if [ -f "${AUTH_KEYS}" ]; then
  chmod 600 "${AUTH_KEYS}"
  chown "${PRIMARY_USER}:${PRIMARY_USER}" "${AUTH_KEYS}"
  info "authorized_keys configured"
else
  warn "No authorized_keys file yet. You can add keys later to ${AUTH_KEYS}"
fi

info "Hardening SSH configuration..."
mkdir -p /etc/ssh/sshd_config.d
CONF_FILE="/etc/ssh/sshd_config.d/99-thirst-track-security.conf"

# Create or update secure config
cat > "${CONF_FILE}" <<'EOF'
# Thirst Track Security Configuration

PermitRootLogin no
Protocol 2
# PasswordAuthentication will be disabled once key-based auth is confirmed working
# To force keys immediately, uncomment the next line:
# PasswordAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
MaxStartups 2
X11Forwarding no
ChallengeResponseAuthentication no
UsePAM yes
LoginGraceTime 30
# Limit SSH access to the main user
AllowUsers jannisreufsteck
AllowAgentForwarding no
AllowTcpForwarding no
GatewayPorts no
PermitTunnel no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
EOF

# Validate sshd config
if sshd -t; then
  systemctl reload ssh
  info "sshd configuration valid and reloaded"
else
  err "sshd configuration invalid; not reloading. Please check ${CONF_FILE}"
fi

info "Configuring firewall (UFW) to allow SSH and web..."
ufw --force enable || true
ufw allow 22/tcp || true
ufw allow OpenSSH || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true

# Optional: limit rate for SSH to mitigate brute force
ufw limit 22/tcp || true

info "Current UFW status:"
ufw status verbose || true

# Ensure correct ownership of home path
chown -R "${PRIMARY_USER}:${PRIMARY_USER}" "${PRIMARY_HOME}" || true

# Helpful connection hint
IP=$(hostname -I | awk '{print $1}') || true
echo ""
echo "You can now try connecting from your computer:"
echo "  ssh ${PRIMARY_USER}@${IP:-<PI_IP>}"

echo "To disable password auth after confirming key login works:"
echo "  sudo sed -i 's/^#\? PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config.d/99-thirst-track-security.conf && sudo systemctl reload ssh"

info "SSH setup complete."
