#!/usr/bin/env bash
# Build and publish a RY3T mujina release.
#
#   scripts/ry3t-release.sh ry3t-vX.Y.Z [NOTES_FILE]
#
# Releases come only from a clean `main` that equals origin/main
# (github.com/RY3T/mujina). The script tags HEAD, builds mujina-minerd for the
# Amlogic control boards (aarch64 musl), checks the binary reports exactly
# this version, and publishes it with SHA256SUMS as a GitHub release.
set -euo pipefail
die() { echo "!! $*" >&2; exit 1; }

TAG=${1:?usage: scripts/ry3t-release.sh ry3t-vX.Y.Z [NOTES_FILE]}
NOTES=${2:-}
[[ $TAG =~ ^ry3t-v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "tag must look like ry3t-v1.2.3"
cd "$(git rev-parse --show-toplevel)"
TARGET=aarch64-unknown-linux-musl
BIN=target/$TARGET/release/mujina-minerd

[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || die "check out main first"
git fetch -q origin main --tags
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || die "main is not origin/main: push or pull first"
[ -z "$(git status --porcelain --untracked-files=no)" ] || die "uncommitted changes"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && die "$TAG already exists"
[ -z "$NOTES" ] || [ -f "$NOTES" ] || die "$NOTES does not exist"

# mujina-miner builds against the sibling checkout ../amlogic-cb-tools
# (path dependency), so pin and record that too.
CBT=$(cd .. && pwd)/amlogic-cb-tools
[ -d "$CBT/.git" ] || [ -f "$CBT/.git" ] || die "$CBT is missing (mujina-miner depends on it)"
[ -z "$(git -C "$CBT" status --porcelain --untracked-files=no)" ] || die "$CBT has uncommitted changes"
CBT_REV=$(git -C "$CBT" rev-parse HEAD)

git tag -a "$TAG" -m "$TAG (amlogic-cb-tools $CBT_REV)"
trap 'git tag -d "$TAG" >/dev/null 2>&1 || true' ERR
unset MUJINA_VERSION
cargo build --release --target "$TARGET" -p mujina-miner --bin mujina-minerd
grep -qa "$TAG" "$BIN" || die "the binary does not carry $TAG"
grep -qa "$TAG-dirty" "$BIN" && die "the binary was built dirty"

OUT=dist/$TAG; rm -rf "$OUT"; mkdir -p "$OUT"
cp "$BIN" "$OUT/mujina-minerd-aarch64"
(cd "$OUT" && shasum -a 256 mujina-minerd-aarch64 > SHA256SUMS && cat SHA256SUMS)

if [ -z "$NOTES" ]; then
  PREV=$(git describe --tags --abbrev=0 --match 'ry3t-v*' "$TAG^" 2>/dev/null || true)
  NOTES=$OUT/NOTES.md
  { echo "mujina-minerd for Amlogic S19j Pro / S19k Pro control boards (aarch64, static musl)."
    echo; echo "Changes${PREV:+ since $PREV}:"; echo
    git log --format='- %s (%h)' ${PREV:+$PREV..}"$TAG"
    echo; echo "Built against amlogic-cb-tools $CBT_REV."; } > "$NOTES"
fi
trap - ERR
git push -q origin "$TAG"
gh release create "$TAG" -R RY3T/mujina --verify-tag --title "$TAG" --notes-file "$NOTES" \
  "$OUT/mujina-minerd-aarch64" "$OUT/SHA256SUMS"
echo ">> released $TAG: https://github.com/RY3T/mujina/releases/tag/$TAG"
