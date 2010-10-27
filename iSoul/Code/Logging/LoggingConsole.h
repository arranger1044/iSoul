//
//  LoggingConsole.h
//  LoggingConsole
//
//  Created by valerio on 22/10/10.
//  Copyright 2010 rano. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LoggingConsole : NSWindowController {

    NSTextView * loggingView;
}

@property (nonatomic, assign) IBOutlet NSTextView * loggingView;

- (void)logMessage:(NSString *)message;

@end
