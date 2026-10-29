# dotfiles

chezmoi source for `~/.config` and home dotfiles. macOS and Linux.

## Bootstrap

New machine, at home (locker on the LAN):

```sh
sh -c "$(curl -fsLS https://raw.githubusercontent.com/jearle/dotfiles/main/install.sh)"
```

1. Public pass: Command Line Tools, Homebrew, packages, config, tools.
2. `bw` login to `locker.jesseearle.com` (master password, typed).
3. Secrets pass: `~/.ssh/config`, ssh keys, `secrets.zsh`, WireGuard.

Existing machine, secrets refresh:

```sh
BW_SESSION=$(bw unlock --raw) chezmoi apply
```

## Layout

- Repository root: chezmoi source state.
- `.chezmoi.toml.tmpl`: config data (`os`, `hostname`); refuses other OSes.
- `.chezmoiignore.tmpl`: per-OS ignores.
- `archive/`: pre-chezmoi `.config/`, `powershell/`, `zsh/`; not applied.

Plan and decisions: slice `dotfiles` (`~/repos/vault/01-inbox/dotfiles/`).
