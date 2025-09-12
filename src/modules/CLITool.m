//
//  CLITool.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "macwmfx_globals.h"
#import "configParser.h"
#import "../shared/macwmfx_logging.h"
#import "../client/macwmfx_client.h"
#import "../server/macwmfx_server.h"
#import "../main/module_loader.h"

// Color definitions for terminal output
#define COLOR_RESET   "\033[0m"
#define COLOR_BOLD    "\033[1m"
#define COLOR_RED     "\033[31m"
#define COLOR_GREEN   "\033[32m"
#define COLOR_YELLOW  "\033[33m"
#define COLOR_BLUE    "\033[34m"
#define COLOR_MAGENTA "\033[35m"
#define COLOR_CYAN    "\033[36m"
#define COLOR_WHITE   "\033[37m"

// Color functions
void printColor(const char *color, const char *format, ...) {
    va_list args;
    va_start(args, format);
    printf("%s", color);
    vprintf(format, args);
    printf("%s", COLOR_RESET);
    va_end(args);
}

void printSuccess(const char *format, ...) {
    va_list args;
    va_start(args, format);
    printf("%s✓%s ", COLOR_GREEN, COLOR_RESET);
    vprintf(format, args);
    printf("\n");
    va_end(args);
}

void printError(const char *format, ...) {
    va_list args;
    va_start(args, format);
    printf("%s✗%s ", COLOR_RED, COLOR_RESET);
    vprintf(format, args);
    printf("\n");
    va_end(args);
}

void printWarning(const char *format, ...) {
    va_list args;
    va_start(args, format);
    printf("%s⚠%s ", COLOR_YELLOW, COLOR_RESET);
    vprintf(format, args);
    printf("\n");
    va_end(args);
}

void printInfo(const char *format, ...) {
    va_list args;
    va_start(args, format);
    printf("%sℹ%s ", COLOR_BLUE, COLOR_RESET);
    vprintf(format, args);
    printf("\n");
    va_end(args);
}

void printHeader(const char *title) {
    printf("\n%s%s%s\n", COLOR_CYAN, COLOR_BOLD, title);
    printf("%s", COLOR_RESET);
    for (size_t i = 0; i < strlen(title); i++) {
        printf("=");
    }
    printf("\n\n");
}

void printSection(const char *title) {
    printf("\n%s%s%s\n", COLOR_YELLOW, COLOR_BOLD, title);
    printf("%s", COLOR_RESET);
}

// Function to execute command with sudo if needed
BOOL executeWithSudoIfNeeded(NSString *command, NSString *description) {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", command];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];

        if (task.terminationStatus == 0) {
            printSuccess("%s", [description UTF8String]);
            return YES;
        } else {
            // If the command failed, try with sudo
            NSString *sudoCommand = [NSString stringWithFormat:@"sudo %@", command];
            printWarning("Attempting with elevated privileges...");

            NSTask *sudoTask = [[NSTask alloc] init];
            sudoTask.launchPath = @"/bin/bash";
            sudoTask.arguments = @[@"-c", sudoCommand];

            NSPipe *sudoPipe = [NSPipe pipe];
            sudoTask.standardOutput = sudoPipe;
            sudoTask.standardError = sudoPipe;

            [sudoTask launch];
            [sudoTask waitUntilExit];

            if (sudoTask.terminationStatus == 0) {
                printSuccess("%s (with elevated privileges)", [description UTF8String]);
                return YES;
            } else {
                printError("Failed to %s even with elevated privileges", [description UTF8String]);
                return NO;
            }
        }
    } @catch (NSException *exception) {
        printError("Error executing command: %s", [exception.reason UTF8String]);
        return NO;
    }
}

// Function to update all windows
void updateAllWindows(void) {
    // Get all running applications
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];

    // Iterate through each application
    for (NSRunningApplication *app in apps) {
        if (app.activationPolicy == NSApplicationActivationPolicyRegular) {
            pid_t pid = app.processIdentifier;
            // Use CGWindowListCopyWindowInfo to get windows for this app
            CFArrayRef windowList = CGWindowListCopyWindowInfo(
                kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
                kCGNullWindowID);

            if (windowList) {
                NSArray *windows = CFBridgingRelease(windowList);
                for (NSDictionary *windowInfo in windows) {
                    NSNumber *windowPid = windowInfo[(id)kCGWindowOwnerPID];
                    if (windowPid.intValue == pid) {
                        // Post a notification to update this window
                        [[NSDistributedNotificationCenter defaultCenter]
                            postNotificationName:@"com.aspauldingcode.macwmfx.updateWindow"
                                        object:[windowInfo[(id)kCGWindowNumber] stringValue]
                                      userInfo:nil
                            deliverImmediately:YES];
                    }
                }
            }
        }
    }
}

