{
  description = "codename goose desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      version = "1.3.0";
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "goose-desktop";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/block/goose/releases/download/stable/goose_${version}_amd64.deb";
          sha256 = "sha256-t8gP2oPCVGPdV7kRl49z3TbrKJekubUhYqXvxeuD+jM=";
        };

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.makeWrapper
          pkgs.binutils
          pkgs.zstd
        ];

        # Add runtime dependencies for OpenGL and GSettings.
        buildInputs = with pkgs; [
          alsa-lib
          at-spi2-atk
          chromium.sandbox
          cups
          dbus
          expat
          gsettings-desktop-schemas
          gtk3
          libdrm
          libgbm
          libglvnd
          libxkbcommon
          nss
          pango
        ];

        unpackPhase = ''
          runHook preUnpack
          ar x $src
          tar -xf data.tar.zst
          runHook postUnpack
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib
          cp -r usr/lib/goose $out/lib/goose-desktop

          # Enhance the wrapper to set up the full runtime environment.
          makeWrapper $out/lib/goose-desktop/Goose $out/bin/goose-desktop \
            --set CHROME_DEVEL_SANDBOX ${pkgs.chromium.sandbox}/bin/chrome-sandbox \
            --prefix LD_LIBRARY_PATH : ${pkgs.libglvnd}/lib \
            --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share:${pkgs.gsettings-desktop-schemas}/share"

          mkdir -p $out/share
          cp -r usr/share/* $out/share/

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Your local AI agent, automating engineering tasks seamlessly.";
          homepage = "https://block.github.io/goose/";
          license = licenses.asl20;
          platforms = platforms.linux;
          maintainers = [
            {
              name = "Riley McLain";
              email = "riley.mclain@watts.ai";
            }
          ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ self.packages.${system}.default ];
      };
    };
}
