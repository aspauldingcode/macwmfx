//
//  CLITool.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import "../client/macwmfx_client.h"
#import "../server/macwmfx_server.h"
#import "../shared/headers/macwmfx_Common.h"
#import "../shared/macwmfx_logging.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

// Color definitions for terminal output
#define COLOR_RESET "\033[0m"
#define COLOR_BOLD "\033[1m"
#define COLOR_RED "\033[31m"
#define COLOR_GREEN "\033[32m"
#define COLOR_YELLOW "\033[33m"
#define COLOR_BLUE "\033[34m"
#define COLOR_CYAN "\033[36m"

// Global flag to keep the run loop running for async XPC
BOOL gKeepRunning = YES;

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

void printHeader(const char *title) {
  printf("\n%s%s%s\n", COLOR_CYAN, COLOR_BOLD, title);
  for (size_t i = 0; i < strlen(title); i++)
    printf("=");
  printf("\n\n");
}

NSString *generateDefaultConfig() {
  // Feature-complete config showcasing every customization option
  return @"{\n"
         @"  \"theme\": \"macwmfx Default\",\n"
         @"\n"
         @"  \"global\": {\n"
         @"    \"geometry\": {\n"
         @"      \"cornerRadius\": 12.0,\n"
         @"      \"asymmetricRadius\": {\n"
         @"        \"topLeft\": 12.0,\n"
         @"        \"topRight\": 12.0,\n"
         @"        \"bottomLeft\": 12.0,\n"
         @"        \"bottomRight\": 12.0\n"
         @"      },\n"
         @"      \"margins\": {\n"
         @"        \"top\": 0,\n"
         @"        \"bottom\": 0,\n"
         @"        \"left\": 0,\n"
         @"        \"right\": 0\n"
         @"      },\n"
         @"      \"contentPadding\": 8.0\n"
         @"    },\n"
         @"\n"
         @"    \"materials\": {\n"
         @"      \"vibrancy\": \"ultra-thin\",\n"
         @"      \"blurRadius\": 20.0,\n"
         @"      \"opacity\": 0.95,\n"
         @"      \"tint\": \"#00000000\",\n"
         @"      \"saturation\": 1.0,\n"
         @"      \"noise\": 0.0\n"
         @"    },\n"
         @"\n"
         @"    \"decoration\": {\n"
         @"      \"border\": {\n"
         @"        \"enabled\": false,\n"
         @"        \"thickness\": 1.0,\n"
         @"        \"material\": \"solid\",\n"
         @"        \"gradient\": [\n"
         @"          { \"color\": \"#FFFFFF40\", \"offset\": 0.0 },\n"
         @"          { \"color\": \"#FFFFFF10\", \"offset\": 1.0 }\n"
         @"        ],\n"
         @"        \"glow\": {\n"
         @"          \"radius\": 0.0,\n"
         @"          \"color\": \"#FFFFFF00\",\n"
         @"          \"animated\": false\n"
         @"        }\n"
         @"      },\n"
         @"      \"shadow\": {\n"
         @"        \"enabled\": true,\n"
         @"        \"radius\": 20.0,\n"
         @"        \"noise\": 0.0,\n"
         @"        \"stacks\": [\n"
         @"          { \"radius\": 5.0, \"offset\": [0, 2], \"opacity\": 0.3 "
         @"},\n"
         @"          { \"radius\": 15.0, \"offset\": [0, 5], \"opacity\": 0.2 "
         @"}\n"
         @"        ]\n"
         @"      }\n"
         @"    },\n"
         @"\n"
         @"    \"chrome\": {\n"
         @"      \"titlebar\": {\n"
         @"        \"style\": \"unified\",\n"
         @"        \"height\": 38.0,\n"
         @"        \"transparent\": false,\n"
         @"        \"floating\": false,\n"
         @"        \"detached\": false\n"
         @"      },\n"
         @"      \"trafficLights\": {\n"
         @"        \"position\": [12, 12],\n"
         @"        \"scale\": 1.0,\n"
         @"        \"spacing\": 8.0,\n"
         @"        \"customGlyphs\": false\n"
         @"      }\n"
         @"    },\n"
         @"\n"
         @"    \"motion\": {\n"
         @"      \"dragEffect\": {\n"
         @"        \"effect\": \"none\",\n"
         @"        \"springStiffness\": 7.0,\n"
         @"        \"friction\": 1.5,\n"
         @"        \"mass\": 15.0,\n"
         @"        \"scaleFactor\": 0.95,\n"
         @"        \"tiltAngle\": 5.0,\n"
         @"        \"gridWidth\": 8,\n"
         @"        \"gridHeight\": 6,\n"
         @"        \"enabled\": false\n"
         @"      },\n"
         @"      \"animations\": {\n"
         @"        \"open\": {\n"
         @"          \"type\": \"scale-fade\",\n"
         @"          \"duration\": 0.25,\n"
         @"          \"easing\": \"ease-out\",\n"
         @"          \"damping\": 0.8,\n"
         @"          \"stiffness\": 300.0\n"
         @"        },\n"
         @"        \"close\": {\n"
         @"          \"type\": \"scale-fade\",\n"
         @"          \"duration\": 0.2,\n"
         @"          \"easing\": \"ease-in\",\n"
         @"          \"damping\": 0.8,\n"
         @"          \"stiffness\": 300.0\n"
         @"        },\n"
         @"        \"focus\": {\n"
         @"          \"type\": \"scale-fade\",\n"
         @"          \"duration\": 0.15,\n"
         @"          \"easing\": \"ease-in-out\",\n"
         @"          \"damping\": 0.9,\n"
         @"          \"stiffness\": 400.0\n"
         @"        },\n"
         @"        \"resize\": {\n"
         @"          \"type\": \"elastic\",\n"
         @"          \"duration\": 0.3,\n"
         @"          \"easing\": \"spring\",\n"
         @"          \"damping\": 0.7,\n"
         @"          \"stiffness\": 250.0\n"
         @"        }\n"
         @"      }\n"
         @"    }\n"
         @"  },\n"
         @"\n"
         @"  \"rules\": [\n"
         @"    {\n"
         @"      \"match\": {\n"
         @"        \"bundleIdentifier\": \"com.apple.finder\",\n"
         @"        \"state\": \"active\"\n"
         @"      },\n"
         @"      \"override\": {\n"
         @"        \"decoration\": {\n"
         @"          \"border\": {\n"
         @"            \"enabled\": true,\n"
         @"            \"thickness\": 1.0,\n"
         @"            \"glow\": {\n"
         @"              \"radius\": 4.0,\n"
         @"              \"color\": \"#007AFF40\",\n"
         @"              \"animated\": false\n"
         @"            }\n"
         @"          }\n"
         @"        }\n"
         @"      }\n"
         @"    },\n"
         @"    {\n"
         @"      \"match\": {\n"
         @"        \"title\": \"Settings\",\n"
         @"        \"windowClass\": \"NSWindow\"\n"
         @"      },\n"
         @"      \"override\": {\n"
         @"        \"geometry\": {\n"
         @"          \"cornerRadius\": 16.0\n"
         @"        },\n"
         @"        \"materials\": {\n"
         @"          \"vibrancy\": \"sidebar\"\n"
         @"        }\n"
         @"      }\n"
         @"    }\n"
         @"  ]\n"
         @"}";
}

