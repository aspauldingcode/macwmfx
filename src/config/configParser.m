#import "../shared/headers/macwmfx_Common.h"
#import "../shared/macwmfx_logging.h"
#import <objc/runtime.h>
#import <sys/event.h>
#import <sys/fcntl.h>

// Forward declaration of the styler's refresh method
@class macwmfxStyler;

@interface ConfigParser ()
@property(nonatomic, strong, readwrite) NSDictionary *rawConfig;
@property(nonatomic, copy) NSString *configPath;
@property(nonatomic, assign) int kqueueFD;
@property(nonatomic, assign) int configFileFD;
@property(nonatomic, strong) dispatch_source_t kqueueSource;
@property(nonatomic, strong) dispatch_source_t debounceTimer;
@end

@implementation ConfigParser

#pragma mark - Singleton

+ (instancetype)sharedInstance {
  static ConfigParser *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[ConfigParser alloc] init];
  });
  return sharedInstance;
}

#pragma mark - Initialization

- (instancetype)init {
  self = [super init];
  if (self) {
    _kqueueFD = -1;
    _configFileFD = -1;

    // XDG-style config path: ~/.config/macwmfx/config.json
    NSString *homeDir = NSHomeDirectory();
    self.configPath =
        [homeDir stringByAppendingPathComponent:@".config/macwmfx/config.json"];

    // Fallback to /Library/Application Support if XDG path doesn't exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.configPath]) {
      NSString *appSupportPath = @"/Library/Application Support/macwmfx";
      NSString *fallbackPath =
          [appSupportPath stringByAppendingPathComponent:@"config.json"];
      if ([[NSFileManager defaultManager] fileExistsAtPath:fallbackPath]) {
        self.configPath = fallbackPath;
      }
    }

    MACWMFX_LOG_INFO(macwmfx_log_config, "Config path: %@", self.configPath);
    [self loadConfig];
    [self startKqueueWatcher];
  }
  return self;
}

- (void)dealloc {
  [self stopKqueueWatcher];
}

#pragma mark - Config Loading

- (void)loadConfig {
  NSData *configData = [NSData dataWithContentsOfFile:self.configPath];
  if (!configData) {
    MACWMFX_LOG_INFO(macwmfx_log_config, "No config found at %@",
                     self.configPath);
    return;
  }

  NSError *error = nil;
  NSDictionary *config = [NSJSONSerialization JSONObjectWithData:configData
                                                         options:0
                                                           error:&error];
  if (error || !config) {
    MACWMFX_LOG_ERROR(macwmfx_log_config, "Error parsing config file: %@",
                      error);
    return;
  }

  self.rawConfig = config;
  MACWMFX_LOG_INFO(macwmfx_log_config, "macwmfx config loaded from %@",
                   self.configPath);
}

- (void)reloadConfig {
  MACWMFX_LOG_INFO(macwmfx_log_config, "Hot-reloading config...");
  [self loadConfig];

  // Refresh all windows after config reload
  // Use performSelector to avoid compile-time dependency
  Class stylerClass = NSClassFromString(@"macwmfxStyler");
  if (stylerClass &&
      [stylerClass respondsToSelector:@selector(refreshAllWindows)]) {
    [stylerClass performSelector:@selector(refreshAllWindows)];
    MACWMFX_LOG_INFO(macwmfx_log_config,
                     "Config hot-reload complete, all windows refreshed");
  }
}

#pragma mark - Kqueue File Watching

- (void)startKqueueWatcher {
  // Only watch if we have a valid config path
  if (!self.configPath || self.configPath.length == 0) {
    MACWMFX_LOG_DEBUG(macwmfx_log_config, "No config path to watch");
    return;
  }

  // Create kqueue
  self.kqueueFD = kqueue();
  if (self.kqueueFD < 0) {
    MACWMFX_LOG_ERROR(macwmfx_log_config, "Failed to create kqueue: %s",
                      strerror(errno));
    return;
  }

  // Open the config file for monitoring
  [self openConfigFileForWatching];

  if (self.configFileFD < 0) {
    // Config file doesn't exist yet, watch the directory instead
    [self watchConfigDirectory];
    return;
  }

  // Register file events with kqueue
  [self registerKqueueEvents];

  // Start dispatch source for kqueue events
  [self startKqueueDispatchSource];

  MACWMFX_LOG_INFO(macwmfx_log_config, "Kqueue file watcher started for: %@",
                   self.configPath);
}

