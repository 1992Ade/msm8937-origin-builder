#!/usr/bin/env bash
# Shared kernel optimizations for the MSM8937 (Mi-Thorium 4.19) builders.
#
# Root-solution independent: the same file is used by msm8937-origin-builder (OriginSU)
# and msm8937-KazeSU-builder (KazeSU). Keep both copies identical.
#
# Usage (from the kernel source root):
#   optimizations.sh apply  <defconfig>   # append configs + apply small source patches
#   optimizations.sh verify <.config>     # check the final config after olddefconfig
#
# Only low-risk changes live here. Each one is opt-in at runtime or behaves like stock
# unless userspace changes a setting, so a regression is easy to rule out.

set -euo pipefail

warn() { echo "::warning::optimizations: $*"; }

apply() {
  local defconfig="$1"
  [ -f "$defconfig" ] || { echo "::error::defconfig not found: $defconfig"; exit 1; }

  echo "== Optimizations: configs =="
  cat >> "$defconfig" <<'EOF'
# --- optimizations.sh -------------------------------------------------------
# Power-efficient workqueues: queue work on unbound workers instead of waking an
# idle CPU just to run it. Saves power on the 8x Cortex-A53, negligible cost.
CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y
# zstd for ZRAM (available, not default): lz4 stays the default algorithm.
# Select it at runtime with: echo zstd > /sys/block/zram0/comp_algorithm (before swapon)
CONFIG_CRYPTO_ZSTD=y
# TTL / Hop Limit targets for tethering (IPv4 TTL already in Mi-Thorium's common.config).
CONFIG_IP_NF_MANGLE=y
CONFIG_IP_NF_TARGET_TTL=y
CONFIG_IP6_NF_MANGLE=y
CONFIG_IP6_NF_TARGET_HL=y
CONFIG_NETFILTER_XT_TARGET_HL=y
# ---------------------------------------------------------------------------
EOF

  echo "== Optimizations: vm.swappiness up to 200 =="
  # 4.19 caps vm.swappiness at 100. Its reclaim math already uses
  # file_prio = 200 - anon_prio, so 200 is a valid value: it makes the kernel prefer
  # swapping to ZRAM over dropping file cache. The default value is unchanged (the ROM
  # still sets it); this only raises the allowed maximum.
  if grep -q 'static int two_hundred = 200;' kernel/sysctl.c; then
    echo "-- already patched"
  elif grep -q 'file_prio = 200 - anon_prio;' mm/vmscan.c \
       && awk '/\.procname[[:space:]]*=[[:space:]]*"swappiness"/{f=1} f&&/\.extra2/{print; exit}' kernel/sysctl.c \
          | grep -q '&one_hundred'; then
    sed -i 's/^static int one_hundred = 100;$/&\nstatic int two_hundred = 200;/' kernel/sysctl.c
    # Only the extra2 inside the "swappiness" entry
    sed -i '/\.procname[[:space:]]*=[[:space:]]*"swappiness"/,/}/ s/\.extra2\([[:space:]]*\)=[[:space:]]*&one_hundred/.extra2\1= \&two_hundred/' kernel/sysctl.c
    grep -q 'static int two_hundred = 200;' kernel/sysctl.c \
      && awk '/\.procname[[:space:]]*=[[:space:]]*"swappiness"/{f=1} f&&/\.extra2/{print; exit}' kernel/sysctl.c | grep -q '&two_hundred' \
      && echo "-- swappiness max = 200" \
      || { echo "::error::swappiness patch did not apply cleanly"; exit 1; }
  else
    warn "swappiness patch skipped (kernel/sysctl.c or mm/vmscan.c changed upstream)"
  fi

  echo "== Optimizations: tune code generation for Cortex-A53 =="
  # Every MSM8937/MSM8917/SDM439 core is a Cortex-A53. -mcpu only changes instruction
  # scheduling/selection for that core (it stays ARMv8.0); with ThinLTO it is recorded
  # per function and applied at link time too.
  if grep -q -- '-mcpu=cortex-a53' Makefile; then
    echo "-- already set"
  elif grep -q '^export KBUILD_CFLAGS' Makefile || grep -q 'export KBUILD_CFLAGS' Makefile; then
    sed -i '0,/export KBUILD_CFLAGS/s//KBUILD_CFLAGS += -mcpu=cortex-a53\n&/' Makefile
    echo "-- KBUILD_CFLAGS += -mcpu=cortex-a53"
  else
    warn "-mcpu=cortex-a53 skipped (no 'export KBUILD_CFLAGS' in Makefile)"
  fi

  sed -i 's/^[[:space:]]*CONFIG_/CONFIG_/' "$defconfig"
}

verify() {
  local config="$1" rc=0
  [ -f "$config" ] || { echo "::error::config not found: $config"; exit 1; }
  echo "--- Optimizations in the final .config ---"
  # Added by this script: the build fails if Kconfig dropped one of them.
  for sym in WQ_POWER_EFFICIENT_DEFAULT CRYPTO_ZSTD IP_NF_TARGET_TTL IP6_NF_TARGET_HL NETFILTER_XT_TARGET_HL; do
    if grep -q "^CONFIG_${sym}=y" "$config"; then
      echo "  CONFIG_${sym}=y"
    else
      echo "::error::optimizations: CONFIG_${sym} is not enabled in the final config"
      rc=1
    fi
  done
  # Set elsewhere (Mi-Thorium fragments / workflow): reported only.
  for sym in CRYPTO_LZ4 LTO_CLANG THINLTO; do
    if grep -q "^CONFIG_${sym}=y" "$config"; then
      echo "  CONFIG_${sym}=y"
    else
      warn "CONFIG_${sym} is not enabled"
    fi
  done
  grep -E '^CONFIG_ZRAM_DEFAULT_COMP_ALGORITHM=' "$config" || true
  return "$rc"
}

case "${1:-}" in
  apply)  apply  "${2:?missing defconfig path}" ;;
  verify) verify "${2:?missing .config path}" ;;
  *) echo "usage: $0 apply <defconfig> | verify <.config>"; exit 2 ;;
esac
