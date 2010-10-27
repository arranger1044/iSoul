//
//  LoggingController.h
//  LoggingConsole
//
//  Created by valerio on 22/10/10.
//  Copyright 2010 rano. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define LOG_PATH @"Library/Logs/rainbow.log"

@class LoggingConsole;

@interface LoggingController : NSObject {

    LoggingConsole * console;
}

+ (LoggingController *)sharedInstance;
- (void)startLogging;

@end
