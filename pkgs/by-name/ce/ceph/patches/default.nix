{
  fetchpatch2,
}:

let
  squidPatch =
    { name, hash }:
    fetchpatch2 {
      inherit name hash;
      url = "https://github.com/proxmox/ceph/raw/35f5f7f91776ccba31254fc47e9359b94580b4a0/patches/${name}";
    };
in
[
  ./boost-1.85.patch
  ./boost-1.86-PyModule.patch

  (fetchpatch2 {
    name = "ceph-boost-1.86-uuid.patch";
    url = "https://github.com/ceph/ceph/commit/01306208eac492ee0e67bff143fc32d0551a2a6f.patch";
    hash = "sha256-2qT245jt6mFFlmr0miG1durshYkJd2v+avEj3JKtGyA=";
  })

  (fetchpatch2 {
    name = "ceph-cmake-4.patch";
    url = "https://gitlab.alpinelinux.org/ashpool/aports/-/raw/d22b70eafe33c3daabe4eea6913c5be87d9463ad/community/ceph19/cpp_redis.patch";
    hash = "sha256-wxPIsYt25CjXhJ6kmr/MXwFD58Sl4y4W+r9jAMND+uw=";
  })

  # See:
  # * <https://github.com/ceph/ceph/pull/55560>
  # * <https://github.com/ceph/ceph/pull/60575>
  (fetchpatch2 {
    name = "ceph-systemd-sans-cluster-name.patch";
    url = "https://github.com/ceph/ceph/commit/5659920c7c128cb8d9552580dbe23dd167a56c31.patch?full_index=1";
    hash = "sha256-Uch8ZghyTowUvSq0p/RxiVpdG1Yqlww9inpVksO6zyk=";
  })
  (fetchpatch2 {
    name = "ceph-systemd-prefix.patch";
    url = "https://github.com/ceph/ceph/commit/9b38df488d7101b02afa834ea518fd52076d582a.patch?full_index=1";
    hash = "sha256-VcbJhCGTUdNISBd6P96Mm5M3fFVmZ8r7pMl+srQmnIQ=";
  })

  # Remove once Ceph supports arrow-cpp >= 20, see:
  # * https://tracker.ceph.com/issues/71269
  # * https://github.com/NixOS/nixpkgs/issues/406306
  # Patch from: https://github.com/ceph/s3select/pull/169
  (fetchpatch2 {
    name = "ceph-s3select-arrow-20-compat.patch";
    url = "https://github.com/ceph/s3select/commit/58fe02f8c93cd7f4102b435ee7233aa555c7c305.patch";
    hash = "sha256-RBNBZW8esbauDXM92y/pZOjDJCcvUkAeE+G8OJj84G0=";
    stripLen = 1;
    extraPrefix = "src/s3select/";
  })

  (squidPatch {
    name = "0001-cmake-disable-version-from-git.patch";
    hash = "sha256-AgTLlK/xkPV1MuRCEZc6UNjvEDwI0keW9P3QsafKbPA=";
  })
  # 0002 to 0005 are Debian control specific
  # 0006 hardcodes a Debian user
  (squidPatch {
    name = "0007-fix-compatibility-with-CPUs-not-supporting-SSE-4.1-i.patch";
    hash = "sha256-VDEpdg5M97IYXiWgN6VQ4ZIAUsYhz4cqWrTAEz/cN4I=";
  })
  # 0008 and 0009 are Debian control specific
  (squidPatch {
    name = "0010-ceph-crash-change-order-of-client-names.patch";
    hash = "sha256-M4daDhc6bNqSGjoUzYhRfMHYU2AzCdTxusqUGiaSEqA=";
  })
  # 0011 and 0012 are Debian control specific
  (squidPatch {
    name = "0013-disable-elastic_shared_blob-to-prevent-crashing-OSDs.patch";
    hash = "sha256-UVUCxWucIq4/um5IL2XNYQoec0qV7K7wdm+rnoXQKCA=";
  })
  (squidPatch {
    name = "0014-mgr-stop-using-deprecated-API-to-initialize-Python.patch";
    hash = "sha256-4gwaCXl22XM/+v3k7uvQKdj6Eqmuu7rvOFB42oNh0WQ=";
  })
  (squidPatch {
    name = "0015-mgr-set-argv-for-python-in-PyModuleRegistry.patch";
    hash = "sha256-bnm4XP97HO8DuPf18Q/XeZCR8F3X2N0Nm78n6gvnnN4=";
  })
  (squidPatch {
    name = "0016-mgr-add-site-package-paths-in-PyModuleRegistry.patch";
    hash = "sha256-+CKaZ2fppozys8e1D3aaO3FZ1n9AhSFTI0BpiEj4lrs=";
  })
  # 0017 is Debian control specific
  (squidPatch {
    name = "0018-fix-build-for-Apache-Arrow-15.0.0.-on-Debian.patch";
    hash = "sha256-p92iMAfOlvB/HNor7PRwhjZItsSK/Z+bkQg68M6Qt0Q=";
  })
  (squidPatch {
    name = "0019-Update-RGW-Arrow-Flight-code-to-adjust-to-API-change.patch";
    hash = "sha256-0sJh3Qof/rrjlqvEDhQXcQDx6SsneKxyQiOxPhUBS4k=";
  })
  # 0020 and 0021 are Debian contrl specific
  (squidPatch {
    name = "0022-pybind-mgr-replace-imports-of-distutils.util.patch";
    hash = "sha256-DcT932Q4Y2jI6+8VTJoqP16Pa4xWyiSIvMjtBDd3m2c=";
  })
  /*
    (squidPatch {
      name = "0023-debian-radosgw-add-media-types-packages-as-alternati.patch";
      hash = "sha256-z0LEnhqeu0vU27WdhWH7/P4Crh7EseWyCP1Bb/QZ02c=";
    })
  */
  (squidPatch {
    name = "0024-ceph-volume-fix-importlib.metadata-compat.patch";
    hash = "sha256-+5x+7OSsBFOk4R2QnDtZy/MDDTimwMXCU0HBkVpGYD0=";
  })
  # 0025 is Debian specific
  (squidPatch {
    name = "0026-pybind-mgr-Hack-around-the-ImportError-PyO3-modules-.patch";
    hash = "sha256-5I1Q4Iq1vgVq+wK5yTGzVL+6LTX6EpwpjCcLRHxMEO0=";
  })
  (squidPatch {
    name = "0027-python-common-cryptotools-use-json-for-structured-ou.patch";
    hash = "sha256-AmRkXEpREECEyTLopOLsOMTZAWZSQAnbIA3DMb2NSMM=";
  })
  (squidPatch {
    name = "0028-python-common-cryptotools-create-CrytpoCaller-interf.patch";
    hash = "sha256-O81dIxsSGhsUS3KdPuoNBiqWXU1dqzUgZ1SZdfdv+8Y=";
  })

  # This patch renames files, which fetchpatch2 strips
  ./0029-python-common-cryptotools-use-one-single-dir-for-cry.patch

  # 0030 just removes a directory that is already gone

  (squidPatch {
    name = "0031-pybind-mgr-update-mgr_util-to-use-cryptotools-Crypto.patch";
    hash = "sha256-s3iIPADNjjeZflisCb2yXwz+uzh9Q9Ns02YyhDLxWNc=";
  })
  (squidPatch {
    name = "0032-python-common-Correct-typo-in-private_key-naming-fie.patch";
    hash = "sha256-gBqAth754qnXCiVmSodtgRE9u8kHxfI/s04+kYm6LQg=";
  })
  (squidPatch {
    name = "0033-python-common-cryptotools-Always-encode-Err-via-stde.patch";
    hash = "sha256-RiGNX4ycZMasrsHO72aT9Iz8TY0c/ow1xK6nBS8DNZQ=";
  })
  (squidPatch {
    name = "0034-pybind-mgr-Correct-code-to-ensure-cephadm-tests-test.patch";
    hash = "sha256-lZcCn6GR8wYUMRLggk9agqPZ/DJ6McUgNeCUES4JUHo=";
  })
  (squidPatch {
    name = "0035-python-common-cryptotools-fix-error-path-in-verify-t.patch";
    hash = "sha256-swe3s53m03kCZyWZwchI6UYOKNk7ghTrR3agDB/9NVs=";
  })
  (squidPatch {
    name = "0036-python-common-cryptotools-Remove-ascii-and-utf-8-ref.patch";
    hash = "sha256-V1t3FKsxLj4mQFvqoklRZGIUwoxxklBSsrODafq0CmI=";
  })
  (squidPatch {
    name = "0037-pybind-mgr-Appropriately-rename-function.patch";
    hash = "sha256-oTtAtEiXEI6m9TZj+sHK8XlPD4NgROu0cxg50UUMG9Q=";
  })
  (squidPatch {
    name = "0038-python-common-cryptotools-give-the-parsers-more-sens.patch";
    hash = "sha256-kj5h4L9Ypa/LxRr9lT9Cqtw6ebdhFQrUpKDZk2zOaQQ=";
  })
  (squidPatch {
    name = "0039-mgr-dashboard-replace-direct-use-of-bcrypt-in-dashbo.patch";
    hash = "sha256-3YCMdwKh74amt95rflpO0k58zZWIIZ816seC9XOd6Vw=";
  })
  (squidPatch {
    name = "0040-pybind-mgr-fix-test-case-in-test_tls.py.patch";
    hash = "sha256-OdDsXbi07kIt8nBfuU9ooY/yunuTirlpfcV/Mhkh+tA=";
  })
  (squidPatch {
    name = "0041-python-common-cryptotools-move-actual-crypto-opts-in.patch";
    hash = "sha256-ug0AR9fpM8uz1j/h8lUjP1PAa1RxUdwuA2JkwFc8gtc=";
  })
  (squidPatch {
    name = "0042-python-common-cryptotools-use-a-main-function.patch";
    hash = "sha256-qbh3EWQgieBT/+HhZ6uQR9Jf6DjuxlrOdy1Kuq1AfJE=";
  })
  (squidPatch {
    name = "0043-python-common-cryptotools-unify-and-organize-all-end.patch";
    hash = "sha256-owPbxunz3E2X7+VdoVn1urh8WJhqSKIjXe4S/7pq3j0=";
  })
  (squidPatch {
    name = "0044-python-common-cryptotools-add-caller-module-for-base.patch";
    hash = "sha256-WGH+RyiMIUbdWKEtTGSMzdnfR+bGP6n63fUdw2Dla4Q=";
  })
  (squidPatch {
    name = "0045-python-common-cryptotools-move-internal-crypto-calle.patch";
    hash = "sha256-C4BlJo0issSYb1jTukxZBqjTpAAGcZkcMrn6BPw5JcY=";
  })
  (squidPatch {
    name = "0046-python-common-cryptotools-create-module-for-selectin.patch";
    hash = "sha256-eGbL5tiO0fYUnp6dOOTQ/NC3DVEB3QwlKzv9gyYGvpU=";
  })
  (squidPatch {
    name = "0047-python-common-cryptotools-catch-all-failures-to-read.patch";
    hash = "sha256-yQmA4aIV12EffOq4ofbiVx9A4XoxVK8IDuSqHD74ylI=";
  })
  (squidPatch {
    name = "0048-mgr-cephadm-always-use-the-internal-cryptocaller.patch";
    hash = "sha256-IZ/6kAWBCcZ8g3Y82WG2bNiqDQIqtDi3HpxF24Fx7gY=";
  })
  (squidPatch {
    name = "0049-mgr-dashboard-add-an-option-to-control-the-dashboard.patch";
    hash = "sha256-WrckIIwdiE8byhMWT8LyvGEvlNbsEkfNfHYv6lGMO3U=";
  })
  (squidPatch {
    name = "0050-pybind-mgr-restful-provide-workaround-for-PyO3-Impor.patch";
    hash = "sha256-LD6awn52/GxC+mT1/zvK2rg49Po4G6uCWW/QAvBsNOI=";
  })
  (squidPatch {
    name = "0051-mgr-fix-module-import-by-making-NOTIFY_TYPES-in-py-m.patch";
    hash = "sha256-OSNCG2ihUVcIVs5FtbtWKq1QvIAbd4JTNQYmQuhDSw4=";
  })
  (squidPatch {
    name = "0052-mgr-osd_perf_query-fix-ivalid-escape-sequence.patch";
    hash = "sha256-KDP8BRd7+ZcJg+E4jAmYlxBAf+kVnfnb1uks8ivNYYE=";
  })
  (squidPatch {
    name = "0053-mgr-zabbix-fix-invalid-escape-sequences.patch";
    hash = "sha256-4KBllcr2Roxj3nG6OATZG5aUopnc+dSeZXSyLiSX+pc=";
  })
  (squidPatch {
    name = "0054-client-prohibit-unprivileged-users-from-setting-sgid.patch";
    hash = "sha256-ssCPnY04OHY4cQl2mh1MMETlrnqt824k6T1HXkwN8LQ=";
  })
  (squidPatch {
    name = "0055-pybind-rbd-disable-on_progress-callbacks-to-prevent-.patch";
    hash = "sha256-njdqUUPSIPzqw6C83H6yVseOKppigA2Y+XJKpDi21NM=";
  })
]
