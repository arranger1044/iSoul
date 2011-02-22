//
//  DownloadProgressCell.m
//  iSoul
//
//  Created by Richard on 10/31/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "DownloadProgressCell.h"
#import "Constants.h"
#import "Transfer.h"
#import "User.h"
#import "NSStringSpeed.h"
#import "PathNode.h"

#define kProgressXOffset		10.0
#define	kProgressYOffset		4.0
#define kCaptionHeight			13.0
#define kCaptionYOffset			2.0

@implementation DownloadProgressCell

- (void)awakeFromNib
{
	progress = [[NSImage imageNamed:@"Progress"] retain];
	progressComplete = [[NSImage imageNamed:@"Progress_complete"] retain];
	progressInactiveDark = [[NSImage imageNamed:@"Progress_inactive_dark"] retain];
	progressInactiveLight = [[NSImage imageNamed:@"Progress_inactive_light"] retain];
	progressCap = [[NSImage imageNamed:@"ProgressCaps"] retain];
	progressCapComplete = [[NSImage imageNamed:@"ProgressCaps_complete"] retain];
	progressCapInactive = [[NSImage imageNamed:@"ProgressCaps_inactive"] retain];
	progressCapInactiveDark = [[NSImage imageNamed:@"ProgressCaps_dark"] retain];
	
	// set the control font
	NSFont *myFont = [NSFont controlContentFontOfSize:10.0];
	[self setFont:myFont];
	[self setTextColor:[NSColor grayColor]];
}

- (void)dealloc
{
	[progress release];
	[progressComplete release];
	[progressInactiveDark release];
	[progressInactiveLight release];
	[progressCap release];
	[progressCapComplete release];
	[progressCapInactive release];
	[progressCapInactiveDark release];
	
	[super dealloc];
}

- (BOOL)isEditable
{
	return NO;
}

