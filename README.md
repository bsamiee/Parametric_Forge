# Parametric Forge

![Nix](https://img.shields.io/badge/Nix-5277C3?style=for-the-badge&logo=nix&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Home Manager](https://img.shields.io/badge/Home_Manager-5277C3?style=for-the-badge&logo=nix&logoColor=white)
![Zsh](https://img.shields.io/badge/Zsh-F1502F?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

**Parametric Forge** is a rigorous, deterministic, and modular macOS configuration built on **Nix**, **nix-darwin**, and **Home Manager**. 

Designed at the intersection of **software engineering** and **computational design**, this repository provides a reproducible environment that seamlessly handles both heavy architectural workflows (CAD, BIM, 3D modeling) and modern development practices (Rust, Lua, Nix, TypeScript).

---

## 🚀 Philosophy

- **Deterministic**: The entire system state—from kernel settings to GUI applications—is defined in code. No more "it works on my machine."
- **Modular**: Configuration is split into granular, reusable modules (`modules/common`, `modules/darwin`, `modules/home`).
- **Design-Centric**: First-class support for architectural file formats (`.3dm`, `.rvt`, `.dwg`) via extensive Git LFS configurations.
- **Secure**: Deep integration with **1Password** for SSH keys, GitHub tokens, and CLI secrets.

---

## ✨ Key Features

## 🛠 Power Toolchain

This repository implements a highly integrated "terminal-first" workflow, leveraging the most modern Rust-based tools available.

### 🟢 Zellij (Multiplexer)
The core of the terminal experience.
- **Configuration**: Fully declarative `config.kdl` generated via Nix.
- **Plugins**: Pre-loaded with `zjstatus` (WASM-based status bar) for a sleek, informative footer.
- **Layouts**: Custom layouts (`default`, `stacked`) optimized for coding and git workflows.
- **Theme**: Unified **Dracula** theme applied across all panes and plugins.

### 🚀 WezTerm (Emulator)
A GPU-accelerated terminal emulator configured with Lua.
- **Modular Config**: Split into `appearance`, `keys`, `behavior`, and `integration` modules for maintainability.
- **Integration**: Custom event handling to play nicely with Zellij and shell integration.
- **Visuals**: Tuned for high-DPI displays with specific font fallbacks (SF Mono, Nerd Fonts).

### 📂 Yazi (File Manager)
A blazing fast terminal file manager written in Rust.
- **Plugins**:
  - `full-border`: Aesthetic borders for preview panes.
  - `mount`: Quick drive mounting.
  - `piper`: Custom pipe integration.
  - `augment-command`: Enhanced command palette.
- **Integration**: Deep Zsh integration for "cd on exit" behavior.
- **Preview**: Rich previews for code, images, and even 3D formats (where supported).

### 📝 Neovim (Editor)
A fully-featured IDE replacement.
- **Manager**: Built on **lazy.nvim** for lightning-fast startup times.
- **Structure**: Modular `lua/` configuration separating core options, keymaps, and plugins.
- **Remote**: Includes `neovim-remote` for handling nested editing sessions within the terminal.

---

## 🐚 Advanced Shell Environment

### Zsh & Starship
- **Completion**: `fzf-tab` replaces the standard menu with a fuzzy-searchable popup.
- **Prompt**: **Starship** provides instant context (git branch, package version, execution time).
- **Security**: **1Password** integration injects SSH keys and API tokens (GitHub, AWS) only when needed.

### Modern Core Utils
Legacy Unix tools are replaced with modern, faster alternatives:
- `ls` → **eza** (Icons, git status, tree view)
- `cat` → **bat** (Syntax highlighting, git integration)
- `man` → **batman** (Bat-styled man pages)
- `cd` → **zoxide** (Smart directory jumping based on frecency)
- `grep` → **ripgrep** (Faster, smarter search)
- `find` → **fd** (User-friendly find)

---

## 📂 Repository Structure

```graphql
.
├── flake.nix             # Entry point (Inputs & Outputs)
├── hosts/                # Host-specific configurations
│   └── darwin/           # macOS machine definitions (e.g., "macbook")
├── modules/              # Reusable configuration modules
│   ├── common/           # Shared across all systems
│   ├── darwin/           # macOS system settings (Homebrew, Dock, etc.)
│   └── home/             # User-space config (Home Manager)
│       ├── programs/     # Individual tool configs (git, zsh, neovim)
│       ├── apps/         # GUI app configs (wezterm, alacritty)
│       └── scripts/      # Custom shell scripts
└── overlays/             # Custom package overlays
```

---

## ⚡️ Quick Start

### Prerequisites
1. **Install Nix**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Enable Flakes**:
   Ensure `experimental-features = nix-command flakes` is in your `/etc/nix/nix.conf`.

### Bootstrap
Clone the repository and apply the configuration:

```bash
# Clone to your preferred location
git clone https://github.com/bsamiee/Parametric_Forge.git ~/.config/nix

# Apply the configuration (replace 'macbook' with your host name if different)
nix run nix-darwin -- switch --flake ~/.config/nix#macbook
```

---

## 🔧 Configuration Highlights

### Git LFS for Architects
The Git configuration is specifically tuned for parametric design workflows, with LFS attributes pre-defined for:
- **Rhino**: `.3dm`, `.gh`, `.ghx`
- **Revit**: `.rvt`, `.rfa`
- **AutoCAD**: `.dwg`, `.dxf`
- **Adobe**: `.psd`, `.ai`, `.indd`

### 1Password Integration
The shell environment automatically hooks into 1Password:
- **SSH Agent**: Seamless git authentication.
- **CLI Plugins**: Auth for `gh` (GitHub CLI), `aws`, and more without manual token management.
- **Secret Management**: Environment variables injected securely.

---

## 📜 License

MIT © [Bardia Samiee](https://github.com/bsamiee)
