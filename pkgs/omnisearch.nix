{ stdenv
, libxml2
, curl
, openssl
, git
, lib
,
}:
let
  inherit (lib) platforms;
  inherit (builtins) fetchurl;

  repoURLBase = "https://git.bwaaa.monster";
  unChangeLICENSE = fetchurl {
    url = "https://git.bwaaa.monster/omnisearch/plain/LICENSE";
    sha256 = "1i86m5vk5na9ya6hcci4z1p9riizls1fanpb9z5l810qm1i7062q";
  };

  beaker = stdenv.mkDerivation rec {
    pname = "beaker";
    version = "360d6271e1a20d128430e52637d5d35f4c706ca5";

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

  #FIXME: groups/users -- instead be in options-config
  # omnisearchService = # dosini
  #   ''
  #     [Unit]
  #     Description=Omnisearch Web Search Server
  #     After=network.target
  #
  #     [Service]
  #     Type=simple
  #     User=omnisearch
  #     Group=omnisearch
  #     WorkingDirectory=$out/etc/omnisearch
  #     ExecStart=$out/bin/omnisearch
  #     Restart=always
  #     RestartSec=5
  #     PrivateTmp=yes
  #     NoNewPrivileges=yes
  #
  #     [Install]
  #     WantedBy=multi-user.target
  #   '';
  #TODO: have the systemd-service in options-config instead
  #TEST: reference of Makefile install-systemd
  # PREFIX      ?= /usr
  # DATA_DIR    ?= /etc/omnisearch
  # CONF_DIR    ?= /etc/omnisearch
  # VAR_DIR     ?= /var/lib/omnisearch
  # LOG_DIR     ?= /var/log/omnisearch
  # CACHE_DIR   ?= /var/cache/omnisearch
  # install-systemd: $(TARGET)
  #   @mkdir -p $(DATA_DIR)/templates $(DATA_DIR)/static $(DATA_DIR)/locales $(LOG_DIR) $(CACHE_DIR)
  #   @cp -rf templates/* $(DATA_DIR)/templates/
  #   @cp -rf static/* $(DATA_DIR)/static/
  #   @cp -rf locales/* $(DATA_DIR)/locales/
  #   @cp -n example-config.ini $(DATA_DIR)/config.ini || true
  #   install -m 755 $(TARGET) $(INSTALL_BIN_DIR)/omnisearch
  #   @echo "Setting up user '$(USER)'..."
  #   @(grep -q '^$(GROUP):' /etc/group || groupadd $(GROUP)) 2>/dev/null || true
  #   @id -u $(USER) >/dev/null 2>&1 || useradd --system --home $(DATA_DIR) --shell /usr/sbin/nologin -g $(GROUP) $(USER)
  #   @chown -R $(USER):$(GROUP) $(LOG_DIR) $(CACHE_DIR) $(VAR_DIR) $(DATA_DIR) 2>/dev/null || true
  #   @chown $(USER):$(GROUP) $(DATA_DIR)/config.ini 2>/dev/null || true
  #   install -m 644 init/systemd/omnisearch.service $(SYSTEMD_DIR)/omnisearch.service
  #   @echo ""
  #   @echo "Config: $(DATA_DIR)/config.ini"
  #   @echo "Edit config with: nano $(DATA_DIR)/config.ini"
  #   @echo "Installed systemd service to $(SYSTEMD_DIR)/omnisearch.service"
  #   @echo "Run 'systemctl enable --now omnisearch' to start"

  #XXX: A hack, but it works...
  omnisearchRun = # sh
    ''
      cd $out/share/omnisearch
      ../../bin/omnisearch & disown
    '';
in
stdenv.mkDerivation rec {
  pname = "omnisearch";
  version = "499bb9b1268cd422619efdc46889960425462aae";

  src = fetchGit {
    url = "${repoURLBase}/${pname}";
    rev = version;
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

    install -Dm755 bin/omnisearch $out/bin/omnisearch
    cp -r $src/{templates,static,locales} -t $out/share/omnisearch/
    install -Dm644 example-config.ini $out/share/omnisearch/config.ini

    cat << EOF > omnisearch-run.sh
    ${omnisearchRun}
    EOF
    install -Dm755 omnisearch-run.sh $out/bin/omnisearch-run

    #TEST: temp
    cp -r $src/ $out/temp-src
  '';

  meta = {
    description = "Lightweight metasearch engine in C";
    platforms = platforms.linux;
    license = [ unChangeLICENSE ];
  };
}
