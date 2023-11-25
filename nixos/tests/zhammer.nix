{ system ? builtins.currentSystem,
  config ? {},
  pkgs ? import ../.. { inherit system config; }
}:

with import ../lib/testing-python.nix { inherit system pkgs; };

let

  makeZfsTest = name:
    { kernelPackage ? if enableUnstable
                      then pkgs.zfsUnstable.latestCompatibleLinuxPackages
                      else pkgs.linuxPackages
    , extraKernelParams ? []
    , enableUnstable ? false
    , ignoreFailures ? false
    , zfsPackage ? if enableUnstable then pkgs.zfsUnstable else pkgs.zfs
    , extraTest ? ""
    }:
    makeTest {
      name = "zfs-" + name;
      meta = with pkgs.lib.maintainers; {
        maintainers = [ numinit ];
      };

      nodes.${name} = { config, pkgs, lib, ... }: let
        zhammer = pkgs.writeShellScriptBin "zhammer" ''
          set -euo pipefail

          workdir="."
          count=100000
          blocksize="16k"
          check_every=10000

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
            echo "[zhammer::''${BASHPID}] $1" >&2
          }

          if [ ! -d "$workdir" ] || [ ! "$count" -gt 0 ] || [ -z "$blocksize" ] || [ ! "$check_every" -gt 0 ]; then
            log "Usage: $0 <workdir> <count> <blocksize> <check_every>"
            exit 1
          fi

          log "Work dir: $workdir"
          log "Count: $count files"
          log "Block size: $blocksize"
          log "Check every: $check_every files"

          # Create a file filled with 0xff.
          cd "$workdir"
          prefix="zhammer_''${BASHPID}_"
          dd if=/dev/zero bs="$blocksize" count=1 status=none | LC_ALL=C tr "\000" "\377" > "''${prefix}0"

          cleanup() {
            rm -f "$prefix"* || true
          }

          trap cleanup EXIT

          total=0
          for (( n=0; n<=$count; n+=$check_every )); do
            log "writing $check_every files at iteration $n"
            h=0
            for (( i=1; i<=$check_every; i+=2 )); do
              j=$((i+1))
              cp --reflink=never --sparse=always "''${prefix}$h" "''${prefix}$i" || true
              cp --reflink=never --sparse=always "''${prefix}$i" "''${prefix}$j" || true
              h=$((h+1))
            done

            log "checking $check_every files at iteration $n"
            for (( i=1; i<=$check_every; i++ )); do
              old="''${prefix}0"
              copy="''${prefix}$i"
              if [ -f "$old" ] && [ -f "$copy" ] && ! cmp -s "$old" "$copy"; then
                log "$old differed from $copy!"
                hexdump -C "$old" > "$old.hex"
                hexdump -C "$copy" > "$copy.hex"
                log "Hexdump diff follows"
                diff -u "$old.hex" "$copy.hex" >&2 || true
                log "ZFS version info" >&2
                zfs version >&2 || true
                exit 1
              fi
            done
            rm -f "$prefix"[1-9]* || true
          done
        '';
      in {
        virtualisation = {
          cores = 8;
          memorySize = 8192;
          useBootLoader = true;
          useEFIBoot = true;
        };
        boot.loader.systemd-boot.enable = true;
        boot.loader.timeout = 0;
        boot.loader.efi.canTouchEfiVariables = true;
        networking.hostId = "deadbeef";
        boot.kernelPackages = kernelPackage;

        # Always enable block cloning if supported.
        boot.kernelParams = ["zfs.zfs_bclone_enabled=1"] ++ extraKernelParams;

        boot.zfs.package = zfsPackage;
        boot.supportedFilesystems = [ "zfs" ];
        boot.initrd.systemd.enable = false;

        environment.systemPackages = [ pkgs.parted pkgs.parallel zhammer ];

        # /dev/disk/by-id doesn't get populated in the NixOS test framework
        boot.zfs.devNodes = "/dev/disk/by-uuid";
      };

      testScript = ''
        machine = ${name}
        machine.wait_for_unit("multi-user.target")
        machine.succeed(
          "zpool status",
          "truncate -s 4G /dev/shm/zfs",
          "zpool create -f -o ashift=12 -O canmount=off -O mountpoint=none -O xattr=sa -O dnodesize=auto -O acltype=posix -O atime=off -O relatime=on tank /dev/shm/zfs",
          "zfs create -o canmount=on -o mountpoint=/test tank/test"
        )

        machine.succeed(
          "parallel --lb --halt-on-error now,fail=1 zhammer /test 1000000 16k 10000 ::: $(seq $(nproc))${pkgs.lib.optionalString ignoreFailures " || true"}"
        )
      '' + extraTest;
    };


in {
  zfs_2_2_1 = makeZfsTest "zfs_2_2_1" { ignoreFailures = true; };
  zfs_2_2_1_zfs_dmu_offset_next_sync = makeZfsTest "zfs_2_2_1_zfs_dmu_offset_next_sync" { ignoreFailures = true; extraKernelParams = [ "zfs.zfs_dmu_offset_next_sync=0" ]; };
  /*
  # For some reason, this fails
  zfs_2_2_1_with_patch = makeZfsTest "zfs_2_2_1_with_patch" {
    zfsPackage = pkgs.zfs.overrideAttrs (prev: {
      extraPatches = [
        (pkgs.fetchpatch {
          # https://github.com/openzfs/zfs/pull/15571
          # Remove when it's backported to 2.1.x.
          url = "https://github.com/robn/zfs/commit/617c990a4cf1157b0f8332f35672846ad16ca70a.patch";
          hash = "sha256-j5YSrud7BaWk2npBl31qwFFLYltbut3CUjI1cjZOpag=";
        })
      ];
    });
  };*/
  zfs_2_1_with_patch = makeZfsTest "zfs_2_1_with_patch" { zfsPackage = pkgs.zfs_2_1; };
}
