#!/usr/bin/env bash
set -euo pipefail

default_workdir="."
default_count=1000000
default_blocksize=16k
default_check_every=10000

workdir="$default_workdir"
count="$default_count"
blocksize="$default_blocksize"
check_every="$default_check_every"

if [ $# -ge 1 ]; then
  workdir="$1"
fi

if [ $# -ge 2 ]; then
  count="$2"
fi

if [ $# -ge 3 ]; then
  blocksize="$3"
fi

if [ $# -ge 4 ]; then
  check_every="$4"
fi

log() {
  echo "[zhammer::${BASHPID}] $1" >&2
}

print_zfs_version_info() {
  local uname
  local version
  local kmod
  uname="$(uname -a)"
  version="$(zfs version | grep -v kmod)"
  kmod="$(zfs version | grep kmod)"

  local module
  local srcversion
  local sha256
  module="$(modinfo -n zfs || true)"
  srcversion="$(modinfo -F srcversion zfs || true)"

  if [ -f "$module" ]; then
    local cmd=cat
    if [[ "$module" = *.xz ]]; then
      cmd=xzcat
    fi

    sha256="$("$cmd" "$module" | sha256sum | awk '{print $1}')"
  fi

  log "==="
  log "Uname: $uname"
  log "Cmdline: $(</proc/cmdline)"
  for param in zfs_bclone_enabled zfs_bclone_wait_dirty zfs_dmu_offset_next_sync; do
    local filename="/sys/module/zfs/parameters/$param"
    if [ -f "$filename" ]; then
        log "  - $param: $(<"$filename")"
    fi
  done
  log "ZFS userspace: $version"
  log "ZFS kernel: $kmod"
  log "Module: $module"
  log "Srcversion: $srcversion"
  log "SHA256: $sha256"
  log "==="
}

if [ ! -d "$workdir" ] || [ ! "$count" -gt 0 ] || [ -z "$blocksize" ] || [ ! "$check_every" -gt 0 ]; then
  log "Usage: $0 <workdir=$default_workdir> <count=$default_count> <blocksize=$default_blocksize> <check_every=$default_check_every>"
  exit 1
fi

log "zhammer starting!"

print_zfs_version_info

log "Work dir: $workdir"
log "Count: $count files"
log "Block size: $blocksize"
log "Check every: $check_every files"

# Create a file filled with 0xff.
cd "$workdir"
prefix="zhammer_${BASHPID}_"
dd if=/dev/urandom bs="$blocksize" count=1 status=none > "${prefix}0"

cleanup() {
  rm -f "$prefix"* || true
}

trap cleanup EXIT

for (( n=0; n<=count; n+=check_every )); do
  log "writing $check_every files at iteration $n"
  h=0
  for (( i=1; i<=check_every; i+=2 )); do
    j=$((i+1))
    cp --reflink=never --sparse=always "${prefix}$h" "${prefix}$i" || true
    cp --reflink=never --sparse=always "${prefix}$i" "${prefix}$j" || true
    h=$((h+1))
  done

  log "checking $check_every files at iteration $n"
  for (( i=1; i<=check_every; i++ )); do
    old="${prefix}0"
    copy="${prefix}$i"
    if [ -f "$old" ] && [ -f "$copy" ] && ! cmp -s "$old" "$copy"; then
      log "$old differed from $copy!"
      hexdump -C "$old" > "$old.hex"
      hexdump -C "$copy" > "$copy.hex"

      log "Hexdump diff follows"
      diff -u "$old.hex" "$copy.hex" >&2 || true

      print_zfs_version_info
      exit 1
    fi
  done
  rm -f "$prefix"[1-9]* || true
done
