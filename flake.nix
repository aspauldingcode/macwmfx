{
  description = "macwmfx: Objective-C project built with Nix (replacing the Makefile)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        sdkRoot = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";
        # Use system's Clang directly
        cc = "/usr/bin/clang";

        # Installation script to symlink files to /usr/local/bin/ammonia/tweaks
        installScript = pkgs.writeScript "install-macwmfx" ''
          #!${pkgs.bash}/bin/bash

          # Create directories with cp
          sudo mkdir -p /usr/local/bin/ammonia/tweaks
          sudo mkdir -p /Library/Application\ Support/macwmfx

          # Remove existing files/symlinks
          sudo rm -f /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib
          sudo rm -f /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib.blacklist
          sudo rm -f /usr/local/bin/macwmfx

          # Create new symlinks
          sudo ln -sf $1/usr/local/bin/ammonia/tweaks/libmacwmfx.dylib /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib
          sudo ln -sf $1/usr/local/bin/ammonia/tweaks/libmacwmfx.dylib.blacklist /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib.blacklist
          sudo ln -sf $1/bin/macwmfx /usr/local/bin/macwmfx

          # Set permissions
          sudo chmod 755 /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib
          sudo chmod 644 /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib.blacklist
          sudo chmod 755 /usr/local/bin/macwmfx
          echo "Installed macwmfx files to /usr/local/bin/ammonia/tweaks"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            darwin.apple_sdk.frameworks.Cocoa
            darwin.apple_sdk.frameworks.Foundation
            darwin.apple_sdk.frameworks.AppKit
            darwin.apple_sdk.frameworks.QuartzCore
            darwin.apple_sdk.frameworks.CoreFoundation
          ];
        };

        packages.macwmfx = pkgs.stdenv.mkDerivation {
          pname = "macwmfx";
          version = "1.0.0";
          src = ./.;

          buildInputs = with pkgs; [
            darwin.apple_sdk.frameworks.Cocoa
            darwin.apple_sdk.frameworks.Foundation
            darwin.apple_sdk.frameworks.AppKit
            darwin.apple_sdk.frameworks.QuartzCore
            darwin.apple_sdk.frameworks.CoreFoundation
          ];

          buildPhase = ''
            echo "Building with Clang: ${cc}"
            echo "SDK Root: ${sdkRoot}"

            mkdir -p build/macwmfx

            # Compile all .m files except CLITool.m
            find . -type f -name "*.m" ! -path "./.ccls-cache/*" ! -name "CLITool.m" | while read -r src; do
              obj="build/macwmfx/''${src#./}"
              obj="''${obj%.m}.o"
              mkdir -p "$(dirname "$obj")"

              ${cc} \
                -fmodules \
                -fobjc-arc \
                -Wall \
                -Wextra \
                -O2 \
                -isysroot ${sdkRoot} \
                -I${sdkRoot}/System/Library/Frameworks/AppKit.framework/Headers \
                -I${sdkRoot}/System/Library/Frameworks/Foundation.framework/Headers \
                -iframework ${sdkRoot}/System/Library/Frameworks \
                -F${sdkRoot}/System/Library/Frameworks \
                -F/System/Library/PrivateFrameworks \
                -Iheaders \
                -Iconfig \
                -IZKSwizzle \
                -c "$src" \
                -o "$obj"
            done

            # Link dynamic library
            ${cc} \
              -dynamiclib \
              -install_name "@rpath/libmacwmfx.dylib" \
              -compatibility_version 1.0.0 \
              -current_version 1.0.0 \
              $(find build/macwmfx -name "*.o") \
              -framework Foundation \
              -framework AppKit \
              -framework QuartzCore \
              -framework Cocoa \
              -framework CoreFoundation \
              -o build/libmacwmfx.dylib

            # Build CLI tool
            ${cc} \
              -fmodules \
              -fobjc-arc \
              -Wall \
              -Wextra \
              -O2 \
              -isysroot ${sdkRoot} \
              -I${sdkRoot}/System/Library/Frameworks/AppKit.framework/Headers \
              -I${sdkRoot}/System/Library/Frameworks/Foundation.framework/Headers \
              -iframework ${sdkRoot}/System/Library/Frameworks \
              -F${sdkRoot}/System/Library/Frameworks \
              -F/System/Library/PrivateFrameworks \
              -Iheaders \
              -Iconfig \
              -IZKSwizzle \
              ./macwmfx/CLITool.m \
              build/libmacwmfx.dylib \
              -framework Foundation \
              -framework AppKit \
              -framework QuartzCore \
              -framework Cocoa \
              -framework CoreFoundation \
              -Wl,-rpath,/usr/local/bin/ammonia/tweaks \
              -o build/macwmfx_cli
          '';

          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/usr/local/bin/ammonia/tweaks
            cp build/macwmfx_cli $out/bin/macwmfx
            cp build/libmacwmfx.dylib $out/usr/local/bin/ammonia/tweaks/
            cp ./libmacwmfx.dylib.blacklist $out/usr/local/bin/ammonia/tweaks/

            # Copy install script
            mkdir -p $out/bin
            cp ${installScript} $out/bin/install-macwmfx
            chmod +x $out/bin/install-macwmfx
          '';

          meta = with pkgs.lib; {
            description = "macwmfx: macOS window management tweak built using Nix (replacing the Makefile)";
            license = licenses.mit;
            platforms = [
              "x86_64-darwin"
              "aarch64-darwin"
            ];
          };
        };

        apps.default = flake-utils.lib.mkApp {
          drv = pkgs.writeScriptBin "install-macwmfx" ''
            #!${pkgs.bash}/bin/bash
            ${self.packages.${system}.macwmfx}/bin/install-macwmfx ${self.packages.${system}.macwmfx}
          '';
        };
      }
    );
}
