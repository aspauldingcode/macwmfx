// -*- C++ -*-
//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef _LIBCPP___CONFIGURATION_AVAILABILITY_H
#define _LIBCPP___CONFIGURATION_AVAILABILITY_H

#include <__configuration/compiler.h>
#include <__configuration/language.h>

#if !defined(_LIBCPP_HAS_NO_PRAGMA_SYSTEM_HEADER)
#  pragma GCC system_header
#endif

// Libc++ is shipped by various vendors. In particular, it is used as a system
// library on macOS, iOS and other Apple platforms. In order for users to be
// able to compile a binary that is intended to be deployed to an older version
// of a platform, Clang provides availability attributes [1]. These attributes
// can be placed on declarations and are used to describe the life cycle of a
// symbol in the library.
//
// The main goal is to ensure a compile-time error if a symbol that hasn't been
// introduced in a previously released library is used in a program that targets
// that previously released library. Normally, this would be a load-time error
// when one tries to launch the program against the older library.
//
// For example, the filesystem library was introduced in the dylib in LLVM 9.
// On Apple platforms, this corresponds to macOS 10.15. If a user compiles on
// a macOS 10.15 host but targets macOS 10.13 with their program, the compiler
// would normally not complain (because the required declarations are in the
// headers), but the dynamic loader would fail to find the symbols when actually
// trying to launch the program on macOS 10.13. To turn this into a compile-time
// issue instead, declarations are annotated with when they were introduced, and
// the compiler can produce a diagnostic if the program references something that
// isn't available on the deployment target.
//
// This mechanism is general in nature, and any vendor can add their markup to
// the library (see below). Whenever a new feature is added that requires support
// in the shared library, two macros are added below to allow marking the feature
// as unavailable:
// 1. A macro named `_LIBCPP_AVAILABILITY_HAS_<feature>` which must be defined
//    to `_LIBCPP_INTRODUCED_IN_<version>` for the appropriate LLVM version.
// 2. A macro named `_LIBCPP_AVAILABILITY_<feature>`, which must be defined to
//    `_LIBCPP_INTRODUCED_IN_<version>_MARKUP` for the appropriate LLVM version.
//
// When vendors decide to ship the feature as part of their shared library, they
// can update the `_LIBCPP_INTRODUCED_IN_<version>` macro (and the markup counterpart)
// based on the platform version they shipped that version of LLVM in. The library
// will then use this markup to provide an optimal user experience on these platforms.
//
// Furthermore, many features in the standard library have corresponding
// feature-test macros. The `_LIBCPP_AVAILABILITY_HAS_<feature>` macros
// are checked by the corresponding feature-test macros generated by
// generate_feature_test_macro_components.py to ensure that the library
// doesn't announce a feature as being implemented if it is unavailable on
// the deployment target.
//
// Note that this mechanism is disabled by default in the "upstream" libc++.
// Availability annotations are only meaningful when shipping libc++ inside
// a platform (i.e. as a system library), and so vendors that want them should
// turn those annotations on at CMake configuration time.
//
// [1]: https://clang.llvm.org/docs/AttributeReference.html#availability

// For backwards compatibility, allow users to define _LIBCPP_DISABLE_AVAILABILITY
// for a while.
#if defined(_LIBCPP_DISABLE_AVAILABILITY)
#  if !defined(_LIBCPP_HAS_NO_VENDOR_AVAILABILITY_ANNOTATIONS)
#    define _LIBCPP_HAS_NO_VENDOR_AVAILABILITY_ANNOTATIONS
#  endif
#endif

// Availability markup is disabled when building the library, or when a non-Clang
// compiler is used because only Clang supports the necessary attributes.
#if defined(_LIBCPP_BUILDING_LIBRARY) || defined(_LIBCXXABI_BUILDING_LIBRARY) || !defined(_LIBCPP_COMPILER_CLANG_BASED)
#  if !defined(_LIBCPP_HAS_NO_VENDOR_AVAILABILITY_ANNOTATIONS)
#    define _LIBCPP_HAS_NO_VENDOR_AVAILABILITY_ANNOTATIONS
#  endif
#endif

// When availability annotations are disabled, we take for granted that features introduced
// in all versions of the library are available.
#if defined(_LIBCPP_HAS_NO_VENDOR_AVAILABILITY_ANNOTATIONS)