- (void)openConfigFileForWatching {
  const char *path = [self.configPath fileSystemRepresentation];
  self.configFileFD = open(path, O_RDONLY | O_EVTONLY);

  if (self.configFileFD < 0) {
    MACWMFX_LOG_DEBUG(macwmfx_log_config,
                      "Could not open config file for watching: %s",
                      strerror(errno));
  }
}

- (void)registerKqueueEvents {
  if (self.configFileFD < 0 || self.kqueueFD < 0)
    return;

  struct kevent change;

  // Watch for: write, delete, rename, revoke
  EV_SET(&change, self.configFileFD, EVFILT_VNODE,
         EV_ADD | EV_ENABLE | EV_CLEAR,
         NOTE_WRITE | NOTE_DELETE | NOTE_RENAME | NOTE_REVOKE | NOTE_ATTRIB, 0,
         (__bridge void *)self);

  if (kevent(self.kqueueFD, &change, 1, NULL, 0, NULL) < 0) {
    MACWMFX_LOG_ERROR(macwmfx_log_config,
                      "Failed to register kqueue events: %s", strerror(errno));
  }
}

- (void)startKqueueDispatchSource {
  if (self.kqueueFD < 0)
    return;

  __weak typeof(self) weakSelf = self;

  self.kqueueSource = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_READ, self.kqueueFD, 0,
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

  dispatch_source_set_event_handler(self.kqueueSource, ^{
    [weakSelf handleKqueueEvent];
  });

  dispatch_source_set_cancel_handler(self.kqueueSource, ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf && strongSelf.kqueueFD >= 0) {
      close(strongSelf.kqueueFD);
      strongSelf.kqueueFD = -1;
    }
  });

  dispatch_resume(self.kqueueSource);
}

- (void)handleKqueueEvent {
  struct kevent event;
  struct timespec timeout = {0, 0};

  while (kevent(self.kqueueFD, NULL, 0, &event, 1, &timeout) > 0) {
    if (event.filter == EVFILT_VNODE) {
      MACWMFX_LOG_DEBUG(macwmfx_log_config,
                        "Config file event detected: flags=0x%x",
                        (unsigned int)event.fflags);
      if (event.fflags & (NOTE_DELETE | NOTE_RENAME | NOTE_REVOKE)) {
        // File was deleted/renamed - re-open and re-register on main thread
        MACWMFX_LOG_DEBUG(
            macwmfx_log_config,
            "Config file deleted/renamed, re-registering watcher");
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
              [self reRegisterFileWatcher];
            });
      }

      if (event.fflags & (NOTE_WRITE | NOTE_ATTRIB)) {
        // File was modified - debounce and reload
        [self scheduleConfigReload];
      }
    }
  }
}

- (void)reRegisterFileWatcher {
  // Close old file descriptor
  if (self.configFileFD >= 0) {
    close(self.configFileFD);
    self.configFileFD = -1;
  }

  // Try to re-open the file
  [self openConfigFileForWatching];

  if (self.configFileFD >= 0) {
    [self registerKqueueEvents];
    MACWMFX_LOG_INFO(macwmfx_log_config,
                     "Re-registered file watcher after file recreation");
    // Reload config since file was recreated
    [self scheduleConfigReload];
  } else {
    // File still doesn't exist, try again later on main thread
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          [self reRegisterFileWatcher];
        });
  }
}

- (void)scheduleConfigReload {
  // Cancel any pending reload
  if (self.debounceTimer) {
    dispatch_source_cancel(self.debounceTimer);
    self.debounceTimer = nil;
  }

  // Schedule reload with 100ms debounce to handle rapid file saves
  __weak typeof(self) weakSelf = self;
  self.debounceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                              dispatch_get_main_queue());

  dispatch_source_set_timer(
      self.debounceTimer, dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC),
      DISPATCH_TIME_FOREVER, 10 * NSEC_PER_MSEC);

  dispatch_source_set_event_handler(self.debounceTimer, ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf reloadConfig];
      if (strongSelf.debounceTimer) {
        dispatch_source_cancel(strongSelf.debounceTimer);
        strongSelf.debounceTimer = nil;
      }
    }
  });

  dispatch_resume(self.debounceTimer);
}

