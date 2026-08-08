{
  stdenv,
  libxml2,
  curl,
  openssl,
  fetchgit,

  #TEST: temp
  lib,
}:
let
  beaker = stdenv.mkDerivation {
    pname = "beaker";
    version = "git";
    src = fetchgit {
      url = "https://git.bwaa.monster/beaker";
      rev = "9c68a8ae6fb32f8a1660da392b9985a4ab3e7cb4"; # TEST:
      hash = lib.fakeHash;
      buildPhase = /* sh */ "make";
      installPhase = /* sh */ "make install";
      ## from old commit
      makeFlags = [
        "INSTALL_PREFIX=$(out)/"
        "LDCONFIG=true"
      ];
    };
  };
in
stdenv.mkDerivation {
  pname = "omnisearch";
  version = "git";
  src = fetchgit {
    url = "https://git.bwaa.monster/omnisearch";
    rev = "HEAD";
    hash = lib.fakeHash;
  };

  buildInputs = [
    libxml2.dev
    curl.dev
    openssl
    beaker
  ];

  #XXX: bad?
  preBuild = ''
    makeFlagsArray+=(
      "PREFIX=$out"
      "CFLAGS=-Wall -Wextra -O2 -Isrc -I${libxml2.dev}/include/libxml2"
      "LIBS=-lbeaker -lcurl -lxml2 -lpthread -lm -lssl -lcrypto"
    )
  '';

  buildPhase = "make";
  # installPhase = "make install-init";
  installPhase = ''
    mkdir -p $out/bin $out/share/omnisearch
    install -Dm755 bin/omnisearch $out/bin/omnisearch
    cp -r templates static locales -t $out/share/omnisearch/
  '';

  meta = {
    description = "Lightweight metasearch engine in C";
    platforms = lib.platforms.linux;
  };
}
