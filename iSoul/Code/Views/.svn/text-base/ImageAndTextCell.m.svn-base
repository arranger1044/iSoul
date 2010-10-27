//
//  FileCell.m
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "ImageAndTextCell.h"

#define kImageOriginXOffset 2
#define kImageOriginYOffset 1
#define kTextOriginXOffset	4

@implementation ImageAndTextCell
@synthesize image;

- (void)dealloc
{
	[image release];
	image = nil;
	[super dealloc];
}

- (BOOL)isEditable
{
	return NO;
}

- (id)copyWithZone:(NSZone*)zone
{
    ImageAndTextCell *cell = (ImageAndTextCell*)[super copyWithZone:zone];
    cell->image = [image retain];
    return cell;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (image != nil)
	{
		// draw the image first
		NSRect imageFrame = cellFrame;
		NSSize imageSize = [image size];
		imageFrame.origin.x += kImageOriginXOffset;
		imageFrame.origin.y -= kImageOriginYOffset;
        imageFrame.size = imageSize;
		
        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
		[image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
		cellFrame.origin.x += imageFrame.size.width + kImageOriginXOffset;
		cellFrame.size.width -= imageFrame.size.width + kImageOriginXOffset;
	}

	// now draw the file name
	cellFrame.origin.x += kTextOriginXOffset;
	cellFrame.size.width -= kTextOriginXOffset;
	
	// vertically align the text in the cell
	NSSize s = [[self stringValue] sizeWithAttributes:
				[NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName,nil]];
	float yOffset = ceil((cellFrame.size.height - s.height) / 2.0);
	cellFrame.origin.y += yOffset;
	cellFrame.size.height -= yOffset;
	[super drawWithFrame:cellFrame inView:controlView];
}
		

@end
