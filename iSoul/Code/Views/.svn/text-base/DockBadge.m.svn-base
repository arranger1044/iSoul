//
//  DockBadge.m
//  iSoul
//
//  Created by Richard on 12/11/09.
//  Copyright 2009 BDP. All rights reserved.
//
//  based on code from transmission (as are the pics)
//  thanks!


#import "DockBadge.h"
#import "NSStringSpeed.h"

#define kPadding 2.0f

@implementation DockBadge

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
    if (self) {
		downloadRate = uploadRate = 0.0;
		
		// cache the images
        downloadBadge = [[NSImage imageNamed:@"DownloadBadge"] retain];
		uploadBadge = [[NSImage imageNamed:@"UploadBadge"] retain];
		
		// create the string font attributes
		NSShadow *stringShadow = [[NSShadow alloc] init];
        [stringShadow setShadowOffset: NSMakeSize(2.0f, -2.0f)];
        [stringShadow setShadowBlurRadius: 4.0f];        
		// attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		//			   [NSColor whiteColor], NSForegroundColorAttributeName,
		//			   [NSFont boldSystemFontOfSize: 26.0f], NSFontAttributeName, stringShadow, NSShadowAttributeName, nil];
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
					  			   [NSColor whiteColor], NSForegroundColorAttributeName,
					  			   [NSFont boldSystemFontOfSize: 26.0f], NSFontAttributeName, nil];
        [stringShadow release];
    }
    return self;
}

- (void)dealloc
{
	[attributes release];
	[uploadBadge release];
	[downloadBadge release];
	[super dealloc];
}

// returns true if the values are new
- (BOOL)setDownloadRate:(float)dl uploadRate:(float)ul
{
	if ((downloadRate == dl) && (uploadRate == ul)) {
		return NO;
	}
	
	downloadRate = dl;
	uploadRate = ul;
	return YES;
}

- (void)drawRect:(NSRect)rect
{
	// draw the icon image first
	[[NSApp applicationIconImage] drawInRect:rect 
									fromRect:NSZeroRect 
								   operation:NSCompositeSourceOver 
									fraction:1.0];
	
	float bottom = 0.0;
	
	if (uploadRate > 0) {
		NSString *uploadString = [NSString stringForSpeed:uploadRate];
		[self drawBadge:uploadBadge string:uploadString atHeight:bottom];
		bottom += [uploadBadge size].height + kPadding;
	}
	
	if (downloadRate > 0) {
		NSString *downloadString = [NSString stringForSpeed:downloadRate];
		[self drawBadge:downloadBadge string:downloadString atHeight:bottom];
	}
}

- (void)drawBadge:(NSImage *)badge string:(NSString *)string atHeight:(float)height
{
    NSRect badgeRect;
    badgeRect.size = [badge size];
    badgeRect.origin.x = 0;
    badgeRect.origin.y = height;
    
    [badge drawInRect:badgeRect fromRect:NSZeroRect operation: NSCompositeSourceOver fraction: 1.0f];
    
    //string is in center of image
    NSSize stringSize = [string sizeWithAttributes:attributes];
    
    NSRect stringRect = badgeRect;
    stringRect.origin.x += (badgeRect.size.width - stringSize.width) * 0.5f;
    stringRect.origin.y += (badgeRect.size.height - stringSize.height) * 0.5f + 1.0f; //adjust for shadow
    stringRect.size = stringSize;
    
    [string drawInRect:stringRect withAttributes:attributes];
}

@end
