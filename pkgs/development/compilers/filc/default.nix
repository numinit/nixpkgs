{
  fetchFromGitHub,
  fetchpatch,
  mkLLVMPackages,
}:

let
  filcPackages' = (mkLLVMPackages {
    version = "20.1.8";
    /*monorepoSrc = fetchFromGitHub {
      owner = "pizlonator";
      repo = "fil-c";
      tag = "v0.673";
      hash = "sha256-mXuTQHwplo/cXmWpr9VpLYD/VZLCFJ42o+I9L5O50UI=";
    };*/
    monorepoSrc = fetchFromGitHub {
      owner = "numinit";
      repo = "fil-c";
      rev = "0af39902ad8a688145f6c531b4b71adcaa33f88c";
      hash = "sha256-606cFRXVXvuhYUq+fM3fsb+FaNLWUwxypb9rVq1IsBk=";
    };
    attrName = "filcPackages";
  }).value;
in
filcPackages'.overrideScope (final: prev: {
  libllvm = prev.libllvm.overrideAttrs (prevPackage: {
    doCheck = false;
  });
})
