{
  clangStdenv,
  lib,
  fetchFromGitHub,
  pkg-config,
  autoreconfHook,
  autoconf-archive,
  makeWrapper,
  patchelf,
  tpm2-abrmd,
  tpm2-tss,
  tpm2-tools,
  opensc,
  openssl,
  sqlite,
  python3,
  glibc,
  libyaml,
  cmocka,
  abrmdSupport ? true,
  fapiSupport ? true,
  fuzz ? false,
}:

clangStdenv.mkDerivation rec {
  pname = "tpm2-pkcs11";
  version = "1.9.1";

  src = fetchFromGitHub {
    owner = "tpm2-software";
    repo = pname;
    rev = version;
    hash = "sha256-W74ckrpK7ypny1L3Gn7nNbOVh8zbHavIk/TX3b8XbI8=";
  };

  # The preConfigure phase doesn't seem to be working here
  # ./bootstrap MUST be executed as the first step, before all
  # of the autoreconfHook stuff
  postPatch = ''
    echo "$version" > VERSION

    # Don't run git in the bootstrap
    substituteInPlace bootstrap --replace-warn "git" "# git"

    # Don't run tests with dbus
    substituteInPlace Makefile.am --replace-fail "dbus-run-session" "env"

    patchShebangs test

    ./bootstrap
  '';

  configureFlags =
    [
      "--enable-unit"
    ]
    ++ lib.optionals fuzz [
      "--enable-fuzzing"
      "--disable-hardening"
    ]
    ++ lib.optional fapiSupport "--with-fapi";

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    autoconf-archive
    makeWrapper
    patchelf
    cmocka
  ];
  buildInputs = lib.optional abrmdSupport tpm2-abrmd ++ [
    tpm2-tss
    tpm2-tools
    opensc
    openssl
    sqlite
    libyaml
    (python3.withPackages (
      ps: with ps; [
        packaging
        pyyaml
        cryptography
        pyasn1-modules
        tpm2-pytss
      ]
    ))
  ];

  enableParallelBuilding = true;
  hardeningDisable = lib.optional fuzz "all";

  outputs = [
    "out"
    "bin"
    "dev"
  ];

  doCheck = true;
  dontStrip = true;
  dontPatchELF = true;

  # To be able to use the userspace resource manager, the RUNPATH must
  # explicitly include the tpm2-abrmd shared libraries.
  preFixup =
    let
      rpath = lib.makeLibraryPath (
        (lib.optional abrmdSupport tpm2-abrmd)
        ++ [
          tpm2-tss
          sqlite
          openssl
          glibc
          libyaml
        ]
      );
    in
    ''
      patchelf \
        --set-rpath ${rpath} \
        ${lib.optionalString abrmdSupport "--add-needed ${lib.makeLibraryPath [ tpm2-abrmd ]}/libtss2-tcti-tabrmd.so"} \
        --add-needed ${lib.makeLibraryPath [ tpm2-tss ]}/libtss2-tcti-device.so \
        $out/lib/libtpm2_pkcs11.so.0.0.0
    '';

  postInstall = ''
    mkdir -p $bin/bin/ $bin/share/tpm2_pkcs11/
    mv ./tools/* $bin/share/tpm2_pkcs11/
    makeWrapper $bin/share/tpm2_pkcs11/tpm2_ptool.py $bin/bin/tpm2_ptool \
      --prefix PATH : ${lib.makeBinPath [ tpm2-tools ]}
  '';

  meta = with lib; {
    description = "PKCS#11 interface for TPM2 hardware";
    homepage = "https://github.com/tpm2-software/tpm2-pkcs11";
    license = licenses.bsd2;
    platforms = platforms.linux;
    maintainers = [ ];
    mainProgram = "tpm2_ptool";
  };
}
