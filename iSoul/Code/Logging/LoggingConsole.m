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

- (void) refreshLog: (NSNotification *) aNotification {
	[aNotification.object readInBackgroundAndNotify];
}

- (void) logReadMessage: (NSNotification *) aNotification {
	NSData * data = [aNotification.userInfo objectForKey: NSFileHandleNotificationDataItem];

	if (data.length) {
		NSString * readChars = [[NSString alloc] initWithData: data 
													 encoding: NSUTF8StringEncoding];
		[self logMessage: readChars];
		//[data release];
		[readChars release];
		[aNotification.object readInBackgroundAndNotify];
	} else {
		[self performSelector: @selector(refreshLog:) withObject: aNotification afterDelay: 1.0];
	}
}


- (id) initWithWindowNibName: (NSString *) windowNibName{
	self = [super initWithWindowNibName: @"LoggingConsole"];
	if (!self)
		return nil;

	DNSLog(@"init Console");

	return self;
}

- (void) awakeFromNib {
	self.window.title = @"Console";
	loggingView.editable = NO;
    
    /* Ask to log */
    [LoggingController.sharedInstance startLogging];
    
    NSString * logPath = [[NSUserDefaults.standardUserDefaults valueForKey: @"LogPath"] 
                          stringByAppendingPathComponent: logFileName];
    
    /* Start receiving notification for file */
    NSFileHandle * fh = [NSFileHandle fileHandleForReadingAtPath: logPath];
    [NSNotificationCenter.defaultCenter addObserver: self
										   selector: @selector(logReadMessage:)
											   name: NSFileHandleReadCompletionNotification
											 object: fh];
    
    [fh readInBackgroundAndNotify]; 
    
    //[loggingView setUsesFindBar:YES];
    
}

- (void) logMessage:(NSString *) message {
    BOOL scrollToEnd = YES;
    NSScrollView * scrollView = (NSScrollView *) loggingView.superview.superview;
	
    if (loggingView.frame.size.height > scrollView.frame.size.height &&
		scrollView.verticalScroller.floatValue != 1.0f)
		scrollToEnd = NO;

    NSAttributedString * formattedString = [[NSAttributedString alloc] initWithString: message];
    NSTextStorage * storage = loggingView.textStorage;
	
	//[storage beginEditing];
	[storage appendAttributedString: formattedString];
	//[storage endEditing];
    [formattedString release];
    
    if (scrollToEnd) {
        NSRange range = NSMakeRange(loggingView.string.length, 0);
        [loggingView scrollRangeToVisible: range];
    }
    
}

- (void) cleanConsole: (id) sender{
	loggingView.string = @"";
}

@end
