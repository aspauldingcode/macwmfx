echo '#import <Cocoa/Cocoa.h>' > test.m
clang -framework Cocoa -isysroot $(xcrun --show-sdk-path) test.m -o test