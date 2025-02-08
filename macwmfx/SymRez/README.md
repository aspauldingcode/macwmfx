# SymRez
When dlsym isn't enough

## When to use?
Although dlsym is very powerful, it usually plays by the rules and will not resolve non-exported symbols. This is where SymRez comes into play. SymRez works by manually resolving symbol names to their pointer locations in the symbol table inside Mach-O files. Works especially well for hooking symbolicated global variables, which dlsym will not :) 

Note: SymRez does not demangle symbols. The raw symbol name is required for this to work.

## API
```
#ifndef SymRez_h
#define SymRez_h

#ifdef __cplusplus
extern "C" {
#endif


#include <stdio.h>
#include <stdbool.h>

#define SR_DYLD_HDR ((void *) -1)

typedef const struct mach_header_64 mach_header;
typedef const struct mach_header_64* mach_header_t;

// return true to stop loop
typedef bool (*symrez_function_t)(char *symbol, void *ptr);

typedef struct symrez* symrez_t;

/*! @function symrez_new
    @abstract Create new symrez object. Caller must free.
    @param image_name Name or full path of the library to symbolicate. Pass NULL for current executable  */
symrez_t symrez_new(const char *image_name);

/*! @function symrez_new
    @abstract Create new symrez object. Caller must free.
    @param header  Pointer to the mach_header_64 to symbolicate. Pass NULL for current executable */
symrez_t symrez_new_mh(mach_header_t header);

/*! @function sr_resolve_symbol
    @abstract Find symbol address
    @param symrez symrez object created by symrez_new
    @param symbol Mangled symbol name
    @return Pointer to symbol location or NULL if not found */
void * sr_resolve_symbol(symrez_t symrez, const char *symbol);

/*! @function sr_for_each
    @abstract Loop through all symbols with a callback
    @param symrez symrez object created by symrez_new
    @param callback callback for processing each iteration. Return true to stop loop.
    @discussion String passed to 'callback' may be ephemeral . */
void sr_for_each(symrez_t symrez, symrez_function_t callback);

/*! @function sr_free
    @abstract Release all resources allocated for this symrez object */
void sr_free(symrez_t);

/*! @function symrez_resolve_once
    @abstract Lookup a single symbol. Does not allocate memory but not recommended for multiple lookups
    @param image_name Name or full path of the library to symbolicate. Pass NULL for current executable
    @return Pointer to symbol location or NULL if not found */
void * symrez_resolve_once(const char *image_name, const char *symbol);

/*! @function symrez_resolve_once_mh
    @abstract Lookup a single symbol. Does not allocate memory but not recommended for multiple lookups
    @param header  Pointer to the mach_header_64 to symbolicate. Pass NULL for current executable
    @return Pointer to symbol location or NULL if not found */
void * symrez_resolve_once_mh(mach_header_t header, const char *symbol);

#ifdef __cplusplus
}
#endif
#endif /* SymRez_h */
```

## Example
```
void* (*__CGSWindowByID)(int windowID);
void* (*__BunldeInfo)(const CFURLRef bundleURL);

...

symrez_t skylight = symrez_new(“SkyLight”);
if(skylight != NULL) {
	__CGSWindowByID = sr_resolve_symbol(skylight, "_CGSWindowByID");

symrez_t launchservices = symrez_new(“LaunchServices”);
if(launchservices != NULL) {
	__BundleInfo = sr_resolve_symbol(LaunchServices, "__ZN10BundleInfoC2EPK7__CFURL");
```
