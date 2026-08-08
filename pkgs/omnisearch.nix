{
  stdenv,
  libxml2,
  curl,
  openssl,
  git,

  #TEST: temp
  lib,
}:
let
  repoURLBase = "https://git.bwaaa.monster";

  beaker = stdenv.mkDerivation rec {
    pname = "beaker";
    version = "360d6271e1a20d128430e52637d5d35f4c706ca5"; # "360d627";

    src = fetchGit {
      url = "${repoURLBase}/${pname}";
      rev = version;
    };

    buildPhase = /* sh */ ''
      make
    '';
    installPhase = /* sh */ ''
      make INSTALL_PREFIX="$out/" install
    '';
    makeFlags = [
      "INSTALL_PREFIX=$(out)/"
      "LDCONFIG=true"
    ];
  };
in
stdenv.mkDerivation rec {
  pname = "omnisearch";
  version = "499bb9b1268cd422619efdc46889960425462aae"; # "9c68a8a";

  src = fetchGit {
    url = "${repoURLBase}/${pname}";
    rev = version;
    # rev = "9c68a8ae6fb32f8a1660da392b9985a4ab3e7cb4";
  };

  buildInputs = [
    libxml2
    curl
    openssl
    beaker
    git
  ];
  preBuild = ''
    makeFlagsArray+=(
      GIT_HASH="$(git -C $src rev-parse --short ${version})"
      GIT_DATE="$(git -C $src log -1 --format='%ad' --date='format:%y.%m.%d')"
      GIT_BRANCH="$(git -C $src rev-parse --abbrev-ref ${version})"
      GIT_REMOTE="$(git -C $src remote get-url origin)"
    )
  '';
  buildPhase = # sh
    ''
      #NOTE: I don't understand why I cant put everything in makeFlagArray...
      make \
        PREFIX="$out" \
        CFLAGS="-Wall -Wextra -O2 -Isrc -I${libxml2.dev}/include/libxml2" \
        LIBS="-lbeaker -lcurl -lxml2 -lpthread -lm -lssl -lcrypto" \
        ''${makeFlagsArray[@]}

      # make install-systemd #TODO: HOLY SHIT WORKS WITHOUT THIS!
    '';

  installPhase = ''
    mkdir -p $out/bin $out/share/omnisearch
    install -Dm755 bin/omnisearch $out/bin/omnisearch
    cp -r templates static locales -t $out/share/omnisearch/
  '';

  meta = {
    description = "Lightweight metasearch engine in C";
    platforms = lib.platforms.linux;
    license = [ ../omnisearch.LICENSE ]; # TEST:
  };
}