void handleConfigCommand() {
  printHeader("macwmfx Setup");
  NSString *userConfigDir =
      [NSString stringWithFormat:@"%@/.config/macwmfx", NSHomeDirectory()];
  NSString *userConfigPath =
      [userConfigDir stringByAppendingPathComponent:@"config.json"];

  NSFileManager *fm = [NSFileManager defaultManager];
  [fm createDirectoryAtPath:userConfigDir
      withIntermediateDirectories:YES
                       attributes:nil
                            error:nil];

  [[generateDefaultConfig() dataUsingEncoding:NSUTF8StringEncoding]
      writeToFile:userConfigPath
       atomically:YES];
  printSuccess("Configuration created at: %s", [userConfigPath UTF8String]);
}

void handleServerCommand(NSString *command) {
  macwmfxClient *client = [macwmfxClient sharedClient];
  [client connectWithCompletion:^(macwmfxServerResponse *response,
                                  NSError *error) {
    if (error) {
      printError("Server not reachable. Please ensure macwmfx is installed.");
      gKeepRunning = NO;
      return;
    }

    void (^completion)(macwmfxServerResponse *, NSError *) = ^(
        macwmfxServerResponse *res, NSError *err) {
      if (err)
        printError("Command failed: %s", [err.localizedDescription UTF8String]);
      else
        printSuccess("%s",
                     [res.data[@"message"] UTF8String] ?: "Command successful");
      gKeepRunning = NO;
    };

    if ([command isEqualToString:@"reload"])
      [client reloadWithCompletion:completion];
    else if ([command isEqualToString:@"start"])
      [client startServerWithCompletion:completion];
    else if ([command isEqualToString:@"stop"])
      [client stopServerWithCompletion:completion];
    else if ([command isEqualToString:@"status"]) {
      [client
          getStatusWithCompletion:^(macwmfxServerResponse *res, NSError *err) {
            if (err)
              printError("Status failed: %s",
                         [err.localizedDescription UTF8String]);
            else {
              printHeader("macwmfx Status");
              printColor(COLOR_CYAN, "  Running: %s\n",
                         [res.data[@"running"] boolValue] ? "Yes" : "No");
              printColor(COLOR_CYAN, "  Connections: %ld\n",
                         [res.data[@"clientCount"] integerValue]);
            }
            gKeepRunning = NO;
          }];
    } else {
      gKeepRunning = NO;
    }
  }];
}

void showHelp(const char *progName) {
  printHeader("macwmfx CLI");
  printf("Usage: %s <command>\n\n", progName);
  printf("Commands:\n");
  printf("  --help            Show this help\n");
  printf("  --generate-config Create default JSON configuration\n");
  printf("  --reload          Reload configuration and refresh windows\n");
  printf("  --start           Identify and start managing windows\n");
  printf("  --stop            Stop managing windows\n");
  printf("  --status          Show engine status\n");
  printf("  --observe-logs    Steam logs from macwmfx\n\n");
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    macwmfx_logging_init();
    if (argc < 2) {
      showHelp(argv[0]);
      return 0;
    }

    NSString *arg = [NSString stringWithUTF8String:argv[1]];
    if ([arg isEqualToString:@"--help"]) {
      showHelp(argv[0]);
      return 0;
    }
    if ([arg isEqualToString:@"--generate-config"]) {
      handleConfigCommand();
      return 0;
    }

    if ([arg hasPrefix:@"--"]) {
      handleServerCommand([arg substringFromIndex:2]);
      while (gKeepRunning) {
        [[NSRunLoop currentRunLoop]
            runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
      }
    } else {
      showHelp(argv[0]);
    }
  }
  return 0;
}
