//
//  LoggingController.m
//  LoggingConsole
//
//  Created by valerio on 22/10/10.
//  Copyright 2010 rano. All rights reserved.
//

#import "LoggingController.h"
#import "NSData+CocoaDevUsersAdditions.h"
#import "Constants.h"
#include "time.h"

#define DEBUG_LOGGING_CONTROLLER

@interface LoggingController ()

@property (nonatomic, copy) NSString * startingDate;

@end


@implementation LoggingController

@synthesize startingDate;
@synthesize isLogging;

#pragma mark -
#pragma mark Singleton Pattern

static LoggingController * sharedControllerIstance = nil;

+ (LoggingController *) sharedInstance{
    
    if (sharedControllerIstance == nil) {
        sharedControllerIstance = [[super allocWithZone:NULL] init];
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

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

#pragma mark -
#pragma mark Logging Management

//- (void)logReadMessage:(NSNotification *)aNotification
//{
//    //printf("notification received\n");
//    //printf("%s\n", (char *)[[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem] bytes]);
//    NSString * readChars = [[NSString alloc] initWithData:[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem] 
//                                                 encoding:NSUTF8StringEncoding];
//    [console logMessage:readChars];
//    [readChars release];
//    [[aNotification object] readInBackgroundAndNotify];
//}

- (void)redirectStdErrStdOutToFile:(NSString *)logPath{
    
    //NSString * logPath = [NSHomeDirectory() stringByAppendingPathComponent:logPath];
	freopen([logPath fileSystemRepresentation], "a", stderr);
    freopen([logPath fileSystemRepresentation], "a", stdout);
}

- (NSString *)todaysDateAsString{
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    NSLocale * usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
    [formatter setLocale:usLocale];
    [usLocale release];
    NSString * todaysDate = [formatter stringFromDate:[NSDate date]];
    [formatter release];
    return [todaysDate stringByReplacingOccurrencesOfString:@":" withString:@"."] 
            ;
}

- (void)printStartingLogging:(NSString *)logPath{

    NSString * todaysDate = [self todaysDateAsString];

    NSString * heading = [NSString stringWithFormat:@"\n*****************************      SECRET PROJECT RAINBOW      *********************************\n"
                          "*****************************          LOG %@          *********************************\n\n", todaysDate];
    
    NSFileHandle * myHandle = [NSFileHandle fileHandleForUpdatingAtPath:logPath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[heading dataUsingEncoding:NSUTF8StringEncoding]];
    [myHandle closeFile];

}

- (void)startLogging{
    
    if (!isLogging)
    {
        //NSString * logPath = [NSHomeDirectory() stringByAppendingPathComponent:LOG_PATH];
        DNSLog(@"LP %@", [[NSUserDefaults standardUserDefaults] valueForKey:@"LogPath"]);
        NSString * logPath = [[[NSUserDefaults standardUserDefaults] valueForKey:@"LogPath"] 
                              stringByAppendingPathComponent:logFileName];

        DNSLog(@"%@",logPath);
        /* Redirecting output streams */
        [self redirectStdErrStdOutToFile:logPath];
        
        /* Save the starting current date */
        self.startingDate = [self todaysDateAsString];
        /* Log the heading first */
        [self printStartingLogging:logPath];
        
        /* Notify the logging has started */
        isLogging = YES;
    }
}


- (void)checkCreateLoggingDirectory:(NSString *)logDir{
    
    NSFileManager * NSFm = [NSFileManager defaultManager];
    
    BOOL isDir = YES;
    NSError * error;
    
    if(![NSFm fileExistsAtPath:logDir isDirectory:&isDir])
    {
        if (![NSFm createDirectoryAtPath:logDir
             withIntermediateDirectories:YES
                              attributes:nil
                                   error:&error])
        {
            NSLog(@"Impossible to create logging directory %@. Error: %@", logDir, [error description]);
        }
    }
    else 
    {
        NSLog(@"%@ already exists as a directory", logDir);
    }        
}

- (void)deleteCurrentLog:(NSString *)logPath{
    NSFileManager * NSFm = [NSFileManager defaultManager];
    NSError * error;
    
    if (![NSFm removeItemAtPath:logPath error:&error])
    {
        NSLog(@"Impossible to remove current log file %@. Error: %@", logPath, [error description]);
    }
}

- (void)archiveLogFile:(NSString *)logPath toDirectory:(NSString *)dirPath{
    NSFileManager * NSFm = [NSFileManager defaultManager];
    NSError * error;
    NSString * logName = [logPath lastPathComponent];
#ifdef DEBUG_LOGGING_CONTROLLER
    NSLog(@"logPath: %@ logFileName: %@", logPath, logName);
#endif
    NSString * archivedLogPath = [dirPath stringByAppendingPathComponent:logName];
#ifdef DEBUG_LOGGING_CONTROLLER
    NSLog(@"dirPath: %@ archivedLogPath: %@", dirPath, archivedLogPath);
#endif
    if (![NSFm moveItemAtPath:logPath toPath:archivedLogPath error:&error])
    {
        NSLog(@"Impossible to move current log file %@", [error description]);
    }
}

- (void)gzipAndArchiveLog:(NSString *)logPath toDirectory:(NSString *)dirPath{
    /* Checks if the loggin directory exists and if not creates it */
    [self checkCreateLoggingDirectory:dirPath];
    /* Get NSData from logPath */
    NSData * logData = [NSData dataWithContentsOfFile:logPath];
    /* Compress it with gzip */
    NSData * compressedLogData = [logData gzipDeflate];
    /* Create a name with today's date*/    
    NSString * todaysDate = [self todaysDateAsString];
    NSString * archivedLogName = [NSString stringWithFormat:@"LOG %@ - %@.log.gzip", self.startingDate, todaysDate];
#ifdef DEBUG_LOGGING_CONTROLLER 
    NSLog(@"todaysDate: %@ archivedLogName: %@", todaysDate, archivedLogName);
#endif
    
    NSString * logCurrentPath = [logPath stringByDeletingLastPathComponent];
    NSString * temporaryLogPath = [logCurrentPath stringByAppendingPathComponent:archivedLogName];
#ifdef DEBUG_LOGGING_CONTROLLER
    NSLog(@"temporaryLogPath: %@ logCurrentPath: %@", temporaryLogPath, logCurrentPath);
#endif
    [compressedLogData writeToFile:temporaryLogPath atomically:NO];
    /* move it to the dir */
    [self archiveLogFile:temporaryLogPath toDirectory:dirPath];
    
    [self deleteCurrentLog:logPath];
}


@end
