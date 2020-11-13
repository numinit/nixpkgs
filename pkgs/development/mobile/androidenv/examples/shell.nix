{
  pkgs ? import ../../../../.. {},
  pkgs_i686 ? import ../../../../.. { system = "i686-linux"; },
  config ? pkgs.config
}:

let
  android = {
    versions = {
      tools = "26.1.1";
      platformTools = "30.0.5";
      buildTools = "30.0.2";
      ndk = "21.3.6528147";
      cmake = "3.10.2";
    };

    platforms = ["23" "24" "25" "26" "27" "28" "29"];
    abis = ["armeabi-v7a" "arm64-v8a"];
    extras = ["extras;google;gcm"];
  };

  androidEnv = import ./.. {
    inherit config pkgs pkgs_i686;
    licenseAccepted = true;
  };

  androidComposition = androidEnv.composeAndroidPackages {
    toolsVersion = android.versions.tools;
    platformToolsVersion = android.versions.platformTools;
    buildToolsVersions = [android.versions.buildTools];
    platformVersions = android.platforms;
    abiVersions = android.abis;

    includeSources = false;
    includeSystemImages = false;
    includeEmulator = false;

    includeNDK = true;
    ndkVersion = android.versions.ndk;
    cmakeVersions = [android.versions.cmake];

    useGoogleAPIs = true;
    includeExtras = android.extras;

    # If you want to use a custom repo JSON:
    repoJson = ../repo.json;

    # If you want to use custom repo XMLs:
    /*repoXmls = {
      packages = [ ../xml/repository2-1.xml ];
      images = [
        ../xml/android-sys-img2-1.xml
        ../xml/android-tv-sys-img2-1.xml
        ../xml/android-wear-sys-img2-1.xml
        ../xml/android-wear-cn-sys-img2-1.xml
        ../xml/google_apis-sys-img2-1.xml
        ../xml/google_apis_playstore-sys-img2-1.xml
      ];
      addons = [ ../xml/addon2-1.xml ];
    };*/

    # Accepting more licenses
    extraLicenses = [
      # Already accepted for you with accept_license = true.
      # "android-sdk-license"

      # These aren't, but are useful for more uncommon setups.
      "android-sdk-preview-license"
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };

  androidSdk = androidComposition.androidsdk;
  platformTools = androidComposition.platform-tools;
  jdk = pkgs.jdk;
in
(pkgs.buildFHSUserEnv rec {
  name = "androidenv-demo";
  targetPkgs = pkgs: [ androidSdk platformTools jdk pkgs.android-studio ];
  runScript = "/bin/sh";
  profile = ''
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
    export ANDROID_HOME=${androidSdk}/libexec/android-sdk
    export ANDROID_NDK_ROOT=${androidSdk}/libexec/android-sdk/ndk-bundle
    export JAVA_HOME=${jdk.home}
  '';
}).env