- (void)watchConfigDirectory {
  // Watch the parent directory for file creation
  NSString *configDir = [self.configPath stringByDeletingLastPathComponent];

  // Create directory if it doesn't exist
  [[NSFileManager defaultManager] createDirectoryAtPath:configDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];

  const char *dirPath = [configDir fileSystemRepresentation];
  int dirFD = open(dirPath, O_RDONLY | O_EVTONLY);

  if (dirFD < 0) {
    MACWMFX_LOG_ERROR(macwmfx_log_config,
                      "Could not open config directory for watching: %s",
                      strerror(errno));
    return;
  }

  __weak typeof(self) weakSelf = self;
  dispatch_source_t dirSource = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_VNODE, dirFD, DISPATCH_VNODE_WRITE,
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

  dispatch_source_set_event_handler(dirSource, ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf) {
      // Check if config file now exists
      if ([[NSFileManager defaultManager]
              fileExistsAtPath:strongSelf.configPath]) {
        MACWMFX_LOG_INFO(macwmfx_log_config,
                         "Config file created, switching to file watcher");
        dispatch_source_cancel(dirSource);
        close(dirFD);
        [strongSelf openConfigFileForWatching];
        [strongSelf registerKqueueEvents];
        [strongSelf scheduleConfigReload];
      }
    }
  });

  dispatch_source_set_cancel_handler(dirSource, ^{
    close(dirFD);
  });

  dispatch_resume(dirSource);
  MACWMFX_LOG_INFO(macwmfx_log_config,
                   "Watching config directory for file creation: %@",
                   configDir);
}

- (void)stopKqueueWatcher {
  if (self.debounceTimer) {
    dispatch_source_cancel(self.debounceTimer);
    self.debounceTimer = nil;
  }

  if (self.kqueueSource) {
    dispatch_source_cancel(self.kqueueSource);
    self.kqueueSource = nil;
  }

  if (self.configFileFD >= 0) {
    close(self.configFileFD);
    self.configFileFD = -1;
  }

  // kqueueFD is closed by the dispatch source cancel handler
  MACWMFX_LOG_DEBUG(macwmfx_log_config, "Kqueue file watcher stopped");
}

@end

#pragma mark - Rule Engine

@implementation macwmfxRuleEngine

+ (NSDictionary *)resolveAppearanceForWindow:(NSWindow *)window {
  ConfigParser *cp = [ConfigParser sharedInstance];
  NSDictionary *config = cp.rawConfig;
  if (!config)
    return @{};

  // 1. Start with global appearance
  NSMutableDictionary *resolved =
      [NSMutableDictionary dictionaryWithDictionary:config[@"global"] ?: @{}];

  // 2. Resolve matching rules
  NSArray *rules = config[@"rules"];
  if (rules && [rules isKindOfClass:[NSArray class]]) {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *windowClass = NSStringFromClass([window class]);
    NSString *windowTitle = window.title;
    BOOL isActive = window.isKeyWindow;

    for (NSDictionary *rule in rules) {
      NSDictionary *match = rule[@"match"];
      NSDictionary *override = rule[@"override"];
      if (!match || !override)
        continue;

      BOOL matches = YES;

      if (match[@"bundleIdentifier"] &&
          ![match[@"bundleIdentifier"] isEqualToString:bundleID]) {
        matches = NO;
      }
      if (matches && match[@"windowClass"] &&
          ![match[@"windowClass"] isEqualToString:windowClass]) {
        matches = NO;
      }
      if (matches && match[@"title"] &&
          ![windowTitle containsString:match[@"title"]]) {
        matches = NO;
      }
      if (matches && match[@"state"]) {
        NSString *state = match[@"state"];
        if ([state isEqualToString:@"active"] && !isActive)
          matches = NO;
        if ([state isEqualToString:@"inactive"] && isActive)
          matches = NO;
      }

      if (matches) {
        [self mergeDictionary:override into:resolved];
      }
    }
  }

  return resolved;
}

+ (void)mergeDictionary:(NSDictionary *)source
                   into:(NSMutableDictionary *)target {
  [source
      enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *__unused stop) {
        if ([obj isKindOfClass:[NSDictionary class]] &&
            [target[key] isKindOfClass:[NSDictionary class]]) {
          NSMutableDictionary *subTarget = [target[key] mutableCopy];
          [self mergeDictionary:obj into:subTarget];
          target[key] = subTarget;
        } else {
          target[key] = obj;
        }
      }];
}

@end
