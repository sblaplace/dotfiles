# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS and Home Manager configuration repository that manages multiple machines including:
- Desktop workstations (neovenezia - NVIDIA gaming rig, t450 - ThinkPad laptop, precision7730 - Dell laptop)
- Raspberry Pi cluster nodes (raspi01-07 running k3s Kubernetes cluster)
- Jetson development board

The repository uses Nix flakes for reproducible builds and deployments, with integrated k3s cluster management using Cilium CNI.

## Common Commands

### System Management
```bash
# Rebuild NixOS system configuration
sudo nixos-rebuild switch --flake ~/dotfiles#$(hostname)

# Update Home Manager only (for non-NixOS systems like Raspberry Pis)
home-manager switch --flake ~/dotfiles#laplace@$(hostname)

# Update flake inputs (get latest packages)
nix flake update

# Show available configurations
nix flake show

# Garbage collect old generations
sudo nix-collect-garbage -d
```

### Deployment and Installation
```bash
# Install NixOS on a new machine
./install.sh <hostname> <target-ip> [disk-password]
# Examples:
./install.sh neovenezia 192.168.1.100 mypassword
./install.sh raspi01 192.168.1.50

# Deploy to existing machines using deploy-rs
deploy .#<hostname>

# Bootstrap entire k3s cluster (first time only)
nix run .#bootstrap-cluster

# Deploy entire cluster
nix run .#deploy-cluster
```

### K3s Cluster Management
```bash
# Install Cilium CNI after k3s bootstrap
./scripts/install-cilium.sh

# Check cluster status
kubectl get nodes
kubectl get pods -A

# Cilium specific commands
cilium status
cilium connectivity test
cilium hubble ui
hubble observe
```

## Architecture

### Directory Structure
- `flake.nix` - Main flake configuration defining all systems and deployment targets
- `hosts/` - NixOS system configurations per machine
- `home/` - Home Manager configurations with modular structure
- `modules/` - Shared NixOS modules (k3s, common configs, hardware-specific)
- `cluster/` - Kubernetes manifests for ArgoCD and core services
- `secrets/` - SOPS-encrypted secrets (k3s tokens, etc.)

### K3s Cluster Design
- High availability control plane: neovenezia (primary) + raspi01 (secondary)
- Worker nodes: t450, precision7730, raspi02-07, jetson
- Cilium CNI with native routing, kube-proxy replacement, and Hubble observability
- BGP load balancing for external services
- Monitoring stack with Prometheus, Grafana, and Loki

### Home Manager Integration
- Shared base configuration in `home/laplace.nix`
- Modular configs: fish shell, kitty terminal, git, development tools
- Desktop-only modules loaded conditionally based on hostname
- Machine-specific overrides in `home/machines/`

## Key Technologies
- **NixOS**: Declarative Linux distribution
- **Home Manager**: Dotfiles and user environment management
- **Kubernetes (k3s)**: Lightweight Kubernetes distribution
- **Cilium**: eBPF-based networking and security
- **SOPS**: Secrets management with age/SSH key encryption
- **deploy-rs**: NixOS deployment tool
- **Disko**: Declarative disk partitioning
- **ArgoCD**: GitOps continuous deployment

## SOPS Secrets Management
Secrets are encrypted using SSH host keys. To decrypt:
```bash
# Secrets are automatically available at runtime in /run/secrets/
# Example: k3s server token at config.sops.secrets.k3s-server-token.path
```

## Development Workflow
1. Make configuration changes in appropriate module files
2. Test locally with `sudo nixos-rebuild switch --flake .#$(hostname)`
3. For cluster changes, deploy with `deploy .#<hostname>` or `nix run .#deploy-cluster`
4. Commit changes - secrets are encrypted and safe to commit