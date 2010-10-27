//
//  DownloadFilenameCell.m
//  iSoul
//
//  Created by Richard on 10/30/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "DownloadFilenameCell.h"
#import "PathNode.h"
#import "User.h"

#define kImageOriginXOffset 2.0
#define kUsernameTextOffset	17.0

@implementation DownloadFilenameCell

- (BOOL)isEditable
{
	return NO;
}

- (id)copyWithZone:(NSZone*)zone
{
    DownloadFilenameCell *cell = (DownloadFilenameCell*)[super copyWithZone:zone];
    return cell;
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
	return NSZeroRect;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	PathNode *node = (PathNode *)[self objectValue];
	NSString *extension = [[[node name] pathExtension] lowercaseString];
	
	// if the node is a folder, use a folder icon
	NSImage *image = nil;
	if ([node isFolder]) {
		if ([node isExpanded]) {
			image = [[NSWorkspace sharedWorkspace] 
					 iconForFileType:NSFileTypeForHFSTypeCode(kOpenFolderIcon)];
		} else {
			image = [[NSWorkspace sharedWorkspace] 
					 iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		}		
	} else {
		image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
	}
	[image setSize:NSMakeSize(cellFrame.size.height, cellFrame.size.height)];
	
	// draw the icon
	float xOffset = kImageOriginXOffset;
	if (image) {
		NSSize imageSize = [image size];
		NSRect imageFrame = cellFrame;
			
		imageFrame.origin.x += kImageOriginXOffset;
		imageFrame.size = imageSize;
		if ([controlView isFlipped])
			imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
		else
			imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
		[image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
		xOffset += kImageOriginXOffset + imageSize.width;
	}
	cellFrame.origin.x += xOffset;
	cellFrame.size.width -= xOffset;
	
	// if this is a small row, use a small font and centralise
	// otherwise use a normal font and draw at the top
	BOOL bigRow = cellFrame.size.height >= 32.0;
	[self setStringValue:[node name]];
	[self setTextColor:[NSColor blackColor]];
	NSFont *myFont;
	if (bigRow) {
		myFont = [NSFont controlContentFontOfSize:
				  [NSFont systemFontSizeForControlSize:NSRegularControlSize]];
	} else {
		myFont = [NSFont controlContentFontOfSize:
				  [NSFont systemFontSizeForControlSize:NSSmallControlSize]];
		NSSize s = [[self stringValue] sizeWithAttributes:
					[NSDictionary dictionaryWithObjectsAndKeys:myFont,NSFontAttributeName,nil]];
		cellFrame.origin.y += ceil((cellFrame.size.height - s.height) / 2.0);
		cellFrame.size.height = s.height;
	}
	[self setFont:myFont];
	[super drawWithFrame:cellFrame inView:controlView];
	
	// if a large row, draw the username
	if (bigRow) {
		[self setStringValue:[[node user] name]];
		if ([[NSApp mainWindow] isVisible] && [self isHighlighted]) {
			[self setTextColor:[NSColor lightGrayColor]];
		} else {
			[self setTextColor:[NSColor darkGrayColor]];
		}		
		myFont = [NSFont controlContentFontOfSize:9.0];
		[self setFont:myFont];
		cellFrame.origin.y += kUsernameTextOffset;
		cellFrame.size.height -= kUsernameTextOffset;
		[super drawWithFrame:cellFrame inView:controlView];
	}	
}

@end
