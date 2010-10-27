//
//  LoggingController.m
//  LoggingConsole
//
//  Created by valerio on 22/10/10.
//  Copyright 2010 rano. All rights reserved.
//

#import "LoggingController.h"
#import "LoggingConsole.h"

@interface LoggingController()

@property (nonatomic, assign) LoggingConsole * console;

@end

@implementation LoggingController

@synthesize console;

#pragma mark -
#pragma mark Singleton Pattern

static LoggingController * sharedControllerIstance = nil;

+ (LoggingController *) sharedInstance{
    
    if (sharedControllerIstance == nil) {
        sharedControllerIstance = [[super allocWithZone:NULL] init];
        sharedControllerIstance.console = [[LoggingConsole alloc] 
                                           initWithWindowNibName:@"LoggingConsole"];
        [sharedControllerIstance.console showWindow:self];
    }
    return sharedControllerIstance;
    
}

+ (id)allocWithZone:(NSZone *)zone {
    
    return [[self sharedInstance] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;  
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

#pragma mark -
#pragma mark Logging Management

- (void)logReadMessage:(NSNotification *)aNotification
{
    printf("notification received\n");
    //printf("%s\n", (char *)[[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem] bytes]);
    NSString * readChars = [[NSString alloc] initWithData:[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding:NSUTF8StringEncoding];
    [console logMessage:readChars];
    [readChars release];
    [[aNotification object] readInBackgroundAndNotify];
}

- (void)startLogging{
    
    NSString * logPath = [NSHomeDirectory() stringByAppendingPathComponent:LOG_PATH];
    NSFileHandle * fh = [NSFileHandle fileHandleForReadingAtPath:logPath];
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(logReadMessage:)
                               name:NSFileHandleReadCompletionNotification
                             object:fh];
    
    [fh readInBackgroundAndNotify];
    
}




@end
