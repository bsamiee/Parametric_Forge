# Parametric Forge

![Nix Flake](https://img.shields.io/badge/Nix-Flake-5277C3?logo=nixos&logoColor=white&style=flat-square)
![nix-darwin](https://img.shields.io/badge/nix--darwin-activate-5277C3?logo=apple&logoColor=white&style=flat-square)
![Home Manager](https://img.shields.io/badge/Home_Manager-24.05-5277C3?logo=nixos&logoColor=white&style=flat-square)
![Cachix](https://img.shields.io/badge/Cachix-bsamiee-00BFA5?logo=cachix&logoColor=white&style=flat-square)
![1Password SSH](https://img.shields.io/badge/SSH-1Password-0061FF?logo=1password&logoColor=white&style=flat-square)
![License](https://img.shields.io/badge/License-MIT-2F855A?style=flat-square)

Parametric Forge is a deterministic macOS environment built on Nix flakes, nix-darwin, and Home Manager. It targets computational design (Rhino/Grasshopper/BIM, heavy media) and modern development (Rust, Lua, Node, Python) with reproducible tooling and strict XDG hygiene.

**Why it exists**
- One rebuild defines GUI apps, CLI tools, Git/LFS, shells, fonts, and defaults.
- 1Password-backed secrets + SSH keep credentials out of the repo.
- CAD/BIM/media formats are first-class via LFS and tuned defaults.

## Quick Start
- Install Nix (Determinate):
  `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
- Sign into 1Password CLI so secrets/SSH can resolve: `op signin <account>`
- Clone wherever you keep configs: `git clone https://github.com/bsamiee/Parametric_Forge.git ~/Parametric_Forge`
- Apply the mac host: `nix run nix-darwin -- switch --flake ~/Parametric_Forge#macbook`
- Rebuild after edits: `darwin-rebuild switch --flake ~/Parametric_Forge#macbook`

## Secrets + SSH (1Password)
- Secrets are referenced, never stored. Template lives at `~/.config/op/env.template`; hydrate commands with:
  `op run --env-file ~/.config/op/env.template -- <command>`
- 1Password SSH agent for all hosts (see `modules/home/programs/shell-tools/ssh.nix`). Enable the agent in the 1Password app; SSH points to `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`.
- GitHub CLI stays writable (`modules/home/programs/git-tools/gh.nix`), so `gh auth login` persists tokens without fighting Home Manager.
- Secret references (GitHub, Cachix, Tavily, Perplexity, Exa) are defined in `modules/home/environments/secrets.nix` and only resolve when wrapped with `op run ...`.

## Repository Map
```text
.
├── flake.nix / flake.lock
├── hosts/
│   └── darwin/default.nix          # macbook host definition
├── modules/
│   ├── common/                     # shared nix daemon settings
│   ├── darwin/                     # macOS defaults + Homebrew bridge
│   └── home/                       # Home Manager modules
│       ├── assets/                 # ascii art + carbon sources/screenshots
│       ├── aliases/                # shell aliases (core, git, nix, media)
│       ├── environments/           # session env + secrets + app vars
│       ├── programs/               # apps, git-tools, languages, nix-tools, shell-tools, zsh
│       ├── scripts/                # integration hooks (nvim, yazi, zellij)
│       └── xdg.nix                 # XDG base directories + scaffolding
└── overlays/                       # yazi overlay + sqlean package
```

## Targets
- `darwin: macbook (aarch64)` with user `bardiasamiee` (nix-homebrew enabled, Rosetta optional).
- Placeholders exist for `homeConfigurations` and `nixosConfigurations` when new hosts are added.

## Stacks
<details>
<summary>Terminal</summary>

- WezTerm with modular Lua config (`appearance.lua`, `keys.lua`, `integration.lua`) + auto-attach to zellij.
- Zellij with Dracula theme, `zjstatus`, and layouts `default` / `stacked`.
- Yazi with theme, `auto-layout`, `piper`, `sidebar-status`, and cd-on-exit handoff.
</details>

<details>
<summary>Shell + prompt</summary>

- Zsh with `fzf-tab`, Atuin, carapace completions, Starship prompt.
- Aliases in `modules/home/aliases/*` cover rsync, networking, data conversion, 1Password helpers.
- XDG-first defaults: `RIPGREP_CONFIG_PATH`, `BAT_CACHE_PATH`, `STARSHIP_CACHE`, etc.
</details>

<details>
<summary>Git, security, transport</summary>

- Git with delta pager, rebase-on-pull, and broad LFS coverage for CAD/BIM/Adobe/media.
- GitHub CLI stays writable; gitleaks, git-quick-stats, lazygit included.
- SSH multiplexing and 1Password SSH agent; sockets in `~/.ssh/sockets`.
</details>

<details>
<summary>Languages & editors</summary>

- Neovim via `lazy.nvim` with modular Lua config.
- Python 3.13 stack (uv, ruff, mypy, numpy/pandas/polars, FastAPI, Textual).
- Node via `fnm` + pnpm; Lua + LSP tooling; SQLite/duckdb with sqlean/spatialite/vec extensions.
</details>

## Carbon code captures
- Managed by Nix: preset → `~/.carbon-now.json` (Dracula + GeistMono) and wrapper → `carbon-now` (Node 20).
- One-time browser download: `carbon-playwright-install` (installs Chromium + headless shell into `~/.cache/ms-playwright`).
- Curated sources live in `modules/home/assets/carbon/sources/` (e.g., `zsh-gh-wrapper.zsh`, `zellij-dracula.nix`, `wezterm-appearance.lua`). Add more there to keep captures consistent.
- Generate PNGs into `modules/home/assets/carbon/`. Examples:
  - `carbon-now modules/home/assets/carbon/sources/zsh-gh-wrapper.zsh --headless --language zsh --save-to modules/home/assets/carbon --save-as zsh-gh-wrapper`
  - `carbon-now modules/home/assets/carbon/sources/zellij-dracula.nix --headless --language nix --save-to modules/home/assets/carbon --save-as zellij-dracula`
  - `carbon-now modules/home/assets/carbon/sources/wezterm-appearance.lua --headless --language lua --save-to modules/home/assets/carbon --save-as wezterm-appearance`

## Gallery (add PNGs after running the commands above)
- Zsh + 1Password-aware gh wrapper  
  ![zsh gh wrapper](modules/home/assets/carbon/zsh-gh-wrapper.png)
- Zellij Dracula palette  
  ![zellij dracula](modules/home/assets/carbon/zellij-dracula.png)
- WezTerm appearance (Dracula + GeistMono)  
  ![wezterm appearance](modules/home/assets/carbon/wezterm-appearance.png)

## Featured snippets
- SSH via 1Password (`modules/home/programs/shell-tools/ssh.nix`):
```nix
programs.ssh = {
  enable = true;
  extraConfig = ''
    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  '';
  matchBlocks.github.com = {
    user = "git";
    identitiesOnly = true;
    addKeysToAgent = "yes";
  };
};
```

- Zellij Dracula palette (`modules/home/programs/apps/zellij/themes/dracula.nix`):
```nix
colors = {
  background = { hex = "#15131F"; r = 21; g = 19; b = 31; };
  purple     = { hex = "#A072C6"; r = 160; g = 114; b = 198; };
  cyan       = { hex = "#94F2E8"; r = 148; g = 242; b = 232; };
  green      = { hex = "#50FA7B"; r = 80; g = 250; b = 123; };
};
```

- LFS coverage for design assets (`modules/home/programs/git-tools/git.nix`):
```nix
attributes = [
  "*.3dm filter=lfs diff=lfs merge=lfs -text"
  "*.gh filter=lfs diff=lfs merge=lfs -text"
  "*.rvt filter=lfs diff=lfs merge=lfs -text"
  "*.dwg filter=lfs diff=lfs merge=lfs -text"
  "*.psd filter=lfs diff=lfs merge=lfs -text"
  "*.mp4 filter=lfs diff=lfs merge=lfs -text"
];
```

- XDG scaffolding for secrets and SSH (`modules/home/xdg.nix`):
```nix
xdg.configFile."op/env.template".text = ''
  GITHUB_TOKEN="op://Tokens/Github Token/token"
  GH_TOKEN="op://Tokens/Github Token/token"
  PERPLEXITY_API_KEY="op://Tokens/Perplexity Sonar API Key/token"
  CACHIX_AUTH_TOKEN="op://Tokens/Cachix Auth Token - Parametric Forge/token"
  TAVILY_API_KEY="op://Tokens/Tavily Auth Token/token"
  EXA_API_KEY="op://Tokens/Exa API Key/token"
'';

home.activation.createHomeDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
  mkdir -pm 700 "${config.home.homeDirectory}/.ssh/sockets"
'';
```

## Maintenance
- Format: `nix fmt`.
- Dev shell with linters: `nix develop` → `deadnix .`, `statix .`.
- Rebuild: `darwin-rebuild switch --flake ~/Parametric_Forge#macbook` (or `nix run nix-darwin -- switch ...` for fresh installs).
- Update inputs: `nix flake update`; cache push is automatic if `CACHIX_AUTH_TOKEN` is present.

## License
MIT © [Bardia Samiee](https://github.com/bsamiee)
