#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running with sufficient arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <hostname> <target-ip> [disk-password]"
    echo ""
    echo "Examples:"
    echo "  $0 neovenezia 192.168.1.100 mypassword    # Install neovenezia"
    echo "  $0 raspi01 192.168.1.50                   # Install raspi (no encryption)"
    echo ""
    echo "Available hosts:"
    nix flake show --json | jq -r '.nixosConfigurations | keys[]'
    exit 1
fi

HOSTNAME=$1
TARGET=$2
DISK_PASSWORD=${3:-""}

print_info "Starting installation of $HOSTNAME on $TARGET"

# Create temporary password file if needed
if [ -n "$DISK_PASSWORD" ]; then
    print_info "Creating temporary password file"
    echo -n "$DISK_PASSWORD" > /tmp/secret.key
    trap "rm -f /tmp/secret.key" EXIT
fi

# Check if host exists in flake
if ! nix flake show --json | jq -e ".nixosConfigurations.\"$HOSTNAME\"" > /dev/null; then
    print_error "Host $HOSTNAME not found in flake"
    exit 1
fi

# Test SSH connection
print_info "Testing SSH connection to $TARGET..."
if ! ssh -o ConnectTimeout=5 root@$TARGET 'echo SSH connection successful' > /dev/null 2>&1; then
    print_error "Cannot connect to root@$TARGET via SSH"
    print_warn "Make sure:"
    print_warn "  1. Target is booted into NixOS installer or has SSH enabled"
    print_warn "  2. Root login is enabled (PermitRootLogin yes)"
    print_warn "  3. You have SSH keys set up or password authentication enabled"
    exit 1
fi

# Copy secrets if they exist
if [ -n "$DISK_PASSWORD" ]; then
    print_info "Copying disk password to target"
    scp /tmp/secret.key root@$TARGET:/tmp/secret.key
fi

# Run nixos-anywhere
print_info "Starting nixos-anywhere installation..."
print_warn "This will WIPE ALL DATA on the target disk!"
read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    print_info "Installation cancelled"
    exit 0
fi

nixos-anywhere --flake ".#$HOSTNAME" root@$TARGET

print_info "Installation complete!"
print_info "The machine will reboot. After reboot, you can deploy updates with:"
print_info "  deploy .#$HOSTNAME"