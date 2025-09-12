#pragma once

#include <os/log.h>

// Logging subsystem and categories
#define MACWMFX_SUBSYSTEM "com.aspauldingcode.macwmfx"

// Global logging categories
extern os_log_t macwmfx_log_server;
extern os_log_t macwmfx_log_client;
extern os_log_t macwmfx_log_config;
extern os_log_t macwmfx_log_window;
extern os_log_t macwmfx_log_hook;
extern os_log_t macwmfx_log_cli;
extern os_log_t macwmfx_log_general;
extern os_log_t macwmfx_log_titlebar;
extern os_log_t macwmfx_log_traffic_lights;
extern os_log_t macwmfx_log_shadow;
extern os_log_t macwmfx_log_outline;

// Convenience macros for common log levels
#define MACWMFX_LOG_INFO(category, ...) os_log_info(category, __VA_ARGS__)
#define MACWMFX_LOG_ERROR(category, ...) os_log_error(category, __VA_ARGS__)
#define MACWMFX_LOG_DEBUG(category, ...) os_log_debug(category, __VA_ARGS__)
#define MACWMFX_LOG_FAULT(category, ...) os_log_fault(category, __VA_ARGS__)
#define MACWMFX_LOG_WARNING(category, ...) os_log(category, __VA_ARGS__)
#define MACWMFX_LOG(category, ...) os_log(category, __VA_ARGS__)

// Legacy macros for backward compatibility - these will use os_log
#ifdef MACWMFX_DEBUG
    #define DLog(...) MACWMFX_LOG_INFO(macwmfx_log_general, __VA_ARGS__)
    #define VLog(...) MACWMFX_LOG_DEBUG(macwmfx_log_general, __VA_ARGS__)
#else
    #define DLog(...) do {} while(0)
    #define VLog(...) do {} while(0)
#endif

// Initialize logging - should be called once at startup
void macwmfx_logging_init(void);
