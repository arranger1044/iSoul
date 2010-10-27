//
//  ExpandingSidebar.m
//  iSoul
//
//  Created by Richard on 1/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ExpandingSidebar.h"
#import "SidebarItem.h"

#define kRightBuffer	8
#define kTopBuffer		4
#define kIconSize		14

@implementation ExpandingSidebar
@synthesize connectionState;

- (void)awakeFromNib
{
	connectionState = usOffline;
}

- (void)setConnectionState:(ConnectionState)newState
{
	connectionState = newState;
	[self setNeedsDisplayInRect:[self getIconRect]];
}
	 
- (NSRect)getIconRect
{
	NSRect bounds = [self bounds];
	return NSMakeRect(bounds.origin.x + bounds.size.width - kIconSize - kRightBuffer, 
					  bounds.origin.y + kTopBuffer, kIconSize, kIconSize);
}

- (void)reloadData;
{
	[super reloadData];
	
	for(NSInteger i = 0; i < [self numberOfRows]; i++) {
		NSTreeNode *item = [self itemAtRow:i];
		SidebarItem *si = [item representedObject];
		if([[si isExpanded] boolValue]) {
			[self expandItem:item];
		}			
	}
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	NSImage *statusImage = nil;
	switch (connectionState) {
		case usOnline:
		{
			statusImage = [NSImage imageNamed:@"Connect"];
			break;
		}
		case usOffline:
		{
			statusImage = [NSImage imageNamed:@"Disconnect"];
			break;
		}
		case usAway:
		{
			statusImage = [NSImage imageNamed:@"Away"];
			break;
		}
	}
	
	if (statusImage) {
		NSRect imageRect = [self getIconRect];
		
		// only draw the image if necessary
		if (NSIntersectsRect(rect, imageRect)) {
			[statusImage compositeToPoint:NSMakePoint(imageRect.origin.x, imageRect.origin.y + imageRect.size.height)
								operation:NSCompositeSourceOver];
		}		
	}
}

@end