void observeLogs() {
    NSString *command = @"log stream --predicate 'process == \"macwmfx\"'";
    FILE *pipe = popen([command UTF8String], "r");
    if (!pipe) {
        MACWMFX_LOG_ERROR(macwmfx_log_cli, "Error: Could not open pipe for log stream");
        return;
    }

    char buffer[1024];
    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        printf("%s", buffer);
        fflush(stdout);
    }
    pclose(pipe);
}

NSString* generateDefaultConfig() {
    return @"{\n\
  \"debug\": {\n\
    \"enabled\": true,\n\
    \"verbose_logging\": true\n\
  },\n\
  \"hotload\": {\n\
    \"enabled\": true,\n\
    \"interval\": 5\n\
  },\n\
  \"windows\": {\n\
    \"outline\": {\n\
      \"enabled\": true,\n\
      \"type\": \"inline\",\n\
      \"width\": 2.0,\n\
      \"corner_radius\": 8.0,\n\
      \"custom_color\": {\n\
        \"enabled\": false,\n\
        \"active\": \"#007AFF\",\n\
        \"inactive\": \"#8E8E93\",\n\
        \"stacked\": \"#FF3B30\"\n\
      }\n\
    },\n\
    \"shadow\": {\n\
      \"enabled\": true,\n\
      \"custom_color\": {\n\
        \"enabled\": false\n\
      }\n\
    },\n\
    \"transparency\": {\n\
      \"enabled\": false,\n\
      \"value\": 0.95\n\
    },\n\
    \"blur\": {\n\
      \"enabled\": true,\n\
      \"passes\": 1,\n\
      \"radius\": 10.0\n\
    },\n\
    \"titlebar\": {\n\
      \"enabled\": true,\n\
      \"force_classic\": false,\n\
      \"aesthetics\": {\n\
        \"enabled\": true,\n\
        \"active_color\": \"#FFFFFF\",\n\
        \"inactive_color\": \"#F5F5F7\"\n\
      },\n\
      \"custom_color\": {\n\
        \"enabled\": false,\n\
        \"active_background\": \"#FFFFFF\",\n\
        \"active_foreground\": \"#000000\",\n\
        \"inactive_background\": \"#F5F5F7\",\n\
        \"inactive_foreground\": \"#8E8E93\"\n\
      }\n\
    },\n\
    \"traffic_lights\": {\n\
      \"enabled\": true,\n\
      \"style\": \"default\",\n\
      \"shape\": \"circle\",\n\
      \"order\": \"close_minimize_zoom\",\n\
      \"position\": \"top_left\",\n\
      \"size\": 12.0,\n\
      \"padding\": 8.0,\n\
      \"custom_color\": {\n\
        \"enabled\": false,\n\
        \"active\": {\n\
          \"stop\": \"#FF3B30\",\n\
          \"yield\": \"#FF9500\",\n\
          \"go\": \"#34C759\"\n\
        },\n\
        \"inactive\": {\n\
          \"stop\": \"#FF6B6B\",\n\
          \"yield\": \"#FFB84D\",\n\
          \"go\": \"#6BCF7F\"\n\
        },\n\
        \"hover\": {\n\
          \"stop\": \"#FF1744\",\n\
          \"yield\": \"#FF8F00\",\n\
          \"go\": \"#00E676\"\n\
        }\n\
      }\n\
    },\n\
    \"custom_title\": {\n\
      \"enabled\": false,\n\
      \"title\": \"macwmfx\"\n\
    },\n\
    \"size_constraints\": {\n\
      \"enabled\": false\n\
    }\n\
  },\n\
  \"menubar\": {\n\
    \"no_menubar\": {\n\
      \"enabled\": false\n\
    },\n\
    \"ribbonbar\": {\n\
      \"enabled\": false\n\
    }\n\
  },\n\
  \"dock\": {\n\
    \"disable_dock\": {\n\
      \"enabled\": false\n\
    }\n\
  },\n\
  \"spaces\": {\n\
    \"disable_spaces\": {\n\
      \"enabled\": false\n\
    },\n\
    \"rename_spaces\": {\n\
      \"enabled\": false\n\
    },\n\
    \"instant_fullscreen_transition\": {\n\
      \"enabled\": false\n\
    }\n\
  },\n\
  \"system_colors\": {\n\
    \"variant\": \"default\",\n\
    \"slug\": \"macos\"\n\
  }\n\
}";
}

