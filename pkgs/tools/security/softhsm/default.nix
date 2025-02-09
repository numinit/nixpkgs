{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  libtool,
  autoconf,
  automake,
  botan2,
  sqlite,
  libobjc,
  Security,
}:

stdenv.mkDerivation rec {
  pname = "softhsm";
  version = "2.6.1";

  /*src = fetchurl {
    url = "https://dist.opendnssec.org/source/${pname}-${version}.tar.gz";
    hash = "sha256-YSSUcwVLzRgRUZ75qYmogKe9zDbTF8nCVFf8YU30dfI=";
  };*/

  src = fetchFromGitHub {
    owner = "softhsm";
    repo = "SoftHSMv2";
    tag = version;
    hash = "sha256-sx0ceVY795JbtKbQGAVFllB9UJfTdgd242d6c+s1tBw=";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/softhsm/SoftHSMv2/pull/550.patch";
      hash = "sha256-G9nstc5M8U6g1kYGwjzTI35TJ0VhqTAFsrXqSHktzSg=";
    })
    (fetchpatch {
      url = "https://github.com/softhsm/SoftHSMv2/pull/551.patch";
      hash = "sha256-ikWw4d1gyhDFGjnP7Yym2prmKM4rSdDVbekNKwULhvU=";
    })
    (fetchpatch {
      url = "https://github.com/softhsm/SoftHSMv2/pull/742.patch";
      hash = "sha256-DH5aEdmllbSsL7pHPgIUdfRhXOhkfIeEbjpD9FbdIIw=";
    })
  ];

  nativeBuildInputs = [
    libtool
    autoconf
    automake
  ];

  configureFlags = [
    "--with-crypto-backend=botan"
    "--with-botan=${lib.getDev botan2}"
    "--with-objectstore-backend-db"
    "--sysconfdir=$out/etc"
    "--localstatedir=$out/var"
  ];

  preConfigure = ''
    ./autogen.sh
  '';

  propagatedBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    libobjc
    Security
  ];

  buildInputs = [
    botan2
    sqlite
  ];

  enableParallelBuilding = true;

  postInstall = "rm -rf $out/var";

  meta = with lib; {
    homepage = "https://www.opendnssec.org/softhsm";
    description = "Cryptographic store accessible through a PKCS #11 interface";
    longDescription = "
      SoftHSM provides a software implementation of a generic
      cryptographic device with a PKCS#11 interface, which is of
      course especially useful in environments where a dedicated hardware
      implementation of such a device - for instance a Hardware
      Security Module (HSM) or smartcard - is not available.

      SoftHSM follows the OASIS PKCS#11 standard, meaning it should be
      able to work with many cryptographic products. SoftHSM is a
      programme of The Commons Conservancy.
    ";
    license = licenses.bsd2;
    maintainers = [ maintainers.leenaars ];
    platforms = platforms.unix;
  };
}
