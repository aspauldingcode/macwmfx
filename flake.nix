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

        installScript = pkgs.writeScript "install-macwmfx" ''
          #!${pkgs.bash}/bin/bash
          set -ex  # Add error detection and command printing

          echo "Starting installation with package path: $1"

          # Create directories
          echo "Creating directories..."
          sudo mkdir -pv /usr/local/bin/ammonia/tweaks
          sudo mkdir -pv "/Library/Application Support/macwmfx"

          # Remove existing files
          echo "Removing existing files..."
          sudo rm -fv /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib
          sudo rm -fv /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib.blacklist
          sudo rm -fv /usr/local/bin/macwmfx

          # Copy files
          echo "Copying new files..."
          sudo cp -v $1/usr/local/bin/ammonia/tweaks/libmacwmfx.dylib /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib
          sudo cp -v $1/usr/local/bin/ammonia/tweaks/libmacwmfx.dylib.blacklist /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib.blacklist
          sudo cp -v $1/bin/macwmfx /usr/local/bin/macwmfx

          # Set permissions
          echo "Setting permissions..."
          sudo chmod -v 755 /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib
          sudo chmod -v 644 /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib.blacklist
          sudo chmod -v 755 /usr/local/bin/macwmfx

          echo "Installation completed successfully"

          # Verify the architectures of the installed dylib
          echo "Verifying installed dylib architectures:"
          lipo -info /usr/local/bin/ammonia/tweaks/libmacwmfx.dylib
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
            pkgs.swift
          ];
        };

        packages.macwmfx = pkgs.stdenv.mkDerivation {
          pname = "macwmfx";
          version = "0.0.01";
          src = ./.;

          buildInputs = with pkgs; [
            darwin.apple_sdk.frameworks.Foundation
            darwin.apple_sdk.frameworks.AppKit
            darwin.apple_sdk.frameworks.CoreGraphics
            darwin.apple_sdk.frameworks.ApplicationServices
            darwin.apple_sdk.frameworks.QuartzCore
            darwin.apple_sdk.frameworks.CoreFoundation
            darwin.apple_sdk.frameworks.CoreImage
            darwin.apple_sdk.frameworks.IOSurface
            darwin.apple_sdk.libs.xpc
            darwin.libobjc
            pkgs.swift
          ];

          preConfigure = ''
            # Override the default CC/CXX to use Xcode's clang directly.
            export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
            export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
            export CXXFLAGS="-stdlib=libc++"
            export LDFLAGS="-L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib -Wl,-U,_inject_entry"

            # Clear any extra flags inserted by the Nix clang wrapper.
            export NIX_CC_WRAPPER_FLAGS=""
          '';

          buildPhase = ''
            echo "Building with system Clang: ''${CC}"
            mkdir -p build/macwmfx

            # Compile all .m files except CLITool.m
            find . -type f -name "*.m" ! -path "./.ccls-cache/*" ! -name "CLITool.m" | while read -r src; do
              obj="build/macwmfx/''${src#./}"
              obj="''${obj%.m}.o"
              mkdir -p "$(dirname "$obj")"
              ''${CC} \
                -fmodules \
                -fobjc-arc \
                -fexceptions \
                -fvisibility=hidden \
                -Wall \
                -Wextra \
                -Wno-implicit-function-declaration \
                -O2 \
                -arch x86_64 -arch arm64 -arch arm64e \
                -mmacosx-version-min=13.0
                -isysroot ${sdkRoot} \
                -I${sdkRoot}/System/Library/Frameworks/AppKit.framework/Headers \
                -I${sdkRoot}/System/Library/Frameworks/Foundation.framework/Headers \
                -iframework ${sdkRoot}/System/Library/Frameworks \
                -F${sdkRoot}/System/Library/Frameworks \
                -F/System/Library/PrivateFrameworks \
                -Iheaders \
                -Iconfig \
                -IZKSwizzle \
                -ISymRez \
                -c "$src" \
                -o "$obj"
            done

            # Compile all .mm files
            find . -type f -name "*.mm" ! -path "./.ccls-cache/*" | while read -r src; do
              obj="build/macwmfx/''${src#./}"
              obj="''${obj%.mm}.o"
              mkdir -p "$(dirname "$obj")"
              ''${CXX} \
                -fmodules \
                -fobjc-arc \
                -fexceptions \
                -fvisibility=hidden \
                -Wall \
                -Wextra \
                -O2 \
                -arch x86_64 -arch arm64 -arch arm64e \
                -isysroot ${sdkRoot} \
                -I${sdkRoot}/System/Library/Frameworks/AppKit.framework/Headers \
                -I${sdkRoot}/System/Library/Frameworks/Foundation.framework/Headers \
                -iframework ${sdkRoot}/System/Library/Frameworks \
                -F${sdkRoot}/System/Library/Frameworks \
                -F/System/Library/PrivateFrameworks \
                -Iheaders \
                -Iconfig \
                -IZKSwizzle \
                -ISymRez \
                -c "$src" \
                -o "$obj"
            done

            # Compile all .c files
            find . -type f -name "*.c" ! -path "./.ccls-cache/*" | while read -r src; do
              obj="build/macwmfx/''${src#./}"
              obj="''${obj%.c}.o"
              mkdir -p "$(dirname "$obj")"
              ''${CC} \
                -Wall \
                -Wextra \
                -O2 \
                -fexceptions \
                -fvisibility=hidden \
                -arch x86_64 -arch arm64 -arch arm64e \
                -isysroot ${sdkRoot} \
                -I${sdkRoot}/System/Library/Frameworks/AppKit.framework/Headers \
                -I${sdkRoot}/System/Library/Frameworks/Foundation.framework/Headers \
                -iframework ${sdkRoot}/System/Library/Frameworks \
                -F${sdkRoot}/System/Library/Frameworks \
                -F/System/Library/PrivateFrameworks \
                -Iheaders \
                -Iconfig \
                -IZKSwizzle \
                -ISymRez \
                -c "$src" \
                -o "$obj"
            done

            # Compile all .cpp files
            find . -type f -name "*.cpp" ! -path "./.ccls-cache/*" | while read -r src; do
              obj="build/macwmfx/''${src#./}"
              obj="''${obj%.cpp}.o"
              mkdir -p "$(dirname "$obj")"
              ''${CXX} \
                -Wall \
                -Wextra \
                -O2 \
                -fexceptions \
                -fvisibility=hidden \
                -arch x86_64 -arch arm64 -arch arm64e \
                -isysroot ${sdkRoot} \
                -I${sdkRoot}/System/Library/Frameworks/AppKit.framework/Headers \
                -I${sdkRoot}/System/Library/Frameworks/Foundation.framework/Headers \
                -iframework ${sdkRoot}/System/Library/Frameworks \
                -F${sdkRoot}/System/Library/Frameworks \
                -F/System/Library/PrivateFrameworks \
                -Iheaders \
                -Iconfig \
                -ISymRez \
                -c "$src" \
                -o "$obj"
            done

            # Compile all .swift files except Package.swift
            find . -type f -name "*.swift" ! -name "Package.swift" ! -path "./.ccls-cache/*" | while read -r src; do
              obj="build/macwmfx/''${src#./}"
              obj="''${obj%.swift}.o"
              mkdir -p "$(dirname "$obj")"
              swiftc \
                -I./SymRez \
                -c "$src" \
                -o "$obj"
            done

            # Compile SymRez.c specifically
            mkdir -p "build/macwmfx/macwmfx/SymRez"
            ''${CC} \
              -Wall \
              -Wextra \
              -O2 \
              -fexceptions \
              -fvisibility=hidden \
              -arch x86_64 -arch arm64 -arch arm64e \
              -isysroot ${sdkRoot} \
              -fmodules \
              -fmodule-map-file=./macwmfx/SymRez/module.modulemap \
              -I${sdkRoot}/System/Library/Frameworks/AppKit.framework/Headers \
              -I${sdkRoot}/System/Library/Frameworks/Foundation.framework/Headers \
              -iframework ${sdkRoot}/System/Library/Frameworks \
              -F${sdkRoot}/System/Library/Frameworks \
              -F/System/Library/PrivateFrameworks \
              -Iheaders \
              -Iconfig \
              -IZKSwizzle \
              -ISymRez \
              -c ./macwmfx/SymRez/SymRez.c \
              -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib \
              -L./SymRez \
              -lsymrez

            # Link dynamic library
            ''${CXX} \
              -o build/libmacwmfx.dylib \
              -v
              -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib \
              -L./SymRez \
              -lsymrez
              -install_name "@rpath/libmacwmfx.dylib" \
              -compatibility_version 1.0.0 \
              -current_version 1.0.0 \
              -o build/libmacwmfx.dylib \
              -v
              -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib \
              -o build/libmacwmfx.dylib \
              -v
              -lsymrez
              -framework AppKit \
              -framework QuartzCore \
              -framework Cocoa \
              -framework CoreFoundation \
              -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib \
              -L./SymRez \
              -lsymrez
              -framework CoreGraphics \
              -framework IOSurface \
              -o build/libmacwmfx.dylib \
              -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib \
              -L./SymRez \
              -lsymrez
              -L${sdkRoot}/usr/lib \
              -stdlib=libc++ \
              -Wl,-U,_inject_entry \
              -o build/libmacwmfx.dylib \
              -v

            # Build CLI tool
            ''${CC} \
              -fmodules \
              -fobjc-arc \
              -fexceptions \
              -fvisibility=hidden \
              -Wall \
              -Wextra \
              -O2 \
              -arch x86_64 -arch arm64 -arch arm64e \
              -isysroot ${sdkRoot} \
              -I${sdkRoot}/System/Library/Frameworks/AppKit.framework/Headers \
              -I${sdkRoot}/System/Library/Frameworks/Foundation.framework/Headers \
              -iframework ${sdkRoot}/System/Library/Frameworks \
              -F${sdkRoot}/System/Library/Frameworks \
              -F/System/Library/PrivateFrameworks \
              -Iheaders \
              -Iconfig \
              -IZKSwizzle \
              -ISymRez \
              ./macwmfx/CLITool.m \
              build/libmacwmfx.dylib \
              -framework Foundation \
              -framework AppKit \
              -framework QuartzCore \
              -framework Cocoa \
              -framework CoreFoundation \
              -framework CoreGraphics \
              -framework IOSurface \
              -Wl,-rpath,/usr/local/bin/ammonia/tweaks \
              -Wl,-U,_inject_entry \
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
            set -ex  # Add error detection and command printing
            echo "Installing macwmfx..."
            echo "Package path: ${self.packages.${system}.macwmfx}"
            ${self.packages.${system}.macwmfx}/bin/install-macwmfx ${self.packages.${system}.macwmfx}
          '';
        };
      }
    );
}