void generateConfig() {
    printHeader("macwmfx Configuration Setup");

    NSString *configContent = generateDefaultConfig();

    NSString *userConfigDir = [NSString stringWithFormat:@"%@/.config/macwmfx", NSHomeDirectory()];
    NSString *systemConfigDir = @"/Library/Application Support/macwmfx";
    NSString *userConfigPath = [userConfigDir stringByAppendingPathComponent:@"config.json"];
    NSString *systemConfigPath = [systemConfigDir stringByAppendingPathComponent:@"config.json"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    printSection("Creating Configuration Files");

    // Create user config directory
    if (![fileManager createDirectoryAtPath:userConfigDir
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error]) {
        printError("Error creating user config directory: %s", [error.localizedDescription UTF8String]);
        return;
    }

    // Write config to user location
    if (![configContent writeToFile:userConfigPath
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:&error]) {
        printError("Error writing config file: %s", [error.localizedDescription UTF8String]);
        return;
    }

    printSuccess("Configuration created at user location: %s", [userConfigPath UTF8String]);

    // Create system config directory with auto-sudo
    NSString *mkdirCommand = [NSString stringWithFormat:@"mkdir -p \"%@\"", systemConfigDir];
    if (!executeWithSudoIfNeeded(mkdirCommand, @"create system config directory")) {
        printWarning("Could not create system config directory. Configuration will only be available at user location.");
        return;
    }

    // Remove existing system config if it exists
    NSString *rmCommand = [NSString stringWithFormat:@"rm -f \"%@\"", systemConfigPath];
    executeWithSudoIfNeeded(rmCommand, @"remove existing system config");

    // Create symlink from system to user config
    NSString *lnCommand = [NSString stringWithFormat:@"ln -sf \"%@\" \"%@\"", userConfigPath, systemConfigPath];
    if (!executeWithSudoIfNeeded(lnCommand, @"create system config symlink")) {
        printWarning("Could not create system config symlink. Configuration will only be available at user location.");
        return;
    }

    printSection("Configuration Summary");
    printSuccess("Configuration setup complete!");
    printColor(COLOR_CYAN, "  User config: %s\n", [userConfigPath UTF8String]);
    printColor(COLOR_CYAN, "  System config: %s\n", [systemConfigPath UTF8String]);
    printColor(COLOR_CYAN, "  (System config is symlinked to user config)\n");
    printf("\n");
    printInfo("You can now edit the config at: %s", [userConfigPath UTF8String]);
    printInfo("Use 'macwmfx --reload' to restart all open apps and apply changes.");
}

void setupUserConfig() {
    // This function is no longer needed - config generation now handles everything
    printInfo("Use '--generate-config' instead. It now creates the user config and sets up the symlink automatically.");
}

// Function to handle server communication
void handleServerCommand(NSString *command, id data) {
    macwmfxClient *client = [macwmfxClient sharedClient];

    // Connect to server
    [client connectWithCompletion:^(macwmfxServerResponse *response __unused, NSError *error) {
        if (error) {
            printError("Error connecting to macwmfx server: %s", [error.localizedDescription UTF8String]);
            printInfo("The macwmfx server is not running.");
            printInfo("To start the server, you need to:");
            printInfo("  1. Install macwmfx: make install");
            printInfo("  2. Restart applications: macwmfx --reload");
            printInfo("  3. Or manually inject the server dylib into applications");
            printInfo("");
            printInfo("For development, you can also:");
            printInfo("  - Build the server: make server");
            printInfo("  - Load it manually into applications");
            return;
        }

        // Send command based on the command string
        if ([command isEqualToString:@"reload"]) {
            [client reloadWithCompletion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    printSuccess("%s", [response.data[@"message"] UTF8String]);
                }
            }];
        } else if ([command isEqualToString:@"start"]) {
            [client startServerWithCompletion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    printSuccess("%s", [response.data[@"message"] UTF8String]);
                }
            }];
        } else if ([command isEqualToString:@"stop"]) {
            [client stopServerWithCompletion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    printSuccess("%s", [response.data[@"message"] UTF8String]);
                }
            }];
        } else if ([command isEqualToString:@"enable-borders"]) {
            [client enableBordersWithCompletion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    printSuccess("%s", [response.data[@"message"] UTF8String]);
                }
            }];
        } else if ([command isEqualToString:@"disable-borders"]) {
            [client disableBordersWithCompletion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    printSuccess("%s", [response.data[@"message"] UTF8String]);
                }
            }];
        } else if ([command isEqualToString:@"set-border-width"]) {
            [client setBorderWidth:[data floatValue] completion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    printSuccess("%s", [response.data[@"message"] UTF8String]);
                }
            }];
        } else if ([command isEqualToString:@"set-border-radius"]) {
            [client setBorderRadius:[data floatValue] completion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    printSuccess("%s", [response.data[@"message"] UTF8String]);
                }
            }];
        } else if ([command isEqualToString:@"enable-resize"]) {
            [client enableResizeWithCompletion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    printSuccess("%s", [response.data[@"message"] UTF8String]);
                }
            }];
        } else if ([command isEqualToString:@"disable-resize"]) {
            [client disableResizeWithCompletion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    printSuccess("%s", [response.data[@"message"] UTF8String]);
                }
            }];
        } else if ([command isEqualToString:@"status"]) {
            [client getStatusWithCompletion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    NSDictionary *status = response.data;
                    printHeader("macwmfx Server Status");
                    printColor(COLOR_CYAN, "  Running: %s\n", [status[@"running"] boolValue] ? "Yes" : "No");
                    printColor(COLOR_CYAN, "  Client connections: %ld\n", [status[@"clientCount"] integerValue]);

                    NSDictionary *config = status[@"config"];
                    printSection("Configuration");
                    printColor(COLOR_CYAN, "    Borders enabled: %s\n", [config[@"bordersEnabled"] boolValue] ? "Yes" : "No");
                    printColor(COLOR_CYAN, "    Border width: %.1f\n", [config[@"borderWidth"] floatValue]);
                    printColor(COLOR_CYAN, "    Border radius: %.1f\n", [config[@"borderRadius"] floatValue]);
                    printColor(COLOR_CYAN, "    Resize enabled: %s\n", [config[@"resizeEnabled"] boolValue] ? "Yes" : "No");
                }
            }];
        } else if ([command isEqualToString:@"list-modules"]) {
            [client listModulesWithCompletion:^(macwmfxServerResponse *response, NSError *error) {
                if (error) {
                    printError("Error: %s", [error.localizedDescription UTF8String]);
                } else if (response.errorMessage) {
                    printError("Error: %s", [response.errorMessage UTF8String]);
                } else {
                    NSDictionary *data = response.data;
                    printHeader("macwmfx Modules");

                    NSArray *available = data[@"available"];
                    NSArray *loaded = data[@"loaded"];
                    NSDictionary *allInfo = data[@"allInfo"];

                    printSection("Available Modules");
                    if (available.count > 0) {
                        for (NSString *moduleName in available) {
                            BOOL isLoaded = [loaded containsObject:moduleName];
                            printColor(isLoaded ? COLOR_GREEN : COLOR_YELLOW, "  %s %s\n",
                                     [moduleName UTF8String],
                                     isLoaded ? "(loaded)" : "(available)");
                        }
                    } else {
                        printColor(COLOR_YELLOW, "  No modules available (all disabled at compile time)\n");
                    }

                    printSection("Loaded Modules");
                    if (loaded.count > 0) {
                        for (NSString *moduleName in loaded) {
                            NSDictionary *info = allInfo[moduleName];
                            printColor(COLOR_GREEN, "  %s\n", [moduleName UTF8String]);
                            if (info) {
                                printColor(COLOR_CYAN, "    Class: %s\n", [info[@"class"] UTF8String]);
                                printColor(COLOR_CYAN, "    Enabled: %s\n", [info[@"enabled"] boolValue] ? "Yes" : "No");
                                NSArray *deps = info[@"dependencies"];
                                if (deps.count > 0) {
                                    printColor(COLOR_CYAN, "    Dependencies: %s\n", [[deps componentsJoinedByString:@", "] UTF8String]);
                                }
                            }
                        }
                    } else {
                        printColor(COLOR_YELLOW, "  No modules currently loaded\n");
                    }
                }
            }];
        } else if ([command isEqualToString:@"enable-module"]) {
            if ([data isKindOfClass:[NSString class]]) {
                [client enableModule:data completion:^(macwmfxServerResponse *response, NSError *error) {
                    if (error) {
                        printError("Error: %s", [error.localizedDescription UTF8String]);
                    } else if (response.errorMessage) {
                        printError("Error: %s", [response.errorMessage UTF8String]);
                    } else {
                        printSuccess("%s", [response.data[@"message"] UTF8String]);
                    }
                }];
            } else {
                printError("enable-module requires a module name");
            }
        } else if ([command isEqualToString:@"disable-module"]) {
            if ([data isKindOfClass:[NSString class]]) {
                [client disableModule:data completion:^(macwmfxServerResponse *response, NSError *error) {
                    if (error) {
                        printError("Error: %s", [error.localizedDescription UTF8String]);
                    } else if (response.errorMessage) {
                        printError("Error: %s", [response.errorMessage UTF8String]);
                    } else {
                        printSuccess("%s", [response.data[@"message"] UTF8String]);
                    }
                }];
            } else {
                printError("disable-module requires a module name");
            }
        } else if ([command isEqualToString:@"module-info"]) {
            if ([data isKindOfClass:[NSString class]]) {
                [client getModuleInfo:data completion:^(macwmfxServerResponse *response, NSError *error) {
                    if (error) {
                        printError("Error: %s", [error.localizedDescription UTF8String]);
                    } else if (response.errorMessage) {
                        printError("Error: %s", [response.errorMessage UTF8String]);
                    } else {
                        NSDictionary *info = response.data;
                        printHeader("Module Information");
                        printColor(COLOR_CYAN, "  Name: %s\n", [info[@"name"] UTF8String]);
                        printColor(COLOR_CYAN, "  Class: %s\n", [info[@"class"] UTF8String]);
                        printColor(COLOR_CYAN, "  Loaded: %s\n", [info[@"loaded"] boolValue] ? "Yes" : "No");
                        printColor(COLOR_CYAN, "  Enabled: %s\n", [info[@"enabled"] boolValue] ? "Yes" : "No");

                        NSArray *deps = info[@"dependencies"];
                        if (deps.count > 0) {
                            printColor(COLOR_CYAN, "  Dependencies: %s\n", [[deps componentsJoinedByString:@", "] UTF8String]);
                        } else {
                            printColor(COLOR_CYAN, "  Dependencies: None\n");
                        }
                    }
                }];
            } else {
                printError("module-info requires a module name");
            }
        }
    }];
}

