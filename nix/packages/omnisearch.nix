{
  stdenv,
  libxml2,
  curl,
  openssl,
  git,
  lib,
  bashNonInteractive,
  ## used in pkgs.omnisearch.overrides {};
  configINIOverrides ? { }, # configINIExtra ? "", # prolly dumb
}:
let
  inherit (lib) platforms;
  inherit (lib.generators) toINI;

  gitHostURL = "https://git.bwaaa.monster";

  beaker = stdenv.mkDerivation rec {
    pname = "beaker";
    version = "2026.06.02"; # TODO newer version
    src = fetchGit {
      url = "${gitHostURL}/${pname}";
      rev = "360d6271e1a20d128430e52637d5d35f4c706ca5";
    };
    makeFlags = [
      "INSTALL_PREFIX=$(out)/"
      "LDCONFIG=true"
    ];
    meta.license = lib.licenses.lgpl21Only;
  };

  configINIAttrs = {
    server = {
      host = "0.0.0.0";
      port = 8087;
      ## default locale (default: "en_gb")
      #locale = "en_gb";
    };
    proxy = {
      ## single proxy, or ... (default: )
      # proxy = ''"socks5://127.0.0.1:9050"'';

      ## ... a proxy file (path as a string, do not source it) (default: )
      # list_file = path/to/file;

      #max_retries = 3;

      ## Randomize proxy credentials for each request
      #randomize_username = true;
      #randomize_password = true;
    };
    cache = {
      ## Directory to store cached responses (default: "/tmp/omnisearch_cache";)
      #dir = "/var/cache/omnisearch";

      ## Cache TTL for search results in seconds (default: 3600 = 1 hour)
      #ttl_search = 3600;

      ## Cache TTL for infobox data in seconds (default: 86400 = 24 hours)
      #ttl_infobox = 86400;
    };
    engines = {
      ## Use * for all engines, or specify comma-separated list (e.g., ddg,yahoo)
      ## Use *,-engine to exclude specific engines (e.g., *,-startpage)
      ## Available engines: ddg, startpage, yahoo, mojeek
      engines = ''"*"'';
    };
    rate_limit = {
      ## Rate limit searches per interval

      ## /search
      #search_requests = 10;
      #search_interval = 60;

      ## /images
      #images_requests = 20;
      #images_interval = 60;
    };
  }
  // configINIOverrides;
  #INFO: These are default values + few overrides from example-config.ini.
  ## Just use .override if you want to change
  configINI = lib.generators.toINI { } configINIAttrs;

  omnisearchGitRev = "499bb9b1268cd422619efdc46889960425462aae";
in
stdenv.mkDerivation rec {
  pname = "omnisearch";
  version = "2026.08.16";

  src = fetchGit {
    url = "${gitHostURL}/${pname}";
    rev = omnisearchGitRev;
  };

  nativeBuildInputs = [
    git
  ];
  buildInputs = [
    libxml2
    curl
    openssl
    beaker
  ];

  makeFlags = [
    "PREFIX=$(out)"
    "INSTALL_BIN_DIR=$(out)/bin"
    "DATA_DIR=$(out)/share/omnisearch"
    "LOG_DIR=$(out)/var/log/omnisearch"
    "CACHE_DIR=$(out)/var/cache/omnisearch"
    "VAR_DIR=$(out)/var/lib/omnisearch"
    "SYSTEMD_DIR=$(out)/lib/systemd/system"

    "GIT_HASH=${omnisearchGitRev}"
    "GIT_DATE=${version}" # TEST:
    "GIT_BRANCH=master"
    "GIT_REMOTE=${gitHostURL}/${pname}"
  ];

  preBuild = ''
    makeFlagsArray+=(
      CFLAGS="-Wall -Wextra -O2 -Isrc -I${libxml2.dev}/include/libxml2"
      LIBS="-lbeaker -lcurl -lxml2 -lpthread -lm -lssl -lcrypto"
    )
  '';

  installPhase = ''
    mkdir -p $out/{bin,share/omnisearch} # ,share/systemd/system

    #WARN: will fail because it uses `useradd` and `groupadd`. Instead do it manually
    # make install-systemd "''${makeFlagsArray[@]}"
    data_dir=$out/share/omnisearch
    mkdir -p $data_dir/{templates,static,locales}
    mkdir -p $out/var/{log,cache}/omnisearch
    mkdir -p $out/lib/systemd/system
    cp -rf templates/* $data_dir/templates/
    cp -rf static/* $data_dir/static/
    cp -rf locales/* $data_dir/locales/
    ## TODO if ini-file was generated, then replace with it, else keep example
    # cp -n example-config.ini $data_dir/config.ini || true
    cp -n example-config.ini $data_dir/ || true
    install -m755 bin/omnisearch $out/bin/omnisearch

    ln -s $out/bin/omnisearch $out/share/omnisearch/omnisearch

    #TEST:
    echo \
    "#!${bashNonInteractive}/bin/bash
    cd $out/share/omnisearch || exit
    # ../../bin/omnisearch & disown
    ./omnisearch & disown" \
    > omnisearch-run.sh

    install -Dm755 omnisearch-run.sh $out/bin/omnisearch-run

    echo '
    ${configINI}
    ' > generated-config.ini

    install -Dm644 generated-config.ini $out/share/omnisearch/config.ini

  '';
  # # NOTE TEMPORARY
  # cp -r $src/ $out/temp-src

  meta = {
    description = "Lightweight metasearch engine in C";
    platforms = platforms.linux;
    license = lib.licenses.gpl2Plus;
  };
}
