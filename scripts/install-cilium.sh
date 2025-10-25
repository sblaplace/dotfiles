#!/usr/bin/env bash
set -euo pipefail

echo "Installing Cilium CNI with XDP..."

# Install Cilium CLI if not present
if ! command -v cilium &> /dev/null; then
    echo "Installing Cilium CLI..."
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
    CLI_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
    rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
fi

# Install Cilium
cilium install \
  --version 1.14.5 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=neovenezia.local \
  --set k8sServicePort=6443 \
  --set routingMode=native \
  --set autoDirectNodeRoutes=true \
  --set ipv4NativeRoutingCIDR=10.42.0.0/16 \
  --set loadBalancer.acceleration=native \
  --set bpf.masquerade=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# Wait for Cilium to be ready
echo "Waiting for Cilium to be ready..."
cilium status --wait

# Run connectivity test
echo "Running Cilium connectivity test..."
cilium connectivity test

# Enable Hubble UI
echo "Enabling Hubble UI..."
cilium hubble enable --ui

echo ""
echo "✅ Cilium installed successfully!"
echo ""
echo "Access Hubble UI with:"
echo "  cilium hubble ui"
echo ""
echo "Check status with:"
echo "  cilium status"
echo ""
echo "View flows with:"
echo "  hubble observe"