// Shell completion function
void generateShellCompletion(NSString *shell) {
    if ([shell isEqualToString:@"bash"]) {
        printf("# macwmfx bash completion\n");
        printf("_macwmfx_completion() {\n");
        printf("    local cur prev opts\n");
        printf("    COMPREPLY=()\n");
        printf("    cur=\"${COMP_WORDS[COMP_CWORD]}\"\n");
        printf("    prev=\"${COMP_WORDS[COMP_CWORD-1]}\"\n");
        printf("    \n");
        printf("    opts=\"--help --generate-config --observe-logs --reload --start --stop --status enable-borders disable-borders set-border-width set-border-radius enable-resize disable-resize list-modules enable-module disable-module module-info\"\n");
        printf("    \n");
        printf("    case \"${prev}\" in\n");
        printf("        set-border-width|set-border-radius)\n");
        printf("            COMPREPLY=( $(compgen -W \"1 2 3 4 5 6 7 8 9 10\" -- \"${cur}\") )\n");
        printf("            return 0\n");
        printf("            ;;\n");
        printf("        enable-module|disable-module|module-info)\n");
        printf("            # This would ideally fetch from the server, but for now we'll provide common module names\n");
        printf("            COMPREPLY=( $(compgen -W \"WindowOutline WindowShadow WindowTransparency WindowBlur TitlebarAesthetics TrafficLights CustomTitle SizeConstraints NoMenubar Ribbonbar DisableDock DisableSpaces RenameSpaces InstantFullscreenTransition\" -- \"${cur}\") )\n");
        printf("            return 0\n");
        printf("            ;;\n");
        printf("    esac\n");
        printf("    \n");
        printf("    if [[ ${cur} == * ]] ; then\n");
        printf("        COMPREPLY=( $(compgen -W \"${opts}\" -- \"${cur}\") )\n");
        printf("    else\n");
        printf("        COMPREPLY=( $(compgen -W \"${opts}\" -- \"${cur}\") )\n");
        printf("    fi\n");
        printf("}\n");
        printf("complete -F _macwmfx_completion macwmfx\n");
        printf("\n");
        printf("# To install, add this to your ~/.bashrc:\n");
        printf("# source <(macwmfx --completion bash)\n");
    } else if ([shell isEqualToString:@"zsh"]) {
        printf("# macwmfx zsh completion\n");
        printf("_macwmfx() {\n");
        printf("    local curcontext=\"$curcontext\" state line\n");
        printf("    typeset -A opt_args\n");
        printf("    \n");
        printf("    _arguments -C \\\n");
        printf("        '1: :->cmds' \\\n");
        printf("        '*:: :->args'\n");
        printf("    \n");
        printf("    case \"$state\" in\n");
        printf("        cmds)\n");
        printf("            _values 'macwmfx commands' \\\n");
        printf("                '--help[Show help]' \\\n");
        printf("                '--generate-config[Create default configuration]' \\\n");
        printf("                '--observe-logs[Observe macwmfx logs]' \\\n");
        printf("                '--reload[Restart all open apps]' \\\n");
        printf("                '--start[Start the macwmfx server]' \\\n");
        printf("                '--stop[Stop the macwmfx server]' \\\n");
        printf("                '--status[Show server status]' \\\n");
        printf("                'enable-borders[Enable window borders]' \\\n");
        printf("                'disable-borders[Disable window borders]' \\\n");
        printf("                'set-border-width[Set border width]' \\\n");
        printf("                'set-border-radius[Set border radius]' \\\n");
        printf("                'enable-resize[Enable free window resizing]' \\\n");
        printf("                'disable-resize[Disable free window resizing]' \\\n");
        printf("                'list-modules[List available and loaded modules]' \\\n");
        printf("                'enable-module[Enable a specific module]' \\\n");
        printf("                'disable-module[Disable a specific module]' \\\n");
        printf("                'module-info[Show detailed module information]'\n");
        printf("            ;;\n");
        printf("        args)\n");
        printf("            case \"$line[1]\" in\n");
        printf("                set-border-width|set-border-radius)\n");
        printf("                    _values 'values' '1' '2' '3' '4' '5' '6' '7' '8' '9' '10'\n");
        printf("                    ;;\n");
        printf("                enable-module|disable-module|module-info)\n");
        printf("                    _values 'modules' 'WindowOutline' 'WindowShadow' 'WindowTransparency' 'WindowBlur' 'TitlebarAesthetics' 'TrafficLights' 'CustomTitle' 'SizeConstraints' 'NoMenubar' 'Ribbonbar' 'DisableDock' 'DisableSpaces' 'RenameSpaces' 'InstantFullscreenTransition'\n");
        printf("                    ;;\n");
        printf("            esac\n");
        printf("            ;;\n");
        printf("    esac\n");
        printf("}\n");
        printf("\n");
        printf("compdef _macwmfx macwmfx\n");
        printf("\n");
        printf("# To install, add this to your ~/.zshrc:\n");
        printf("# autoload -U compinit && compinit\n");
        printf("# source <(macwmfx --completion zsh)\n");
    } else if ([shell isEqualToString:@"fish"]) {
        printf("# macwmfx fish completion\n");
        printf("complete -c macwmfx -s h -l help -d 'Show help'\n");
        printf("complete -c macwmfx -l generate-config -d 'Create default configuration'\n");
        printf("complete -c macwmfx -l observe-logs -d 'Observe macwmfx logs'\n");
        printf("complete -c macwmfx -l reload -d 'Restart all open apps'\n");
        printf("complete -c macwmfx -l start -d 'Start the macwmfx server'\n");
        printf("complete -c macwmfx -l stop -d 'Stop the macwmfx server'\n");
        printf("complete -c macwmfx -l status -d 'Show server status'\n");
        printf("complete -c macwmfx -a 'enable-borders' -d 'Enable window borders'\n");
        printf("complete -c macwmfx -a 'disable-borders' -d 'Disable window borders'\n");
        printf("complete -c macwmfx -a 'set-border-width' -d 'Set border width'\n");
        printf("complete -c macwmfx -a 'set-border-radius' -d 'Set border radius'\n");
        printf("complete -c macwmfx -a 'enable-resize' -d 'Enable free window resizing'\n");
        printf("complete -c macwmfx -a 'disable-resize' -d 'Disable free window resizing'\n");
        printf("complete -c macwmfx -a 'list-modules' -d 'List available and loaded modules'\n");
        printf("complete -c macwmfx -a 'enable-module' -d 'Enable a specific module'\n");
        printf("complete -c macwmfx -a 'disable-module' -d 'Disable a specific module'\n");
        printf("complete -c macwmfx -a 'module-info' -d 'Show detailed module information'\n");
        printf("\n");
        printf("# To install, save this to ~/.config/fish/completions/macwmfx.fish\n");
    } else {
        printError("Unsupported shell: %s", [shell UTF8String]);
        printInfo("Supported shells: bash, zsh, fish");
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Initialize logging system
        macwmfx_logging_init();

        // Check for help flags first
        if (argc >= 2) {
            NSString *arg = [NSString stringWithUTF8String:argv[1]];
            if ([arg isEqualToString:@"--help"] || [arg isEqualToString:@"-h"]) {
                printHeader("macwmfx CLI Tool");
                printColor(COLOR_CYAN, "Usage: %s <command> [options]\n\n", argv[0]);
                printSection("Commands");
                printColor(COLOR_CYAN, "  --help, -h            Show this help message\n");
                printColor(COLOR_CYAN, "  --generate-config     Create default configuration\n");
                printColor(COLOR_CYAN, "  --completion <shell>  Generate shell completion (bash, zsh, fish)\n");
                printColor(COLOR_CYAN, "  --observe-logs        Observe macwmfx logs\n");
                printColor(COLOR_CYAN, "  --reload              Restart all open apps (kills them)\n");
                printColor(COLOR_CYAN, "  --start               Start the macwmfx server\n");
                printColor(COLOR_CYAN, "  --stop                Stop the macwmfx server\n");
                printColor(COLOR_CYAN, "  --status              Show server status\n");
                printColor(COLOR_CYAN, "  enable-borders        Enable window borders\n");
                printColor(COLOR_CYAN, "  disable-borders       Disable window borders\n");
                printColor(COLOR_CYAN, "  set-border-width <n>  Set border width\n");
                printColor(COLOR_CYAN, "  set-border-radius <n> Set border radius\n");
                printColor(COLOR_CYAN, "  enable-resize         Enable free window resizing\n");
                printColor(COLOR_CYAN, "  disable-resize        Disable free window resizing\n");
                printColor(COLOR_CYAN, "  list-modules          List available and loaded modules\n");
                printColor(COLOR_CYAN, "  enable-module <name>  Enable a specific module\n");
                printColor(COLOR_CYAN, "  disable-module <name> Disable a specific module\n");
                printColor(COLOR_CYAN, "  module-info <name>    Show detailed module information\n\n");
                printSection("Examples");
                printColor(COLOR_CYAN, "  %s --generate-config\n", argv[0]);
                printColor(COLOR_CYAN, "  %s --reload\n", argv[0]);
                printColor(COLOR_CYAN, "  %s enable-borders\n", argv[0]);
                return 0;
            }
        }

        // Check if we have at least one argument
        if (argc < 2) {
            printHeader("macwmfx CLI Tool");
            printColor(COLOR_CYAN, "Usage: %s <command> [options]\n\n", argv[0]);
            printSection("Commands");
            printColor(COLOR_CYAN, "  --help, -h            Show this help message\n");
            printColor(COLOR_CYAN, "  --generate-config     Create default configuration\n");
            printColor(COLOR_CYAN, "  --completion <shell>  Generate shell completion (bash, zsh, fish)\n");
            printColor(COLOR_CYAN, "  --observe-logs        Observe macwmfx logs\n");
            printColor(COLOR_CYAN, "  --reload              Restart all open apps (kills them)\n");
            printColor(COLOR_CYAN, "  --start               Start the macwmfx server\n");
            printColor(COLOR_CYAN, "  --stop                Stop the macwmfx server\n");
            printColor(COLOR_CYAN, "  --status              Show server status\n");
            printColor(COLOR_CYAN, "  enable-borders        Enable window borders\n");
            printColor(COLOR_CYAN, "  disable-borders       Disable window borders\n");
            printColor(COLOR_CYAN, "  set-border-width <n>  Set border width\n");
            printColor(COLOR_CYAN, "  set-border-radius <n> Set border radius\n");
            printColor(COLOR_CYAN, "  enable-resize         Enable free window resizing\n");
            printColor(COLOR_CYAN, "  disable-resize        Disable free window resizing\n");
            printColor(COLOR_CYAN, "  list-modules          List available and loaded modules\n");
            printColor(COLOR_CYAN, "  enable-module <name>  Enable a specific module\n");
            printColor(COLOR_CYAN, "  disable-module <name> Disable a specific module\n");
            printColor(COLOR_CYAN, "  module-info <name>    Show detailed module information\n\n");
            printSection("Examples");
            printColor(COLOR_CYAN, "  %s --generate-config\n", argv[0]);
            printColor(COLOR_CYAN, "  %s --reload\n", argv[0]);
            printColor(COLOR_CYAN, "  %s enable-borders\n", argv[0]);
            return 1;
        }

        NSString *arg = [NSString stringWithUTF8String:argv[1]];

        if ([arg isEqualToString:@"--generate-config"]) {
            generateConfig();
            return 0;
        }

        if ([arg isEqualToString:@"--completion"]) {
            if (argc < 3) {
                printError("--completion requires a shell type (bash, zsh, fish)");
                return 1;
            }
            NSString *shell = [NSString stringWithUTF8String:argv[2]];
            generateShellCompletion(shell);
            return 0;
        }

        if ([arg isEqualToString:@"--observe-logs"]) {
            printInfo("Observing macwmfx logs...");
            observeLogs();
            return 0;
        }

        if ([arg isEqualToString:@"--reload"]) {
            printHeader("Application Reload");
            printWarning("This will kill all open apps and restart them.");

            // Get all running applications
            NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
            NSMutableArray *appsToRestart = [NSMutableArray array];

            // Collect apps to restart (exclude system apps and macwmfx itself)
            for (NSRunningApplication *app in apps) {
                if (app.activationPolicy == NSApplicationActivationPolicyRegular &&
                    ![app.bundleIdentifier hasPrefix:@"com.apple."] &&
                    ![app.bundleIdentifier isEqualToString:@"com.aspauldingcode.macwmfx"]) {
                    [appsToRestart addObject:@{
                        @"bundleIdentifier": app.bundleIdentifier ?: @"",
                        @"bundleURL": app.bundleURL.path ?: @""
                    }];
                }
            }

            printInfo("Found %lu applications to restart...", (unsigned long)appsToRestart.count);

            // Kill the applications
            for (NSRunningApplication *app in apps) {
                if (app.activationPolicy == NSApplicationActivationPolicyRegular &&
                    ![app.bundleIdentifier hasPrefix:@"com.apple."] &&
                    ![app.bundleIdentifier isEqualToString:@"com.aspauldingcode.macwmfx"]) {
                    printColor(COLOR_YELLOW, "Terminating %s...\n", [app.localizedName UTF8String]);
                    [app terminate];
                }
            }

            // Wait a bit for apps to terminate
            sleep(2);

            // Force kill any remaining apps
            for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
                if (app.activationPolicy == NSApplicationActivationPolicyRegular &&
                    ![app.bundleIdentifier hasPrefix:@"com.apple."] &&
                    ![app.bundleIdentifier isEqualToString:@"com.aspauldingcode.macwmfx"]) {
                    printColor(COLOR_RED, "Force killing %s...\n", [app.localizedName UTF8String]);
                    [app forceTerminate];
                }
            }

            // Wait a bit more
            sleep(1);

            // Restart the applications
            printSection("Restarting Applications");
            for (NSDictionary *appInfo in appsToRestart) {
                NSString *bundlePath = appInfo[@"bundleURL"];
                if (bundlePath.length > 0) {
                    printColor(COLOR_GREEN, "Starting %s...\n", [bundlePath.lastPathComponent UTF8String]);
                    [[NSWorkspace sharedWorkspace] launchApplication:bundlePath];
                }
            }

            printSuccess("Application reload complete!");
            return 0;
        }

        if ([arg isEqualToString:@"--start"]) {
            printInfo("Starting macwmfx server...");
            handleServerCommand(@"start", nil);
            return 0;
        }

        if ([arg isEqualToString:@"--stop"]) {
            printInfo("Stopping macwmfx server...");
            handleServerCommand(@"stop", nil);
            return 0;
        }

        if ([arg isEqualToString:@"--status"]) {
            handleServerCommand(@"status", nil);
            return 0;
        }

        // Initialize config parser for runtime commands
        [[ConfigParser sharedInstance] loadConfig];

        // Handle server-based commands
        if ([arg isEqualToString:@"enable-borders"]) {
            handleServerCommand(@"enable-borders", nil);
        }
        else if ([arg isEqualToString:@"disable-borders"]) {
            handleServerCommand(@"disable-borders", nil);
        }
        else if ([arg isEqualToString:@"set-border-width"]) {
            if (argc < 3) {
                printError("set-border-width requires a value");
                return 1;
            }
            float width = atof(argv[2]);
            handleServerCommand(@"set-border-width", @(width));
        }
        else if ([arg isEqualToString:@"set-border-radius"]) {
            if (argc < 3) {
                printError("set-border-radius requires a value");
                return 1;
            }
            float radius = atof(argv[2]);
            handleServerCommand(@"set-border-radius", @(radius));
        }
        else if ([arg isEqualToString:@"enable-resize"]) {
            handleServerCommand(@"enable-resize", nil);
        }
        else if ([arg isEqualToString:@"disable-resize"]) {
            handleServerCommand(@"disable-resize", nil);
        }
        else if ([arg isEqualToString:@"list-modules"]) {
            handleServerCommand(@"list-modules", nil);
        }
        else if ([arg isEqualToString:@"enable-module"]) {
            if (argc < 3) {
                printError("enable-module requires a module name");
                return 1;
            }
            NSString *moduleName = [NSString stringWithUTF8String:argv[2]];
            handleServerCommand(@"enable-module", moduleName);
        }
        else if ([arg isEqualToString:@"disable-module"]) {
            if (argc < 3) {
                printError("disable-module requires a module name");
                return 1;
            }
            NSString *moduleName = [NSString stringWithUTF8String:argv[2]];
            handleServerCommand(@"disable-module", moduleName);
        }
        else if ([arg isEqualToString:@"module-info"]) {
            if (argc < 3) {
                printError("module-info requires a module name");
                return 1;
            }
            NSString *moduleName = [NSString stringWithUTF8String:argv[2]];
            handleServerCommand(@"module-info", moduleName);
        }
        else {
            printError("Unknown command: %s", argv[1]);
            printInfo("Run '%s' without arguments to see available commands.", argv[0]);
            return 1;
        }

        // Give the server time to process the command
        usleep(500000);  // 500ms
    }
    return 0;
}
