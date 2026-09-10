#import "macwmfx_logging.h"

// Define the logging categories
os_log_t macwmfx_log_server;
os_log_t macwmfx_log_client;
os_log_t macwmfx_log_config;
os_log_t macwmfx_log_window;
os_log_t macwmfx_log_hook;
os_log_t macwmfx_log_cli;
os_log_t macwmfx_log_general;
os_log_t macwmfx_log_styler;
os_log_t macwmfx_log_engine;
os_log_t macwmfx_log_titlebar;
os_log_t macwmfx_log_traffic_lights;
os_log_t macwmfx_log_shadow;
os_log_t macwmfx_log_outline;
os_log_t macwmfx_log_corners;
os_log_t macwmfx_log_frame;
os_log_t macwmfx_log_drag_effects;

void macwmfx_logging_init(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Initialize all logging categories
    macwmfx_log_server = os_log_create(MACWMFX_SUBSYSTEM, "server");
    macwmfx_log_client = os_log_create(MACWMFX_SUBSYSTEM, "client");
    macwmfx_log_config = os_log_create(MACWMFX_SUBSYSTEM, "config");
    macwmfx_log_window = os_log_create(MACWMFX_SUBSYSTEM, "window");
    macwmfx_log_hook = os_log_create(MACWMFX_SUBSYSTEM, "hook");
    macwmfx_log_cli = os_log_create(MACWMFX_SUBSYSTEM, "cli");
    macwmfx_log_general = os_log_create(MACWMFX_SUBSYSTEM, "general");
    macwmfx_log_styler = os_log_create(MACWMFX_SUBSYSTEM, "styler");
    macwmfx_log_engine = os_log_create(MACWMFX_SUBSYSTEM, "engine");
    macwmfx_log_titlebar = os_log_create(MACWMFX_SUBSYSTEM, "titlebar");
    macwmfx_log_traffic_lights =
        os_log_create(MACWMFX_SUBSYSTEM, "traffic_lights");
    macwmfx_log_shadow = os_log_create(MACWMFX_SUBSYSTEM, "shadow");
    macwmfx_log_outline = os_log_create(MACWMFX_SUBSYSTEM, "outline");
    macwmfx_log_corners = os_log_create(MACWMFX_SUBSYSTEM, "corners");
    macwmfx_log_frame = os_log_create(MACWMFX_SUBSYSTEM, "frame");
    macwmfx_log_drag_effects = os_log_create(MACWMFX_SUBSYSTEM, "drag_effects");
  });
}
