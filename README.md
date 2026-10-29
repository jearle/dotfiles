# dotfiles

chezmoi source for `~/.config` and home dotfiles. macOS and Linux.

## Bootstrap

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply jearle
```

Secrets pass (needs WireGuard to `locker.jesseearle.com` and a `bw` login):

```sh
BW_SESSION=$(bw unlock --raw) chezmoi apply
```

Writes the files rendered from locker; the public pass skips them.

Existing machine:

```sh
chezmoi init --apply jearle
```

## Layout

- Repository root: chezmoi source state.
- `.chezmoi.toml.tmpl`: config data (`os`, `hostname`); refuses other OSes.
- `.chezmoiignore.tmpl`: per-OS ignores.
- `archive/`: pre-chezmoi `.config/`, `powershell/`, `zsh/`; not applied.

Plan and decisions: slice `dotfiles` (`~/repos/vault/01-inbox/dotfiles/`).
