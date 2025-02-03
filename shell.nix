{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    clang_19
    llvmPackages_19.libcxx
    darwin.apple_sdk.frameworks.Cocoa
    darwin.apple_sdk.frameworks.Foundation
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.QuartzCore
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.cctools # For basic C headers like stdarg.h
    darwin.apple_sdk.libs.xpc
  ];

  shellHook = ''
    echo '#import <Cocoa/Cocoa.h>' > test.m
    echo 'int main() { return 0; }' >> test.m
    clang -framework Cocoa -isysroot $(xcrun --sdk macosx --show-sdk-path) test.m -o test
  '';
}
