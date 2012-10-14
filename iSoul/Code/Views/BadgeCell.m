//
//  BadgeCell.m
//  iSoul
//
//  Created by Richard on 10/28/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "BadgeCell.h"

#define kTextOriginXOffset	2
#define kTextOriginYOffset	2
#define kTextHeightAdjust	4

#define kBadgeBufferRight		3
#define kBadgeBufferLeft		4
#define kBadgeBufferTop			3
#define kBadgeBufferLeftSmall	2
#define kBadgeCircleBufferRight	0
#define kBadgeTextHeight		14
#define kBadgeXRadius			7
#define kBadgeYRadius			8
#define	kBadgeTextSmall			20

@implementation BadgeCell

@synthesize badgeCount;
@synthesize image;

- (void)dealloc
{
	[image release];
	image = nil;
	[super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
    BadgeCell *cell = (BadgeCell*)[super copyWithZone:zone];
    cell->image = [image retain];
    return cell;
}

// only leaf nodes should be editable
- (BOOL)isEditable
{
	return (image != nil);
}

- (NSRect)titleRectForBounds:(NSRect)cellRect
{	
	NSSize imageSize = [image size];
	CGFloat xOffset = imageSize.width + kTextOriginXOffset;
	NSRect titleFrame = NSMakeRect(cellRect.origin.x + xOffset, 
								   cellRect.origin.y, 
								   cellRect.size.width - xOffset - kBadgeBufferRight, 
								   cellRect.size.height);
	return titleFrame;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject event:(NSEvent*)theEvent
{
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (NSColor *)highlightColorInView:(NSView *)controlView
{
    return [NSColor clearColor];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (image != nil)
	{
		// draw the image first
		NSSize imageSize = [image size];
		NSPoint imagePoint = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y);		
        if ([controlView isFlipped])
            imagePoint.y += ceil((cellFrame.size.height + imageSize.height) / 2);
        else
            imagePoint.y += ceil((cellFrame.size.height - imageSize.height) / 2);
		[image compositeToPoint:imagePoint operation:NSCompositeSourceOver];
		
		// Set up badge string and size
		CGFloat badgeX = cellFrame.origin.x + cellFrame.size.width;
		if (badgeCount > 0) {
			badgeX -= kBadgeBufferRight;
			NSString *badge = [NSString stringWithFormat:@"%ld", badgeCount];
			NSSize badgeNumSize = [badge sizeWithAttributes:nil];
			
			// Calculate the badge's coordinates.
			CGFloat badgeWidth = badgeNumSize.width + kBadgeBufferLeft * 2;
			if (badgeWidth < kBadgeTextSmall)
			{
				// The text is too short. Decrease the badge's size.
				badgeWidth = kBadgeTextSmall;
			}
			badgeX -= kBadgeCircleBufferRight + badgeWidth;
			CGFloat badgeY = cellFrame.origin.y + kBadgeBufferTop;
			CGFloat badgeNumX = badgeX + kBadgeBufferLeft;
			if (badgeWidth == kBadgeTextSmall)
			{
				badgeNumX += kBadgeBufferLeftSmall;
			}
			NSRect badgeRect = NSMakeRect(badgeX, badgeY, badgeWidth, kBadgeTextHeight);
			
			// Draw the badge and number.
			NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeRect 
																	  xRadius:kBadgeXRadius 
																	  yRadius:kBadgeYRadius];
			if ([[NSApp mainWindow] isVisible] && ![self isHighlighted])
			{
				// The row is not selected and the window is in focus.
				
				[[NSColor colorWithCalibratedRed:.53 green:.60 blue:.74 alpha:1.0] set];
				[badgePath fill];
				NSDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
				[dict setValue:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName];
				[dict setValue:[NSNumber numberWithFloat:-.25] forKey:NSKernAttributeName];
				[dict setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
				[badge drawAtPoint:NSMakePoint(badgeNumX,badgeY) withAttributes:dict];
			}
			else if ([[NSApp mainWindow] isVisible])
			{
				// The row is selected and the window is in focus.
				[[NSColor whiteColor] set];
				[badgePath fill];
				NSDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
				[dict setValue:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName];
				[dict setValue:[NSNumber numberWithFloat:-.25] forKey:NSKernAttributeName];
				[dict setValue:[NSColor alternateSelectedControlColor] forKey:NSForegroundColorAttributeName];
				[badge drawAtPoint:NSMakePoint(badgeNumX,badgeY) withAttributes:dict];
			}
			else if (![[NSApp mainWindow] isVisible] && ![self isHighlighted])
			{
				// The row is not selected and the window is not in focus.
				[[NSColor disabledControlTextColor] set];
				[badgePath fill];
				NSDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
				[dict setValue:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName];
				[dict setValue:[NSNumber numberWithFloat:-.25] forKey:NSKernAttributeName];
				[dict setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
				[badge drawAtPoint:NSMakePoint(badgeNumX,badgeY) withAttributes:dict];
			}
			else
			{
				// The row is selected and the window is not in focus.
				[[NSColor whiteColor] set];
				[badgePath fill];
				NSDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
				[dict setValue:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName];
				[dict setValue:[NSNumber numberWithFloat:-.25] forKey:NSKernAttributeName];
				[dict setValue:[NSColor disabledControlTextColor] forKey:NSForegroundColorAttributeName];
				[badge drawAtPoint:NSMakePoint(badgeNumX,badgeY) withAttributes:dict];
			}
		} 
		
		// now adjust the cellframe to account for the image and badge
		cellFrame.origin.x += imageSize.width + kTextOriginXOffset;
		cellFrame.size.width = badgeX - cellFrame.origin.x;
		cellFrame.origin.y += kTextOriginYOffset;
		cellFrame.size.height -= kTextHeightAdjust;
		[super drawWithFrame:cellFrame inView:controlView];
	}
	else 
	{
		// must be a group cell, just get super to take care of it
		[super drawWithFrame:cellFrame inView:controlView];
	}

}



@end
