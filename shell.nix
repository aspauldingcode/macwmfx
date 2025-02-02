{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    clang_16
    llvmPackages_16.libcxx
    darwin.apple_sdk.frameworks.Cocoa
    darwin.apple_sdk.frameworks.Foundation
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.QuartzCore
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.cctools # For basic C headers like stdarg.h
    darwin.apple_sdk.libs.xpc
  ];

  shellHook = ''
    export SDKROOT=${pkgs.darwin.apple_sdk.sdk}
    export NIX_CFLAGS_COMPILE="-isystem ${pkgs.darwin.apple_sdk.sdk}/usr/include"
  '';
} 