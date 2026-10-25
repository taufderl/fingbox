#!/usr/bin/env bash
# Prepare the Fingbox OpenWrt device-support branch for an upstream PR.
#
# It rebases the `fingbox` branch onto the latest openwrt/main on a NEW branch
# `fingbox-submit`, and rewrites each commit message to:
#   - drop the Co-Authored-By / Claude-Session / Assisted-by trailers I added,
#   - carry a one-line AI-assistance disclosure (OpenWrt policy), and
#   - carry YOUR Signed-off-by (the DCO certification only you can make).
#
# DCO: running the push/PR steps is you certifying the DCO, so review the diff
# in between. The default run only prepares and stops.
#
# Usage:
#   scripts/openwrt-prep-pr.sh            # rebase + rewrite, then show the diff
#   scripts/openwrt-prep-pr.sh --push     # push fingbox-submit to your fork
#   scripts/openwrt-prep-pr.sh --pr       # open the PR against openwrt/openwrt
#
# Env: OPENWRT_DIR (default ~/git/openwrt), SOB_NAME, SOB_EMAIL.
set -euo pipefail

OPENWRT_DIR=${OPENWRT_DIR:-$HOME/git/openwrt}
SOB_NAME=${SOB_NAME:-$(git -C "$OPENWRT_DIR" config user.name)}
SOB_EMAIL=${SOB_EMAIL:-$(git -C "$OPENWRT_DIR" config user.email)}
SRC_BRANCH=fingbox
WORK_BRANCH=fingbox-submit
UPSTREAM=upstream            # must point at openwrt/openwrt
FORK_REMOTE=origin           # your fork

cd "$OPENWRT_DIR"

step_push() {
  git rev-parse --verify "$WORK_BRANCH" >/dev/null 2>&1 || {
    echo "No $WORK_BRANCH yet — run without arguments first." >&2; exit 1; }
  git -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
    push -u "$FORK_REMOTE" "$WORK_BRANCH"
}

step_pr() {
  local base_sha head
  head=$(git rev-parse --short "$WORK_BRANCH")
  gh pr create -R openwrt/openwrt \
    --base main \
    --head "$(gh api user -q .login):$WORK_BRANCH" \
    --title "sunxi: add support for the Fing Fingbox" \
    --body-file "$OPENWRT_DIR/.fingbox-pr-body.md"
}

case "${1:-}" in
  --push) step_push; exit 0 ;;
  --pr)   step_pr;   exit 0 ;;
  "")     ;;
  *) echo "unknown arg: $1" >&2; exit 2 ;;
esac

# ---- phase 1: rebase + rewrite on a fresh work branch ----
git rev-parse --verify "$SRC_BRANCH" >/dev/null
git remote get-url "$UPSTREAM" | grep -q 'openwrt/openwrt' || {
  echo "remote '$UPSTREAM' must be openwrt/openwrt" >&2; exit 1; }

echo ">> fetching $UPSTREAM/main"
git fetch --quiet "$UPSTREAM" main

echo ">> (re)creating $WORK_BRANCH from $SRC_BRANCH"
git branch -f "$WORK_BRANCH" "$SRC_BRANCH"
git switch --quiet "$WORK_BRANCH"

# message rewriter used per commit during the rebase
rewriter=$(mktemp)
cat > "$rewriter" <<REW
#!/usr/bin/env bash
set -euo pipefail
msg=\$(git log -1 --format=%B \
  | grep -vE '^(Co-Authored-By|Claude-Session|Assisted-by):' \
  | awk 'NF{b=0} !NF{if(b)next;b=1} {print}')   # collapse blank runs
grep -qi 'AI coding assistant\|Claude' <<<"\$msg" || msg="\$msg

This change was developed with the help of an AI coding assistant (Claude,
by Anthropic); I have reviewed it and tested it on the hardware."
grep -q "Signed-off-by: $SOB_NAME <$SOB_EMAIL>" <<<"\$msg" || msg="\$msg

Signed-off-by: $SOB_NAME <$SOB_EMAIL>"
git commit --quiet --amend -m "\$msg"
REW
chmod +x "$rewriter"

echo ">> rebasing onto $UPSTREAM/main and rewriting messages"
GIT_SEQUENCE_EDITOR=: git rebase --quiet "$UPSTREAM/main" --exec "$rewriter"
rm -f "$rewriter"

# PR body
cat > "$OPENWRT_DIR/.fingbox-pr-body.md" <<'PR'
Adds OpenWrt support for the Fing Fingbox, a discontinued Allwinner H3
network-monitoring appliance.

- sun8i-h3 DTS and the fing_fingbox image
- ath9k_htc patch to load the AR9271 calibration data from a file (the chip
  has no EEPROM); MAC addresses come from the on-board 24C02
- boots with the vendor U-Boot (no FEL, no SD slot on this board, so its
  bootloader is never written); sysupgrade preserves a user data partition

Tested on hardware (kernel 6.18): Ethernet, Wi-Fi station and AP, the RGB LED
ring, the reset button and sysupgrade.

Disclosure: this work was developed with the help of an AI coding assistant
(Claude, by Anthropic). I have reviewed every change and tested it on the
device; see the per-commit notes.
PR

echo
echo "== $WORK_BRANCH is ready: $(git rev-list --count "$UPSTREAM/main".."$WORK_BRANCH") commits on $UPSTREAM/main"
git --no-pager log --format='  %h %s' "$UPSTREAM/main".."$WORK_BRANCH"
echo
echo "Next:"
echo "  git -C $OPENWRT_DIR range-diff $SRC_BRANCH $WORK_BRANCH   # what the rewrite changed"
echo "  git -C $OPENWRT_DIR log -p $UPSTREAM/main..$WORK_BRANCH    # REVIEW every line"
echo "  $0 --push      # push to your fork"
echo "  $0 --pr        # open the PR (edit .fingbox-pr-body.md first if needed)"
