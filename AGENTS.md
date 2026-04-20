# AGENTS.md

NixOS/Home Manager configuration for multiple machines with k3s cluster.

## Repository Structure

```
.
├── flake.nix              # Main entrypoint - defines all NixOS configurations
├── hosts/                 # Per-machine NixOS system configs
│   ├── neovenezia/        # Main desktop (x86_64, NVIDIA)
│   ├── raspi01-raspi07/   # Raspberry Pi nodes (aarch64)
│   ├── t450/              # ThinkPad laptop (x86_64)
│   └── precision7730/     # Dell laptop (x86_64)
├── home/                  # Home Manager configs
│   ├── laplace.nix        # Main home config (imports hostname-specific modules)
│   ├── modules/           # Reusable home modules
│   └── machines/          # Per-machine home overrides
├── modules/               # Shared NixOS modules
│   ├── common.nix         # Base config for all machines
│   ├── desktop.nix        # GUI/desktop apps
│   ├── k3s/               # Kubernetes cluster config
│   └── ...
├── secrets/               # SOPS-encrypted secrets
└── install.sh             # Bootstrap new machines via nixos-anywhere
```

## Key Commands

```bash
# Build and switch to new config (current machine)
sudo nixos-rebuild switch --flake .#$(hostname)

# Build home config only (non-NixOS)
home-manager switch --flake .#laplace@$(hostname)

# Update all flake inputs (before applying)
nix flake update

# Check flake evaluates without building
nix flake check

# View available configs
nix flake show

# Garbage collect old generations
sudo nix-collect-garbage -d

# Enter dev shell (loads deploy-rs, sops, kubectl)
nix develop
```

## Adding a New Machine

1. Create `hosts/<hostname>/configuration.nix` and `hardware-configuration.nix`
2. Add entry to `flake.nix` under `nixosConfigurations`
3. (Optional) Create `home/machines/<hostname>.nix` for home overrides
4. Rebuild: `sudo nixos-rebuild switch --flake .#<hostname>`

## Secrets Management

- Uses **sops-nix** with age encryption
- Keys defined in `.sops.yaml`
- Encrypted files in `secrets/`
- Secrets are decrypted at activation and written to `/run/secrets/`

## Home Manager Module Loading

`home/laplace.nix` conditionally imports based on `hostname`:
- `desktop.nix` only on: `neovenezia`, `t450`, `precision7730`
- Machine-specific files auto-imported if they exist: `machines/${hostname}.nix`

## Cluster Deployment

```bash
# Deploy entire k3s cluster
nix run .#deploy-cluster

# Deploy single node
deploy .#<hostname>

# Bootstrap new node (first install)
./install.sh <hostname> <target-ip> [disk-password]
```

## Important Notes

- **neovenezia** uses legacy NVIDIA drivers pinned to `linuxPackages_6_12` (build issues with newer kernels)
- User is always `laplace`, shell is Fish
- Flakes + nix-command are required (enabled in common.nix)
- System state version is `25.05`
- Home state version is `25.05`
- Git config (name/email) lives in `home/modules/git.nix`
- Desktop apps only installed on GUI-enabled machines (checked via `builtins.elem hostname`)