#  define _LIBCPP_INTRODUCED_IN_LLVM_19 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_19_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_18 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_18_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_17 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_17_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_16 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_16_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_15 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_15_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_14 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_14_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_13 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_13_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_12 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_12_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_11 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_11_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_10 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_10_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_9 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_9_ATTRIBUTE      /* nothing */
#  define _LIBCPP_INTRODUCED_IN_LLVM_9_ATTRIBUTE_PUSH /* nothing */
#  define _LIBCPP_INTRODUCED_IN_LLVM_9_ATTRIBUTE_POP  /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_8 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_8_ATTRIBUTE /* nothing */

#  define _LIBCPP_INTRODUCED_IN_LLVM_4 1
#  define _LIBCPP_INTRODUCED_IN_LLVM_4_ATTRIBUTE /* nothing */

#elif defined(__APPLE__)

// clang-format off

// LLVM 19
// TODO: Fill this in
#  define _LIBCPP_INTRODUCED_IN_LLVM_19 0
#  define _LIBCPP_INTRODUCED_IN_LLVM_19_ATTRIBUTE __attribute__((unavailable))

// LLVM 18
// TODO: Fill this in
#  define _LIBCPP_INTRODUCED_IN_LLVM_18 0
#  define _LIBCPP_INTRODUCED_IN_LLVM_18_ATTRIBUTE __attribute__((unavailable))

