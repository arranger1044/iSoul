//
//  LoggingController.h
//  LoggingConsole
//
//  Created by valerio on 22/10/10.
//  Copyright 2010 rano. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LoggingConsole;

@interface LoggingController : NSObject {

    NSString * startingDate;
    BOOL isLogging;
}

@property (nonatomic, assign) BOOL isLogging;

+ (LoggingController *)sharedInstance;
- (void)startLogging;
- (void)gzipAndArchiveLog:(NSString *)logPath toDirectory:(NSString *)dirPath;

@end
