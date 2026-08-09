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
  inherit (builtins) fetchurl;
  bash = "${bashNonInteractive}/bin/bash";
  inherit (lib.generators) toINI;

  pname = "omnisearch";
  gitHostURL = "https://git.bwaaa.monster";
  omnisearchRepoURL = "${gitHostURL}/omnisearch";
  unChangeLICENSE = fetchurl {
    url = "${omnisearchRepoURL}/plain/LICENSE";
    sha256 = "1i86m5vk5na9ya6hcci4z1p9riizls1fanpb9z5l810qm1i7062q";
  };

  beaker = stdenv.mkDerivation rec {
    name = "${pname}-${version}";
    pname = "beaker";
    version = "360d627";

    src = fetchGit {
      url = "${gitHostURL}/beaker";
      rev = "${version}1e1a20d128430e52637d5d35f4c706ca5";
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

  #INFO: These are default values + few overrides from example-config.ini.
  ## Just use .override if you want to change
  configINI = toINI { } (
    {
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
    // configINIOverrides
  );

  #XXX: A hack, but it works...
  omnisearchRun = # sh
    ''
      #!${bash}
      cd $out/share/omnisearch
      # ../../bin/omnisearch & disown
      ./omnisearch & disown
    '';
in
stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  inherit pname;
  version = "499bb9b";

  src = fetchGit {
    url = "${gitHostURL}/${pname}";
    rev = "${version}1268cd422619efdc46889960425462aae";
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

      #TODO: HOLY SHIT WORKS! Just systemd left.
      # will do it manually?
    '';

  installPhase = ''
    mkdir -p $out/{bin,share/omnisearch} # ,share/systemd/system

    # install -Dm755 bin/omnisearch $out/bin/omnisearch
    install -Dm755 bin/omnisearch $out/share/omnisearch/omnisearch
    cp -r $src/{templates,static,locales} -t $out/share/omnisearch/

    cat << EOF > omnisearch-run.sh
    ${omnisearchRun}
    EOF
    install -Dm755 omnisearch-run.sh $out/bin/omnisearch-run

    cat << EOF > generated-config.ini
    ${configINI}
    EOF
    install -Dm644 generated-config.ini $out/share/omnisearch/config.ini

    #TEST: temp
    cp -r $src/ $out/temp-src
  '';

  meta = {
    description = "Lightweight metasearch engine in C";
    platforms = platforms.linux;
    license = [ unChangeLICENSE ];
  };
}
