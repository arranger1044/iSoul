//
//  LoggingConsole.m
//  LoggingConsole
//
//  Created by valerio on 22/10/10.
//  Copyright 2010 rano. All rights reserved.
//

#import "LoggingConsole.h"


@implementation LoggingConsole

@synthesize loggingView;

- (void)awakeFromNib{

    [self.window setTitle:@"Console"];
    [loggingView setEditable:NO];
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

@end
