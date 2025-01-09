//
//  ConfigParser.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#ifndef ConfigParser_h
#define ConfigParser_h

#import <Foundation/Foundation.h>

@interface ConfigParser : NSObject

+ (instancetype)sharedInstance;
- (void)loadConfig;

@end

#endif /* ConfigParser_h */ 