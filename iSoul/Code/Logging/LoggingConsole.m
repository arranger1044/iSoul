//
//  LoggingConsole.m
//  LoggingConsole
//
//  Created by valerio on 22/10/10.
//  Copyright 2010 rano. All rights reserved.
//

#import "LoggingConsole.h"
#import "LoggingController.h"
#import "Constants.h"

@implementation LoggingConsole

@synthesize loggingView;
@synthesize cleanButton;

- (void)logReadMessage:(NSNotification *)aNotification
{
    NSString * readChars = [[NSString alloc] initWithData:[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem] 
                                                 encoding:NSUTF8StringEncoding];
    [self logMessage:readChars];
    [readChars release];
    [[aNotification object] readInBackgroundAndNotify];
}


- (id)initWithWindowNibName:(NSString *)windowNibName{
	self = [super initWithWindowNibName:@"LoggingConsole"];
	if (!self)
		return nil;

	DNSLog(@"init Console");

	return self;
}

- (void)awakeFromNib{

    [self.window setTitle:@"Console"];
    [loggingView setEditable:NO];
    
    /* Ask to log */
    [[LoggingController sharedInstance] startLogging];
    
    NSString * logPath = [[[NSUserDefaults standardUserDefaults] valueForKey:@"LogPath"] 
                          stringByAppendingPathComponent:logFileName];
    
    /* Start receiving notification for file */
    NSFileHandle * fh = [NSFileHandle fileHandleForReadingAtPath:logPath];
//    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
//    [notificationCenter addObserver:self
//                           selector:@selector(logReadMessage:)
//                               name:NSFileHandleReadCompletionNotification
//                             object:fh];
    
    [fh readInBackgroundAndNotify]; 
    
}

- (void)logMessage:(NSString *)message{
    
    BOOL scrollToEnd = YES;
    NSScrollView * scrollView = (NSScrollView *)loggingView.superview.superview;
    if (loggingView.frame.size.height > [scrollView frame].size.height) 
    {
       if (1.0f != [scrollView verticalScroller].floatValue)
            scrollToEnd = NO;
    }


    NSAttributedString * formattedString = [[NSAttributedString alloc] initWithString:message];
    NSTextStorage * storage = [loggingView textStorage];
	
	//[storage beginEditing];
	[storage appendAttributedString:formattedString];
	//[storage endEditing];
    [formattedString release];
    
    if (scrollToEnd) 
    {
        NSRange range = NSMakeRange ([[loggingView string] length], 0);
        [loggingView scrollRangeToVisible: range];
    }
    
}

- (void)cleanConsole:(id)sender{
    [loggingView setString:@""];
}

@end
