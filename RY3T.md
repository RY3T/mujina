# RY3T mujina

This is RY3T's mujina: github.com/RY3T/mujina, a fork of
[256foundation/mujina](https://github.com/256foundation/mujina). It runs on
the Amlogic control boards (S19j Pro, S19k Pro) of every Nova site.

## Branches and repositories

- **`main` on github.com/RY3T/mujina is the only source of what we deploy.**
  Every binary on a miner is built from a tagged commit on it.
- `upstream` (256foundation/mujina) and `skot` (skot/mujina) are the projects
  we take from and contribute to. Upstream changes come into `main` by a merge
  that is tested on the lab miner and then released like any other change.
- `Schnitzel/mujina` (branch `ry3t`) is the old home of this code and is no
  longer used. `ry3t-v1.0.0` is its last state plus the commissioning
  endpoints.

Remotes in a local clone:

```bash
git remote add origin   git@github.com:RY3T/mujina.git
git remote add upstream https://github.com/256foundation/mujina.git
git remote add skot     https://github.com/skot/mujina.git
```

## Versions

Tags `ry3t-vMAJOR.MINOR.PATCH` (semver; the prefix keeps them apart from
upstream's tags). `ry3t-v1.0.0` (2026-11-13) is the binary deployed on sites 1
and 2 since 2026-11-03.

`build.rs` embeds `git describe --tags --match 'ry3t-v*' --dirty` as the
version. The miner logs it at startup (`mujina-minerd starting
version=...`) and serves it at `GET /api/v0/version`:

| Reported | Means |
|---|---|
| `ry3t-v1.1.0` | exactly that release |
| `ry3t-v1.1.0-3-gabc1234` | 3 commits past it, a test build |
| `...-dirty` | built from uncommitted changes: never deploy that to a site |

`ry3t-v1.0.0` predates this and reports nothing: identify it by its SHA-256
`246ceb9d…a909`.

## Releasing

```bash
git checkout main && git pull
scripts/ry3t-release.sh ry3t-v1.1.0            # optional 2nd arg: notes file
```

It refuses a dirty tree or a `main` that differs from origin, tags HEAD,
builds `mujina-minerd` for `aarch64-unknown-linux-musl`, checks the binary
carries the tag, and publishes `mujina-minerd-aarch64` + `SHA256SUMS` as a
GitHub release. Deploy only release binaries, and check the SHA-256 on the
board after copying.
