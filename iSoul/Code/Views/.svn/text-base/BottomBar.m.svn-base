//
//  BottomBar.m
//  iSoul
//
//  Created by Richard on 11/7/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "BottomBar.h"


@implementation BottomBar
@synthesize background;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		// default background
        background = [[NSImage imageNamed:@"ChatBackground"] retain];
    }
    return self;
}

- (void)dealloc
{
	[background release];
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
	
	// get the portion of the background bar to draw
	NSRect r = NSMakeRect(0, dirtyRect.origin.y - bounds.origin.y, 1, dirtyRect.size.height);
	
	[background drawInRect:dirtyRect 
				  fromRect:r 
				 operation:NSCompositeSourceOver
				  fraction:1.0];
}

@end
