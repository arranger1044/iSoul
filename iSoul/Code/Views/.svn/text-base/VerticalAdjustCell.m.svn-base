//
//  VerticalAdjustCell.m
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "VerticalAdjustCell.h"


@implementation VerticalAdjustCell

- (BOOL)isEditable
{
	return NO;
}

- (id)copyWithZone:(NSZone*)zone
{
    VerticalAdjustCell *cell = (VerticalAdjustCell*)[super copyWithZone:zone];
    return cell;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// adjust the text frame to be centred vertically
	NSSize s = [[self stringValue] sizeWithAttributes:
				[NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName,nil]];
		
	NSRect newFrame = cellFrame;
	float yOffset = ceil((cellFrame.size.height - s.height) / 2);
	newFrame.origin.y += yOffset; 
	newFrame.size.height -= yOffset;
	[super drawWithFrame:newFrame inView:controlView];
}

@end