// LLVM 17
#  if (defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 140400) ||       \
      (defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ < 170400) ||     \
      (defined(__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__ < 170400) ||             \
      (defined(__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__ < 100400)
#    define _LIBCPP_INTRODUCED_IN_LLVM_17 0
#  else
#    define _LIBCPP_INTRODUCED_IN_LLVM_17 1
#  endif
#  define _LIBCPP_INTRODUCED_IN_LLVM_17_ATTRIBUTE                                                                 \
    __attribute__((availability(macos, strict, introduced = 14.4)))                                               \
    __attribute__((availability(ios, strict, introduced = 17.4)))                                                 \
    __attribute__((availability(tvos, strict, introduced = 17.4)))                                                \
    __attribute__((availability(watchos, strict, introduced = 10.4)))

// LLVM 16
#  if (defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 140000) ||       \
      (defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ < 170000) ||     \
      (defined(__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__ < 170000) ||             \
      (defined(__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__ < 100000)
#    define _LIBCPP_INTRODUCED_IN_LLVM_16 0
#  else
#    define _LIBCPP_INTRODUCED_IN_LLVM_16 1
#  endif
#  define _LIBCPP_INTRODUCED_IN_LLVM_16_ATTRIBUTE                                                                 \
    __attribute__((availability(macos, strict, introduced = 14.0)))                                               \
    __attribute__((availability(ios, strict, introduced = 17.0)))                                                 \
    __attribute__((availability(tvos, strict, introduced = 17.0)))                                                \
    __attribute__((availability(watchos, strict, introduced = 10.0)))

// LLVM 15
#  if (defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 130400) ||   \
      (defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ < 160500) || \
      (defined(__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__ < 160500) ||         \
      (defined(__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__ < 90500)
#    define _LIBCPP_INTRODUCED_IN_LLVM_15 0
#  else
#    define _LIBCPP_INTRODUCED_IN_LLVM_15 1
#  endif
#  define _LIBCPP_INTRODUCED_IN_LLVM_15_ATTRIBUTE                                                                 \
    __attribute__((availability(macos, strict, introduced = 13.4)))                                               \
    __attribute__((availability(ios, strict, introduced = 16.5)))                                                 \
    __attribute__((availability(tvos, strict, introduced = 16.5)))                                                \
    __attribute__((availability(watchos, strict, introduced = 9.5)))

// LLVM 14
#  define _LIBCPP_INTRODUCED_IN_LLVM_14 _LIBCPP_INTRODUCED_IN_LLVM_15
#  define _LIBCPP_INTRODUCED_IN_LLVM_14_ATTRIBUTE _LIBCPP_INTRODUCED_IN_LLVM_15_ATTRIBUTE

// LLVM 13
#  if (defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 130000) ||   \
      (defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ < 160000) || \
      (defined(__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__ < 160000) ||         \
      (defined(__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__ < 90000)
#    define _LIBCPP_INTRODUCED_IN_LLVM_13 0
#  else
#    define _LIBCPP_INTRODUCED_IN_LLVM_13 1
#  endif
#  define _LIBCPP_INTRODUCED_IN_LLVM_13_ATTRIBUTE                                                                 \
    __attribute__((availability(macos, strict, introduced = 13.0)))                                               \
    __attribute__((availability(ios, strict, introduced = 16.0)))                                                 \
    __attribute__((availability(tvos, strict, introduced = 16.0)))                                                \
    __attribute__((availability(watchos, strict, introduced = 9.0)))

// LLVM 12
#  if (defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 120300)   ||     \
      (defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ < 150300) ||     \
      (defined(__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__ < 150300)         ||     \
      (defined(__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__ < 80300)
#    define _LIBCPP_INTRODUCED_IN_LLVM_12 0
#  else
#    define _LIBCPP_INTRODUCED_IN_LLVM_12 1
#  endif
#  define _LIBCPP_INTRODUCED_IN_LLVM_12_ATTRIBUTE                                                                 \
    __attribute__((availability(macos, strict, introduced = 12.3)))                                               \
    __attribute__((availability(ios, strict, introduced = 15.3)))                                                 \
    __attribute__((availability(tvos, strict, introduced = 15.3)))                                                \
    __attribute__((availability(watchos, strict, introduced = 8.3)))

// LLVM 11
#  if (defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 110000) ||   \
      (defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ < 140000) || \
      (defined(__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__ < 140000) ||         \
      (defined(__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__ < 70000)
#    define _LIBCPP_INTRODUCED_IN_LLVM_11 0
#  else
#    define _LIBCPP_INTRODUCED_IN_LLVM_11 1
#  endif
#  define _LIBCPP_INTRODUCED_IN_LLVM_11_ATTRIBUTE                                                                 \
    __attribute__((availability(macos, strict, introduced = 11.0)))                                               \
    __attribute__((availability(ios, strict, introduced = 14.0)))                                                 \
    __attribute__((availability(tvos, strict, introduced = 14.0)))                                                \
    __attribute__((availability(watchos, strict, introduced = 7.0)))

// LLVM 10
#  define _LIBCPP_INTRODUCED_IN_LLVM_10 _LIBCPP_INTRODUCED_IN_LLVM_11
#  define _LIBCPP_INTRODUCED_IN_LLVM_10_ATTRIBUTE _LIBCPP_INTRODUCED_IN_LLVM_11_ATTRIBUTE

// LLVM 9
#  if (defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 101500) ||   \
      (defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ < 130000) || \
      (defined(__ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_TV_OS_VERSION_MIN_REQUIRED__ < 130000) ||         \
      (defined(__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__ < 60000)
#    define _LIBCPP_INTRODUCED_IN_LLVM_9 0
#  else
#    define _LIBCPP_INTRODUCED_IN_LLVM_9 1
#  endif
#  define _LIBCPP_INTRODUCED_IN_LLVM_9_ATTRIBUTE                                                                  \
    __attribute__((availability(macos, strict, introduced = 10.15)))                                              \
    __attribute__((availability(ios, strict, introduced = 13.0)))                                                 \
    __attribute__((availability(tvos, strict, introduced = 13.0)))                                                \
    __attribute__((availability(watchos, strict, introduced = 6.0)))
#  define _LIBCPP_INTRODUCED_IN_LLVM_9_ATTRIBUTE_PUSH                                                                            \
    _Pragma("clang attribute push(__attribute__((availability(macos,strict,introduced=10.15))), apply_to=any(function,record))") \
    _Pragma("clang attribute push(__attribute__((availability(ios,strict,introduced=13.0))), apply_to=any(function,record))")    \
    _Pragma("clang attribute push(__attribute__((availability(tvos,strict,introduced=13.0))), apply_to=any(function,record))")   \
    _Pragma("clang attribute push(__attribute__((availability(watchos,strict,introduced=6.0))), apply_to=any(function,record))")
#  define _LIBCPP_INTRODUCED_IN_LLVM_9_ATTRIBUTE_POP                                                                    \
    _Pragma("clang attribute pop") \
    _Pragma("clang attribute pop") \
    _Pragma("clang attribute pop") \
    _Pragma("clang attribute pop")

// LLVM 4
#  if defined(__ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_WATCH_OS_VERSION_MIN_REQUIRED__ < 50000
#    define _LIBCPP_INTRODUCED_IN_LLVM_4 0
#  else
#    define _LIBCPP_INTRODUCED_IN_LLVM_4 1
#  endif
#  define _LIBCPP_INTRODUCED_IN_LLVM_4_ATTRIBUTE __attribute__((availability(watchos, strict, introduced = 5.0)))

// clang-format on

#else

// ...New vendors can add availability markup here...

#  error                                                                                                               \
      "It looks like you're trying to enable vendor availability markup, but you haven't defined the corresponding macros yet!"

#endif

// These macros control the availability of std::bad_optional_access and
// other exception types. These were put in the shared library to prevent
// code bloat from every user program defining the vtable for these exception
// types.
//
// Note that when exceptions are disabled, the methods that normally throw
// these exceptions can be used even on older deployment targets, but those
// methods will abort instead of throwing.
#define _LIBCPP_AVAILABILITY_HAS_BAD_OPTIONAL_ACCESS _LIBCPP_INTRODUCED_IN_LLVM_4
#define _LIBCPP_AVAILABILITY_BAD_OPTIONAL_ACCESS _LIBCPP_INTRODUCED_IN_LLVM_4_ATTRIBUTE

#define _LIBCPP_AVAILABILITY_HAS_BAD_VARIANT_ACCESS _LIBCPP_INTRODUCED_IN_LLVM_4
#define _LIBCPP_AVAILABILITY_BAD_VARIANT_ACCESS _LIBCPP_INTRODUCED_IN_LLVM_4_ATTRIBUTE

#define _LIBCPP_AVAILABILITY_HAS_BAD_ANY_CAST _LIBCPP_INTRODUCED_IN_LLVM_4
#define _LIBCPP_AVAILABILITY_BAD_ANY_CAST _LIBCPP_INTRODUCED_IN_LLVM_4_ATTRIBUTE

// These macros control the availability of all parts of <filesystem> that
// depend on something in the dylib.
#define _LIBCPP_AVAILABILITY_HAS_FILESYSTEM_LIBRARY _LIBCPP_INTRODUCED_IN_LLVM_9
#define _LIBCPP_AVAILABILITY_FILESYSTEM_LIBRARY _LIBCPP_INTRODUCED_IN_LLVM_9_ATTRIBUTE
#define _LIBCPP_AVAILABILITY_FILESYSTEM_LIBRARY_PUSH _LIBCPP_INTRODUCED_IN_LLVM_9_ATTRIBUTE_PUSH
#define _LIBCPP_AVAILABILITY_FILESYSTEM_LIBRARY_POP _LIBCPP_INTRODUCED_IN_LLVM_9_ATTRIBUTE_POP

// This controls the availability of the C++20 synchronization library,
// which requires shared library support for various operations
// (see libcxx/src/atomic.cpp). This includes <barier>, <latch>,
// <semaphore>, and notification functions on std::atomic.
#define _LIBCPP_AVAILABILITY_HAS_SYNC _LIBCPP_INTRODUCED_IN_LLVM_11
#define _LIBCPP_AVAILABILITY_SYNC _LIBCPP_INTRODUCED_IN_LLVM_11_ATTRIBUTE

// Enable additional explicit instantiations of iostreams components. This
// reduces the number of weak definitions generated in programs that use
// iostreams by providing a single strong definition in the shared library.
//
// TODO: Enable additional explicit instantiations on GCC once it supports exclude_from_explicit_instantiation,
//       or once libc++ doesn't use the attribute anymore.
// TODO: Enable them on Windows once https://llvm.org/PR41018 has been fixed.
#if !defined(_LIBCPP_COMPILER_GCC) && !defined(_WIN32)
#  define _LIBCPP_AVAILABILITY_HAS_ADDITIONAL_IOSTREAM_EXPLICIT_INSTANTIATIONS_1 _LIBCPP_INTRODUCED_IN_LLVM_12
#else
#  define _LIBCPP_AVAILABILITY_HAS_ADDITIONAL_IOSTREAM_EXPLICIT_INSTANTIATIONS_1 0
#endif

// This controls the availability of floating-point std::to_chars functions.
// These overloads were added later than the integer overloads.
#define _LIBCPP_AVAILABILITY_HAS_TO_CHARS_FLOATING_POINT _LIBCPP_INTRODUCED_IN_LLVM_14
#define _LIBCPP_AVAILABILITY_TO_CHARS_FLOATING_POINT _LIBCPP_INTRODUCED_IN_LLVM_14_ATTRIBUTE

// This controls whether the library claims to provide a default verbose
// termination function, and consequently whether the headers will try
// to use it when the mechanism isn't overriden at compile-time.
#define _LIBCPP_AVAILABILITY_HAS_VERBOSE_ABORT _LIBCPP_INTRODUCED_IN_LLVM_15
#define _LIBCPP_AVAILABILITY_VERBOSE_ABORT _LIBCPP_INTRODUCED_IN_LLVM_15_ATTRIBUTE

// This controls the availability of the C++17 std::pmr library,
// which is implemented in large part in the built library.
//
// TODO: Enable std::pmr markup once https://github.com/llvm/llvm-project/issues/40340 has been fixed
//       Until then, it is possible for folks to try to use `std::pmr` when back-deploying to targets that don't support
//       it and it'll be a load-time error, but we don't have a good alternative because the library won't compile if we
//       use availability annotations until that bug has been fixed.
#define _LIBCPP_AVAILABILITY_HAS_PMR _LIBCPP_INTRODUCED_IN_LLVM_16
#define _LIBCPP_AVAILABILITY_PMR

// These macros controls the availability of __cxa_init_primary_exception
// in the built library, which std::make_exception_ptr might use
// (see libcxx/include/__exception/exception_ptr.h).
#define _LIBCPP_AVAILABILITY_HAS_INIT_PRIMARY_EXCEPTION _LIBCPP_INTRODUCED_IN_LLVM_18
#define _LIBCPP_AVAILABILITY_INIT_PRIMARY_EXCEPTION _LIBCPP_INTRODUCED_IN_LLVM_18_ATTRIBUTE

// This controls the availability of C++23 <print>, which
// has a dependency on the built library (it needs access to
// the underlying buffer types of std::cout, std::cerr, and std::clog.
#define _LIBCPP_AVAILABILITY_HAS_PRINT _LIBCPP_INTRODUCED_IN_LLVM_18
#define _LIBCPP_AVAILABILITY_PRINT _LIBCPP_INTRODUCED_IN_LLVM_18_ATTRIBUTE

// This controls the availability of the C++20 time zone database.
// The parser code is built in the library.
#define _LIBCPP_AVAILABILITY_HAS_TZDB _LIBCPP_INTRODUCED_IN_LLVM_19
#define _LIBCPP_AVAILABILITY_TZDB _LIBCPP_INTRODUCED_IN_LLVM_19_ATTRIBUTE

// These macros determine whether we assume that std::bad_function_call and
// std::bad_expected_access provide a key function in the dylib. This allows
// centralizing their vtable and typeinfo instead of having all TUs provide
// a weak definition that then gets deduplicated.
#define _LIBCPP_AVAILABILITY_HAS_BAD_FUNCTION_CALL_KEY_FUNCTION _LIBCPP_INTRODUCED_IN_LLVM_19
#define _LIBCPP_AVAILABILITY_BAD_FUNCTION_CALL_KEY_FUNCTION _LIBCPP_INTRODUCED_IN_LLVM_19_ATTRIBUTE
#define _LIBCPP_AVAILABILITY_HAS_BAD_EXPECTED_ACCESS_KEY_FUNCTION _LIBCPP_INTRODUCED_IN_LLVM_19
#define _LIBCPP_AVAILABILITY_BAD_EXPECTED_ACCESS_KEY_FUNCTION _LIBCPP_INTRODUCED_IN_LLVM_19_ATTRIBUTE

// Define availability attributes that depend on _LIBCPP_HAS_NO_EXCEPTIONS.
// Those are defined in terms of the availability attributes above, and
// should not be vendor-specific.
#if defined(_LIBCPP_HAS_NO_EXCEPTIONS)
#  define _LIBCPP_AVAILABILITY_THROW_BAD_ANY_CAST
#  define _LIBCPP_AVAILABILITY_THROW_BAD_OPTIONAL_ACCESS
#  define _LIBCPP_AVAILABILITY_THROW_BAD_VARIANT_ACCESS
#else
#  define _LIBCPP_AVAILABILITY_THROW_BAD_ANY_CAST _LIBCPP_AVAILABILITY_BAD_ANY_CAST
#  define _LIBCPP_AVAILABILITY_THROW_BAD_OPTIONAL_ACCESS _LIBCPP_AVAILABILITY_BAD_OPTIONAL_ACCESS
#  define _LIBCPP_AVAILABILITY_THROW_BAD_VARIANT_ACCESS _LIBCPP_AVAILABILITY_BAD_VARIANT_ACCESS
#endif

// Define availability attributes that depend on both
// _LIBCPP_HAS_NO_EXCEPTIONS and _LIBCPP_HAS_NO_RTTI.
#if defined(_LIBCPP_HAS_NO_EXCEPTIONS) || defined(_LIBCPP_HAS_NO_RTTI)
#  undef _LIBCPP_AVAILABILITY_HAS_INIT_PRIMARY_EXCEPTION
#  undef _LIBCPP_AVAILABILITY_INIT_PRIMARY_EXCEPTION
#  define _LIBCPP_AVAILABILITY_HAS_INIT_PRIMARY_EXCEPTION 0
#  define _LIBCPP_AVAILABILITY_INIT_PRIMARY_EXCEPTION
#endif

#endif // _LIBCPP___CONFIGURATION_AVAILABILITY_H