- (id)copyWithZone:(NSZone*)zone
{
    DownloadProgressCell *cell = (DownloadProgressCell*)[super copyWithZone:zone];
    cell->progress = [progress retain];
	cell->progressComplete = [progressComplete retain];
	cell->progressInactiveDark = [progressInactiveDark retain];
	cell->progressInactiveLight = [progressInactiveLight retain];
	cell->progressCap = [progressCap retain];
	cell->progressCapComplete = [progressCapComplete retain];
	cell->progressCapInactive = [progressCapInactive retain];
	cell->progressCapInactiveDark = [progressCapInactiveDark retain];
	
	// set the style
	[cell setFont:[self font]];
	[cell setTextColor:[self textColor]];
	
    return cell;
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
	return NSZeroRect;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	PathNode *node = (PathNode *)[self objectValue];
	
	// display the progress bar in a big row
	// otherwise just the status line
	BOOL bigRow = cellFrame.size.height >= 32.0;
	
	float filePosition, fileSize;
	TransferState state;
	Transfer *activeTransfer = nil;
	if ([node isFolder]) {
		// if we are displaying a folder, we 
		// require all the file sizes adding up
		// and point the transfer to the current
		// active transfer (if any)
		filePosition = fileSize = 0;
		state = 100;
		if ([[node children] count] > 0) 
			activeTransfer = [[[node children] objectAtIndex:0] representedObject];
														   
		for (PathNode *child in [node children]) {
			if (![child isFolder]) {
				Transfer *transfer = [child representedObject];
				filePosition += [[transfer position] floatValue] / 1024.0;
				fileSize += [[transfer size] floatValue] / 1024.0;
				
				// determine the most important state to use
				switch ([[transfer state] unsignedIntValue]) {
					case tfTransferring:
					{
						state = tfTransferring;
						activeTransfer = transfer;
						break;
					}
					case tfAwaitingUser:
					{
						if (!((state == tfRemoteError) || (state == tfLocalError))) {
							state = tfAwaitingUser;
						}
						break;
					}
					case tfRemoteError:
					case tfLocalError:
					{
						if (state != tfTransferring) {
							state = tfRemoteError;
							activeTransfer = transfer;
						}
						break;
					}
					case tfNegotiating:
					case tfWaiting:
					case tfEstablishing:
					case tfInitiating:
					case tfGettingStatus:
					case tfGettingAddress:
					{
						if ((state >= tfQueuedLocally) || 
							(state == tfQueuedRemotely) ||
							(state == tfFinished)) 
							state = tfConnecting;
						break;
					}
					case tfQueuedRemotely:
					{
						if ((state >= tfQueuedLocally) ||
							(state == tfFinished)) {
							state = tfQueuedRemotely;
						}
						break;
					}
					case tfQueuedLocally:
					{
						if ((state > tfQueuedLocally) ||
							(state == tfFinished)) 
							state = tfQueuedLocally;
						break;
					}
					case tfAborted:
					{
						if ((state == tfQueuedRemotely) || 
							(state >= tfQueuedLocally) ||
							(state == tfFinished)) {
							state = tfAborted;
						}
						break;
					}
					case tfFinished:
					{
						if (state > tfQueuedLocally) state = tfFinished;
						break;
					}
				}
			}
		}
		
	} else {
		Transfer *transfer = [node representedObject];
		state = [[transfer state] unsignedIntValue];
		
		// calculate the file size and position in KB
		filePosition =  [[transfer position] floatValue] / 1024.0;
		fileSize = [[transfer size] floatValue] / 1024.0;
		
		activeTransfer = transfer;
	}	
	
	// get the progress and state
	NSImage *startCap = (filePosition > 0) ? 
		progressCapInactiveDark : progressCapInactive;
	NSImage *endCap = progressCapInactive;
	NSImage *bar = progressInactiveDark;
	NSMutableString *caption = [[NSMutableString alloc] init];
	
	// first add the progress caption
	if (bigRow || ((filePosition > 0) && (state != tfFinished))) {
		[caption appendFormat:@"%@ of %@ - ",
		 [NSString stringForSpeed:filePosition],
		 [NSString stringForSpeed:fileSize]];
	}
	
	switch (state) 
	{
		case tfFinished:
		{
			startCap = progressCapComplete;
			endCap = progressCapComplete;
			bar = progressComplete;
			[caption appendString:@"Complete"];
			break;
		}
		case tfTransferring:
		{
			startCap = progressCap;
			bar = progress;
			
			// remove the last two characters
			if ([caption length] > 2) {
				NSRange range;
				range.location = [caption length] - 2;
				range.length = 2;
				[caption deleteCharactersInRange:range];
			}
			
			// calculate the transfer rate in KB/s
			float rate = [[activeTransfer rate] floatValue] / 1024.0;
			if (rate <= 0) break;
			
			// calculate the time remaining in seconds
			float timeRemaining = (fileSize - filePosition) / rate;
			[caption appendFormat:@"(%1.1f KB/s) - %@ remaining", rate, 
			 [NSString stringForTime:timeRemaining]];
		
			break;
		}
		case tfQueuedRemotely:
		{
			[caption appendString:@"Queued Remotely"];
			uint32_t placeInQueue = [[activeTransfer placeInQueue] unsignedIntValue];
			// queue position is 0 if unknown
			if (placeInQueue > 0) {
				[caption appendFormat:@", Position %u", placeInQueue];
			} 
			break;
		}
		case tfQueuedLocally:
		{
			[caption appendString:@"Queued Locally"];
			break;
		}
		case tfNegotiating:
        {
			[caption appendString:@"Negotiating..."];
			break;
		}
		case tfEstablishing:
		case tfInitiating:
        {
			[caption appendString:@"Initiating Transfer"];
			break;
		}
		case tfConnecting:
        {
			[caption appendString:@"Connecting..."];
			break;
		}
		case tfGettingAddress:
		case tfGettingStatus:
		{
			[caption appendString:@"Connecting"];
			break;
		}
		case tfAwaitingUser:
		{
			[caption appendString:@"User is Offline"];
			break;
		}
		case tfAborted:
		{
			[caption appendString:@"Aborted"];
			break;
		}
		case tfCannotConnect:
        {
			[caption appendString:@"Cannot connect"];
			break;
		}
		case tfConnectionClosed:
		{
			[caption appendString:@"Cannot connect - Connection Closed"];
			break;
		}
		case tfRemoteError:
        {
			[caption appendFormat:@"Error - %@",[activeTransfer error]];
			break;
		}
		case tfLocalError:
		{
			[caption appendFormat:@"Error - %@",[activeTransfer error]];
			break;
		}
		default:
		{
			break;
		}
	}
	
	// now draw the progress slider if this is a big row
	int barWidth = cellFrame.size.width - 2 * kProgressXOffset - 1;
	if (bigRow) {
		NSSize imageSize = [progress size];
		NSPoint capPoint = NSMakePoint(cellFrame.origin.x + kProgressXOffset, 
									   cellFrame.origin.y + kProgressYOffset + imageSize.height);
		[startCap compositeToPoint:capPoint operation:NSCompositeSourceOver];
		capPoint.x = cellFrame.origin.x + cellFrame.size.width - kProgressXOffset;
		[endCap compositeToPoint:capPoint operation:NSCompositeSourceOver];
		
		// shrink the width to fit the bar
		float width = (float)barWidth;
		if (fileSize > 0) {
			width *= (filePosition / fileSize);
		} else {
			width = 0;
		}		
		NSRect barRect = NSMakeRect(cellFrame.origin.x + kProgressXOffset + 1,
									cellFrame.origin.y + kProgressYOffset,
									(int)width,
									imageSize.height);
		
		[bar drawInRect:barRect 
			   fromRect:NSZeroRect 
			  operation:NSCompositeSourceOver 
			   fraction:1.0];
		
		// now draw the remainder of the bar
		barRect.origin.x += barRect.size.width;
		barRect.size.width = barWidth - barRect.size.width;
		[progressInactiveLight drawInRect:barRect 
								 fromRect:NSZeroRect 
								operation:NSCompositeSourceOver 
								 fraction:1.0];
		
		// jig the cell frame to show the caption at the correct height
		cellFrame.origin.y += kProgressYOffset + imageSize.height;
	}
	
	
	// now draw the comment
	NSRect newFrame = cellFrame;
	newFrame.origin.x += kProgressXOffset;
	newFrame.origin.y += kCaptionYOffset;
	newFrame.size.width = barWidth + kProgressXOffset;
	newFrame.size.height = kCaptionHeight;
	if ([[NSApp mainWindow] isVisible] && [self isHighlighted]) {
		[self setTextColor:[NSColor lightGrayColor]];
	} else {
		[self setTextColor:[NSColor darkGrayColor]];
	}
	[self setStringValue:caption];
	[super drawWithFrame:newFrame inView:controlView];	
}

@end
