# Sarah's NixOS & Home Manager Configuration

My personal NixOS and Home Manager configurations for managing multiple machines
with shared dotfiles.

## 🖥️ Machines

- **neovenezia** - Dell Aurora R7 (main desktop, NVIDIA, NixOS)
- **t450** - ThinkPad T450 (laptop, NixOS)
- **precision7730** - Dell Precision 7730 (laptop, NixOS)
- **raspi01-07** - Raspberry Pi 4s & 3B (various, standalone Home Manager)

## 📁 Structure

```
.
├── flake.nix              # Main flake configuration
├── hosts/                 # NixOS system configurations
│   ├── neovenezia/
│   ├── t450/
│   └── precision7730/
└── home/                  # Home Manager configurations
    ├── laplace.nix        # Main home config
    ├── modules/           # Modular configs
    └── machines/          # Machine-specific overrides
```

## 🚀 Usage

### NixOS Machines (Full System)

```bash
# Clone the repo
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles

# Copy hardware config
sudo cp /etc/nixos/hardware-configuration.nix ~/dotfiles/hosts/$(hostname)/

# Rebuild system + home
sudo nixos-rebuild switch --flake ~/dotfiles#$(hostname)
```

### Raspberry Pis (Home Manager Only)

```bash
# Install Nix if needed
sh <(curl -L https://nixos.org/nix/install) --daemon

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Clone and apply
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
nix run home-manager/master -- switch --flake ~/dotfiles#laplace@$(hostname)
```

### Adding a New Machine

1. Create host directory: `mkdir -p hosts/newmachine`
2. Copy hardware config:
   `sudo cp /etc/nixos/hardware-configuration.nix hosts/newmachine/`
3. Create `hosts/newmachine/configuration.nix`
4. Add to `flake.nix` under `nixosConfigurations`
5. (Optional) Create `home/machines/newmachine.nix` for machine-specific home
   config

## 🔄 Daily Workflow

```bash
# Update system
sudo nixos-rebuild switch --flake ~/dotfiles#$(hostname)

# Update just home (on non-NixOS)
home-manager switch --flake ~/dotfiles#laplace@$(hostname)

# Update flake inputs (get latest packages)
nix flake update

# Garbage collect old generations
sudo nix-collect-garbage -d
```

## 🛠️ Key Software

- **Shell:** Fish with Starship prompt
- **Terminal:** Kitty
- **Editor:** Helix, VS Code
- **Desktop:** GNOME on NixOS machines
- **Dev:** Node.js, Python, .NET, Typst

## 📝 Notes

- Git configured with user name and email in `home/modules/git.nix`
- Kitty uses FiraCode Nerd Font
- System uses Fish as default shell
- All dotfiles managed through Home Manager for consistency

## 📜 License

MIT - See [LICENSE](LICENSE) for details.
