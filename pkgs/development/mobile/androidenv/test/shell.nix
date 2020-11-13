{
  pkgs ? import ../../../../.. {},
  pkgs_i686 ? import ../../../../.. { system = "i686-linux"; },
  config ? pkgs.config
}:
let
  androidEnv = import ./.. {
    inherit config pkgs pkgs_i686;
    licenseAccepted = true;
  };
  androidComposition = androidEnv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    includeEmulator = true;
    includeSystemImages = true;
    includeDocs = false;
    systemImageTypes = [ "default" ];
    abiVersions = [ "x86_64" ];
    includeNDK = true;
    # platforms = [ "28" ];
    ndkVersion = "21.3.6528147";
    useGoogleAPIs = true;
    useGoogleTVAddOns = false;
    includeExtras = [ "extras;google;gcm" ];
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    glibc_multi
    androidComposition.androidsdk
    openssl
  ];
  ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
  GRADLE_OPTS =
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/28.0.3/aapt2";
}
