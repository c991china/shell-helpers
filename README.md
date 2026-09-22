# shell-helpers

A pile of bash functions I source into every shell. Not a framework, not a
plugin manager. Just functions that do one thing and are easy to read.

I got tired of re-typing `docker ps --format ...` and `kubectl logs -f ...` in
every new terminal. So now they're in files.

## What's in here

| file | what's in it |
|------|--------------|
| `docker-helpers.sh` | `dsh`, `dlog`, `dclean`, `dstopall` |
| `network-helpers.sh` | `wait_for_port`, `myip`, `ports`, `httphead` |
| `git-helpers.sh` | `groot`, `gwip`, `gprune`, `gwt`, `gbclean` |
| `system-helpers.sh` | `duf`, `psg`, `topcpu`, `extract`, `serve` |
| `k8s-helpers.sh` | `klog`, `kexec`, `kctx`, `kimg`, `krestart` |
| `install.sh` | sources everything from your shell rc |
| `bashrc_snippet.sh` | the block install.sh appends to `~/.bashrc` |

## Install

```bash
git clone https://github.com/c991china/shell-helpers.git ~/.shell-helpers
cd ~/.shell-helpers
./install.sh
```

`install.sh` appends a source block to your `~/.bashrc` (or `~/.zshrc` if you're
on zsh). It writes a marker comment so running it twice doesn't add the block
twice. Open a new shell and the functions are there.

Want it somewhere else:

```bash
SHELL_HELPERS_DIR=~/code/shell-helpers ./install.sh
```

## Usage

```bash
$ wait_for_port localhost 5432
waiting for localhost:5432 ....... ok (2.4s)

$ gwt ../hotfix main
Preparing worktree (new branch 'main')
... created worktree at ../hotfix

$ klog my-pod-7f9c
# tails logs from the pod, follows, no -f to remember
```

Each function has a comment above it with the usage. `declare -f wait_for_port`
prints the definition if you forget.

## Gotchas

- **Don't `set -e` in these files.** They're sourced. `set -euo pipefail` in a
  sourced file changes the behavior of your *interactive shell* and is a great
  way to get logged out by a typo. These files don't do it, and you shouldn't
  add it.
- **`wait_for_port` needs either `nc` or bash's `/dev/tcp`.** It falls back to
  `/dev/tcp`, which is bash-only. On zsh without `nc` installed it won't work.
- **`k8s-helpers` requires `kubectl`.** If it's not on PATH, the functions print
  a message and return instead of erroring. Sourcing the file is still safe.
- **Some functions assume GNU tools.** `duf`, `psg`, `extract` use GNU flags.
  On macOS you'll want `brew install coreutils gnu-sed` and `gsed`. `duf` will
  tell you if it can't find a GNU `du`.
- **Name clashes.** `ports`, `serve`, and `myip` are common names. If you have
  your own, source these files before your overrides, or edit them out.

## Notes

Written for bash 4.4+. Should mostly work in bash 3.2 (macOS) but `wait_for_port`
and anything using `mapfile` will not. zsh support is best-effort: the files
guard on `ZSH_VERSION` where it matters, but I don't run zsh daily, so YMMV.

Shellcheck-clean as of shellcheck 0.10 except for a couple of intentional
`SC1090` (dynamic source) warnings. I run `shellcheck *.sh` before committing.
