#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <dlfcn.h>

// PrintF
void (*printf_old)(const char *, ...);

void printf_hook(const char *format, ...) {
    va_list args;
    va_start(args, format);

    printf_old("[HOOKED] ");
    vprintf(format, args);

    va_end(args);
}

// Tweak Setup
void (*GumInterceptorReplaceFunc)(void * self, void * function_address, void * replacement_function, void * replacement_data, void ** original_function);
void *(*GumModuleFindExportByNameFunc)(const char * module_name, const char * symbol_name);
void (*GumInterceptorBeginTransactionFunc)(void * self);
void (*GumInterceptorEndTransactionFunc)(void * self);

void * magic;

void HookF(void * func, void * new, void ** old) {
    if (func != NULL) { 
        GumInterceptorBeginTransactionFunc(magic);
        GumInterceptorReplaceFunc(magic, func, new, NULL, old);
        GumInterceptorEndTransactionFunc(magic);
    }
}

/*
 NOTE:
 LoadFunction is what ammonia looks for when its injecting tweaks
*/
__attribute__((visibility("default"))) void LoadFunction(void * interceptor) {
    // Setup hooking
    magic = interceptor;
    void *hooking = dlopen("/usr/local/bin/ammonia/fridagum.dylib", RTLD_NOW | RTLD_GLOBAL);
    GumInterceptorReplaceFunc = dlsym(hooking, "gum_interceptor_replace");
    GumModuleFindExportByNameFunc = dlsym(hooking, "gum_module_find_export_by_name");
    GumInterceptorBeginTransactionFunc = dlsym(hooking, "gum_interceptor_begin_transaction");
    GumInterceptorEndTransactionFunc = dlsym(hooking, "gum_interceptor_end_transaction");

    // can call hookf as much as we want, whenever
    HookF(printf, printf_hook, (void **)&printf_old); 
}