{ system ? builtins.currentSystem,
  config ? {},
  pkgs ? import ../.. { inherit system config; }
}:

with import ../lib/testing-python.nix { inherit system pkgs; };

let
  makeZfsTest = testName:
    { kernelPackage ? zfsPackage.latestCompatibleLinuxPackages
    , extraKernelParams ? []
    , enableUnstable ? false
    , ignoreFailures ? false
    , zfsPackage ? if enableUnstable then pkgs.zfsUnstable else pkgs.zfs
    , extraTest ? ""
    }:
    makeTest rec {
      name = "zfs-" + testName;
      globalTimeout = 24 * 60 * 60;
      meta = with pkgs.lib.maintainers; {
        maintainers = [ numinit ];
        timeout = globalTimeout;
      };

      nodes.${testName} = { config, pkgs, lib, ... }: let
        zhammer = pkgs.writeShellScriptBin "zhammer" (builtins.readFile ./zhammer.sh);
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
        machine = ${testName}
        machine.wait_for_unit("multi-user.target")
        machine.succeed(
          "zpool status",
          "truncate -s 4G /dev/shm/zfs",
          "zpool create -f -o ashift=12 -O canmount=off -O mountpoint=none tank /dev/shm/zfs",
          "zfs create -o canmount=on -o mountpoint=/test tank/test"
        )

        machine.succeed(
          "parallel --lb --halt-on-error now,fail=1 zhammer /test 10000000 16k 5000 ::: $(seq $(nproc))${pkgs.lib.optionalString ignoreFailures " || true"}"
        )
      '' + extraTest;
    };


in {
  zfs_2_2_3_stock = makeZfsTest "zfs_2_2_3_stock" { };
}
