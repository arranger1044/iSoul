//
//  QueueCell.m
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "QueueCell.h"

#define kImageOriginXOffset 2.0
#define kImageOriginYOffset 14.0

@implementation QueueCell
@synthesize timeImages;
@synthesize selectedTimeImages;

- (void)dealloc
{
	[timeImages release];
	timeImages = nil;
	[selectedTimeImages release];
	selectedTimeImages = nil;
	[super dealloc];
}

- (BOOL)isEditable
{
	return NO;
}

- (id)copyWithZone:(NSZone*)zone
{
    QueueCell *cell = (QueueCell*)[super copyWithZone:zone];
    cell->timeImages = [timeImages retain];
	cell->selectedTimeImages = [selectedTimeImages retain];
    return cell;
}

- (void)loadImages
{
	// preload the time images
	NSMutableArray *imageArray = [[NSMutableArray alloc] init];
	NSMutableArray *selectedArray = [[NSMutableArray alloc] init];
	for (int i = 5; i <= 60; i += 5) {
		NSImage *myImage = [NSImage imageNamed:[NSString stringWithFormat:@"%dmin",i]];
		NSImage *selectedImage = [NSImage imageNamed:[NSString stringWithFormat:@"%dmin_selected",i]];
		[imageArray addObject:myImage];
		[selectedArray addObject:selectedImage];
	}
	timeImages = [NSArray arrayWithArray:imageArray];
	selectedTimeImages = [NSArray arrayWithArray:selectedArray];
	[timeImages retain];
	[selectedTimeImages retain];
	[imageArray release];
	[selectedArray release];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (!self.objectValue) return;
	
	// first check whether the images have been cached
	if (!timeImages) {
		[self loadImages];
	}
	
	// queue time in seconds
	float t = self.floatValue;	
	NSImage *image = nil;
	NSString *caption = nil;
	
	if (t > 0) 
	{
		t /= 60.0;	// q time in minutes
		NSUInteger i = [timeImages count] - 1;
		if (t < 60.0) {
			i = (NSUInteger)t/5;
			caption = [NSString stringWithFormat:@"%lu minutes",5*(i+1)];
		} else {
			t = MIN(999.0f, t / 60.0f);	// q time in hours
			if (t < 2.0) {
				caption = @"1 hour";
			} else {
				caption = [NSString stringWithFormat:@"%1.0f hours",t];
			}
		}
		
		if (self.isHighlighted) {
			image = [selectedTimeImages objectAtIndex:i];
		} else {
			image = [timeImages objectAtIndex:i];
		}
		
	}
	else 
	{
		caption = @"none";
	}

	// store the new string value
	[self setStringValue:caption];
	
	// adjust the text frame to be centred vertically
	NSSize s = [caption sizeWithAttributes:
				[NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName,nil]];	
	double yOffset = ceil((cellFrame.size.height - s.height) / 2.0);
	NSRect newFrame = cellFrame;
	newFrame.origin.y += yOffset;
	newFrame.size.height -= yOffset;
	[super drawWithFrame:newFrame inView:controlView];
	
	// draw the image finally, needs to be after the text 
	// otherwise the image will not draw when selected
	if (image) {
		NSRect imageFrame = cellFrame;	
		imageFrame.origin.x += kImageOriginXOffset;
		imageFrame.origin.y += kImageOriginYOffset;
		[image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
	}
}

@end
