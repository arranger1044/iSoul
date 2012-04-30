//
//  BubbleTextView.m
//  iSoul
//
//  Created by Richard on 12/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BubbleTextView.h"
#import "NSImageSection.h"
#import "User.h"

#define kIconBuffer			10.0
#define kIconSize			32.0
#define kUsernameHeight		15.0

#define kBalloonPadLeft		13.0
#define kBalloonPadRight	6.0
#define kBalloonPadTop		3.0
#define kBalloonPadBottom	6.0

#define kBalloonHeight		46.0
#define kBalloonWidth		77.0
#define kBalloonTail		19.0
#define kBalloonEnd			10.0
#define kBalloonBottom		14.0
#define kBalloonTop			9.0

@implementation BubbleTextView
@synthesize statusParagraphStyle;

- (void)awakeFromNib
{
	// set the default paragraph style to be cloned
	// this is for messages in bubbles
	NSMutableParagraphStyle *messageStyle = [[NSParagraphStyle
											  defaultParagraphStyle] mutableCopy];
	NSMutableParagraphStyle *statusStyle = [[NSParagraphStyle 
											 defaultParagraphStyle] mutableCopy];
	
    [messageStyle setParagraphSpacingBefore:kBalloonTop];
    [messageStyle setParagraphSpacing:kUsernameHeight + kBalloonBottom];
    [self setDefaultParagraphStyle:messageStyle];
    [self setTypingAttributes:[NSDictionary
							   dictionaryWithObjectsAndKeys:
							   messageStyle, NSParagraphStyleAttributeName, 
							   [NSFont userFontOfSize:13.0], NSFontAttributeName, nil]];
	[messageStyle release];
	
	// this paragraph style is for status messages
	[statusStyle setAlignment:NSCenterTextAlignment];
	[self setStatusParagraphStyle:statusStyle];
	[statusStyle release];
	
    // Make sure there's some extra room around the text container
    [self setTextContainerInset:NSMakeSize(2 * kIconBuffer + kIconSize + kBalloonPadLeft,
										   20.0)];

	
	// set the username style
	usernameAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSFont controlContentFontOfSize:10],NSFontAttributeName,
						  [NSColor grayColor],NSForegroundColorAttributeName,nil];
	[usernameAttributes retain];
	
	// preload and tile the bubble images
	blueBalloon = [[self balloonTileArray:[NSImage imageNamed:@"Balloon_8107502"]] retain];
	personIcon = [[NSImage imageNamed:@"PrefAccount"] retain];
	balloons = [[NSArray alloc] initWithObjects:
				[self balloonTileArray:[NSImage imageNamed:@"Balloon_11318719"]],
				[self balloonTileArray:[NSImage imageNamed:@"Balloon_12641896"]],
				[self balloonTileArray:[NSImage imageNamed:@"Balloon_13216486"]],
				[self balloonTileArray:[NSImage imageNamed:@"Balloon_15109309"]],
				[self balloonTileArray:[NSImage imageNamed:@"Balloon_15246896"]],
				[self balloonTileArray:[NSImage imageNamed:@"Balloon_15461355"]],
				[self balloonTileArray:[NSImage imageNamed:@"Balloon_16047647"]],nil];
	balloonIndex = 0;	
	userColours = [[NSMutableDictionary alloc] init];
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
}

- (void)dealloc
{
	[userColours release];
	[blueBalloon release];
	[personIcon release];
	[balloons release];
	[usernameAttributes release];
    [formatter release];
	[super dealloc];
}

// splits a balloon image into its 9 part tile 
// components, to be used in NSDrawNinePartImage
- (NSArray *)balloonTileArray:(NSImage *)balloon
{
	NSRect r = NSMakeRect(0, kBalloonHeight - kBalloonTop, kBalloonTail, kBalloonTop);
	NSImage *tl = [NSImage imageWithRect:r ofImage:balloon];
	
	r.origin.y = kBalloonBottom; 
	r.size.height = kBalloonHeight - kBalloonTop - kBalloonBottom;
	NSImage *le = [NSImage imageWithRect:r ofImage:balloon];
	
	r.origin.x = 0; r.origin.y = 0; r.size.height = kBalloonBottom;
	NSImage *bl = [NSImage imageWithRect:r ofImage:balloon];
	
	r.origin.x = kBalloonTail; r.size.width = 1;
	NSImage *be = [NSImage imageWithRect:r ofImage:balloon];
	
	r.origin.y = kBalloonBottom; 
	r.size.height = kBalloonHeight - kBalloonTop - kBalloonBottom;
	NSImage *cf = [NSImage imageWithRect:r ofImage:balloon];
	
	r.origin.y = kBalloonHeight - kBalloonTop;
	r.size.height = kBalloonTop;
	NSImage *te = [NSImage imageWithRect:r ofImage:balloon];
	
	r.origin.x = kBalloonWidth - kBalloonEnd;
	r.size.width = kBalloonEnd;
	NSImage *tr = [NSImage imageWithRect:r ofImage:balloon];
	
	r.origin.y = kBalloonBottom;
	r.size.height = kBalloonHeight - kBalloonTop - kBalloonBottom;
	NSImage *re = [NSImage imageWithRect:r ofImage:balloon];
	
	r.origin.y = 0;
	r.size.height = kBalloonBottom;
	NSImage *br = [NSImage imageWithRect:r ofImage:balloon];
	
	return [NSArray arrayWithObjects:
			tl,te,tr,le,cf,re,bl,be,br,nil];
}

- (void)setNeedsDisplayInRect:(NSRect)rect avoidAdditionalLayout:(BOOL)flag
{
	// need to pad the top and bottom of the redraw rectangle
	// so that the balloon surround is drawn
	rect.origin.y -= kIconSize / 2;
	rect.size.height += kIconSize;
	[super setNeedsDisplayInRect:rect avoidAdditionalLayout:flag];
}

- (void)drawBubbleAroundTextInRect:(NSRect)rect user:(User *)user outgoing:(BOOL)outgoing timestamp:(NSDate *)timestamp
{
	NSArray *balloon;	
	NSAffineTransform *aft = [NSAffineTransform transform];
	if (outgoing) {
		balloon = blueBalloon;
		
		// if outgoing, flip the co-ordinates for the balloon		
		[aft scaleXBy:-1.0f yBy:1.0f];
		[aft translateXBy:-(2.0f * rect.origin.x + rect.size.width) yBy:0];
		[aft concat];
	} else {
		// check if the balloon colour has been cached
		NSNumber *colourIndex = [userColours objectForKey:user];
		
		if (!colourIndex) {
			// the user has not been seen before
			// so give him a new colour and store in the dictionary
			balloon = [balloons objectAtIndex:balloonIndex];
			[userColours setObject:[NSNumber numberWithUnsignedInt:(unsigned) balloonIndex] 
						   forKey:user];		
			balloonIndex = (balloonIndex + 1) % [balloons count];
		} else {
			// already picked a colour for this user
			balloon = [balloons objectAtIndex:[colourIndex unsignedIntValue]];
		}		
	}
		
	// adjust the paragraph rectangle to contain the balloon
	NSRect balloonRect = NSMakeRect(rect.origin.x - kBalloonPadLeft, 
									rect.origin.y - kBalloonPadTop, 
									rect.size.width + kBalloonPadLeft + kBalloonPadRight, 
									rect.size.height + kBalloonPadTop + kBalloonPadBottom);
	
	// now draw the icon, will not be flipped
	NSImage *icon;
	if ([user icon]) 
    {
		icon = [[NSImage alloc] initWithData:[user icon]];
        //icon = [user icon];
		[icon autorelease];
	} 
    else 
    {
		icon = [NSImage imageNamed:@"PrefAccount"];
	}	
	NSPoint iconOrigin = NSMakePoint(balloonRect.origin.x - kIconBuffer - kIconSize, 
									 balloonRect.origin.y + balloonRect.size.height);
	if (outgoing) iconOrigin.x += kIconSize;
	[icon compositeToPoint:iconOrigin
				 operation:NSCompositeSourceOver];
	
	// flip the view upside down so the images display correctly in 10.5
	NSAffineTransform *flipTransform = [NSAffineTransform transform];
	[flipTransform scaleXBy:1.0f yBy:-1.0f];
	[flipTransform translateXBy:0.0 yBy:-(2.0f * balloonRect.origin.y + balloonRect.size.height)];
	[flipTransform concat];
	
	// bottom left
	NSRect plotRect = NSMakeRect(balloonRect.origin.x, 
								 balloonRect.origin.y, 
								 kBalloonTail, kBalloonBottom);
	[(NSImage *)[balloon objectAtIndex:6] drawInRect:plotRect 
											fromRect:NSZeroRect 
										   operation:NSCompositeSourceOver 
											fraction:1.0f];
	
	// bottom middle
	plotRect.origin.x += plotRect.size.width;
	plotRect.size.width = balloonRect.size.width - kBalloonTail - kBalloonEnd;
	[(NSImage *)[balloon objectAtIndex:7] drawInRect:plotRect 
											fromRect:NSZeroRect 
										   operation:NSCompositeSourceOver 
											fraction:1.0f];
	
	// bottom right
	plotRect.origin.x += plotRect.size.width;
	plotRect.size.width = kBalloonEnd;
	[(NSImage *)[balloon objectAtIndex:8] drawInRect:plotRect 
											fromRect:NSZeroRect 
										   operation:NSCompositeSourceOver 
											fraction:1.0f];
	
	// middle left
	plotRect.origin.x = balloonRect.origin.x;
	plotRect.origin.y = balloonRect.origin.y + kBalloonBottom;
	plotRect.size.width = kBalloonTail;
	plotRect.size.height = balloonRect.size.height - kBalloonBottom - kBalloonTop;
	[(NSImage *)[balloon objectAtIndex:3] drawInRect:plotRect 
											fromRect:NSZeroRect 
										   operation:NSCompositeSourceOver 
											fraction:1.0f];
	
	// middle
	plotRect.origin.x += plotRect.size.width;
	plotRect.size.width = balloonRect.size.width - kBalloonTail - kBalloonEnd;
	[(NSImage *)[balloon objectAtIndex:4] drawInRect:plotRect 
											fromRect:NSZeroRect 
										   operation:NSCompositeSourceOver 
											fraction:1.0f];
	
	// middle right
	plotRect.origin.x += plotRect.size.width;
	plotRect.size.width = kBalloonEnd;
	[(NSImage *)[balloon objectAtIndex:5] drawInRect:plotRect 
											fromRect:NSZeroRect 
										   operation:NSCompositeSourceOver 
											fraction:1.0f];
	
	// top left
	plotRect.origin.x = balloonRect.origin.x;
	plotRect.origin.y = balloonRect.origin.y + balloonRect.size.height - kBalloonTop;
	plotRect.size.width = kBalloonTail;
	plotRect.size.height = kBalloonTop;
	[(NSImage *)[balloon objectAtIndex:0] drawInRect:plotRect 
											fromRect:NSZeroRect 
										   operation:NSCompositeSourceOver 
											fraction:1.0f];
	
	// top middle
	plotRect.origin.x += plotRect.size.width;
	plotRect.size.width = balloonRect.size.width - kBalloonTail - kBalloonEnd;
	[(NSImage *)[balloon objectAtIndex:1] drawInRect:plotRect 
											fromRect:NSZeroRect 
										   operation:NSCompositeSourceOver 
											fraction:1.0f];
	
	// top right
	plotRect.origin.x += plotRect.size.width;
	plotRect.size.width = kBalloonEnd;
	[(NSImage *)[balloon objectAtIndex:2] drawInRect:plotRect 
											fromRect:NSZeroRect 
										   operation:NSCompositeSourceOver 
											fraction:1.0f];
	
	[flipTransform invert];
	[flipTransform concat];
    
	[aft invert];
	[aft concat];
    
    
   
    // now draw the timestamp
    
    NSRect timestampRect;
    if (outgoing)
    {
        timestampRect = NSMakeRect(self.frame.origin.x + 10, balloonRect.origin.y + balloonRect.size.height / 2, 50, 30);
    }
    else
    {
        timestampRect = NSMakeRect(self.frame.size.width - 55, balloonRect.origin.y + balloonRect.size.height / 2, 50, 30);
    }
    
    NSString * dateString;
    
    dateString = [formatter stringFromDate:timestamp];
    
    [dateString drawInRect:timestampRect withAttributes:usernameAttributes];
	
	// now draw the username
    NSRect ourFrame = [self frame];
	NSRect usernameRect;
	NSSize usernameSize = [[user name] sizeWithAttributes:usernameAttributes];
	
	if (outgoing) {				
		CGFloat endPoint = ourFrame.origin.x + ourFrame.size.width - kIconBuffer;
		CGFloat startPoint = MAX(ourFrame.origin.x + kIconBuffer, endPoint - usernameSize.width);
		usernameRect = NSMakeRect(startPoint, iconOrigin.y, endPoint - startPoint, kUsernameHeight);
	} else {
		usernameRect = NSMakeRect(iconOrigin.x, iconOrigin.y, 
								  MIN(usernameSize.width, ourFrame.size.width - kIconBuffer), 
								  kUsernameHeight);
	}
	[[user name] drawInRect:usernameRect withAttributes:usernameAttributes];
    
}

- (void)drawViewBackgroundInRect:(NSRect)rect 
{
    NSLayoutManager *layoutManager = [self layoutManager];
    NSPoint containerOrigin = [self textContainerOrigin];
    NSRange glyphRange, charRange, paragraphCharRange,
	paragraphGlyphRange, lineGlyphRange;
    NSRect paragraphRect, lineUsedRect;
	
    // Draw the background first, before the bubbles.
    [super drawViewBackgroundInRect:rect];
	
    // Convert from view to container coordinates, then to the
	// corresponding glyph and character ranges
    rect.origin.x -= containerOrigin.x;
    rect.origin.y -= containerOrigin.y;
    glyphRange = [layoutManager glyphRangeForBoundingRect:rect
										  inTextContainer:[self textContainer]];
    charRange = [layoutManager
				 characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
	
    // Iterate through the character range, paragraph by paragraph.
    for (paragraphCharRange = NSMakeRange(charRange.location, 0);
		 NSMaxRange(paragraphCharRange) < NSMaxRange(charRange);
		 paragraphCharRange = NSMakeRange(NSMaxRange(paragraphCharRange), 0)) {
        
		// For each paragraph, find the corresponding 
		// character and glyph ranges
        paragraphCharRange = [[[self textStorage] string]
							  paragraphRangeForRange:paragraphCharRange];
        paragraphGlyphRange = [layoutManager
							   glyphRangeForCharacterRange:paragraphCharRange
							   actualCharacterRange:NULL];
        paragraphRect = NSZeroRect;
		
		// get the user attribute for the paragraph
		User *user = [[self textStorage] attribute:@"User" 
										   atIndex:paragraphCharRange.location 
									effectiveRange:NULL];
		NSNumber *isOutgoing = [[self textStorage] attribute:@"Outgoing" 
													 atIndex:paragraphCharRange.location 
											  effectiveRange:NULL];
		NSNumber *isStatusMsg = [[self textStorage] attribute:@"StatusMessage" 
													  atIndex:paragraphCharRange.location 
											   effectiveRange:NULL];
        NSDate * timestamp = [[self textStorage] attribute:@"Timestamp" 
                                                   atIndex:paragraphCharRange.location 
                                            effectiveRange:NULL];
        NSNumber * isEventMsg = [[self textStorage] attribute:@"EventMessage" 
                                                     atIndex:paragraphCharRange.location 
                                              effectiveRange:NULL];
		
        // Iterate through the paragraph glyph range, line by line.
        for (lineGlyphRange = NSMakeRange(paragraphGlyphRange.location, 0); 
			 NSMaxRange(lineGlyphRange) < NSMaxRange(paragraphGlyphRange); 
			 lineGlyphRange = NSMakeRange(NSMaxRange(lineGlyphRange), 0)) {
            
			// For each line, find the used rect and glyph range,
			// and add the used rect to the paragraph rect
            lineUsedRect = [layoutManager
							lineFragmentUsedRectForGlyphAtIndex:lineGlyphRange.location
							effectiveRange:&lineGlyphRange];
            paragraphRect = NSUnionRect(paragraphRect, lineUsedRect);
        }
		
        // Convert back from container to view coordinates, 
		// then draw the bubble
		paragraphRect.origin.x += containerOrigin.x;
		paragraphRect.origin.y += containerOrigin.y;
		if (![isStatusMsg boolValue] && ![isEventMsg boolValue]) 
        {
			[self drawBubbleAroundTextInRect:paragraphRect 
										user:user 
									outgoing:[isOutgoing boolValue]
                                   timestamp:timestamp];
		}		
    }
}

- (BOOL)lastMessageVisible
{
	NSRect visibleRect = [self visibleRect];
	return (visibleRect.origin.y + visibleRect.size.height) > ([self frame].size.height - 3 * kIconSize);
}

- (void)setSelectedRanges:(NSArray *)ranges affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag
{
	// need to check each of the ranges to make sure that 
	// there is no selection occurring across a paragraph
	NSMutableArray *cutRanges = [[NSMutableArray alloc] init];
	NSRange selectionRange, paragraphRange, cutRange;
	for (NSValue *val in ranges) {
		selectionRange = [val rangeValue];
		paragraphRange = [[[self textStorage] string]
						  paragraphRangeForRange:NSMakeRange(selectionRange.location, 0)];
		
		if (selectionRange.length > 0) {
			while (NSMaxRange(selectionRange) > NSMaxRange(paragraphRange)) {
				cutRange = selectionRange;
				cutRange.length -= NSMaxRange(selectionRange) - NSMaxRange(paragraphRange) + 1;
				[cutRanges addObject:[NSValue valueWithRange:cutRange]];
				NSUInteger charsToSkip = NSMaxRange(paragraphRange) - selectionRange.location;
				selectionRange.location += charsToSkip;
				selectionRange.length -= charsToSkip;
				paragraphRange = [[[self textStorage] string]
								  paragraphRangeForRange:NSMakeRange(selectionRange.location, 0)];
			}
			
			if (NSMaxRange(selectionRange) == NSMaxRange(paragraphRange)) {
				selectionRange.length--;
			}
		}			

		// add the final range, a subsection of a paragraph
		[cutRanges addObject:[NSValue valueWithRange:selectionRange]];
	}	
	
	[super setSelectedRanges:cutRanges affinity:affinity stillSelecting:stillSelectingFlag];
	[cutRanges release];
}

@end
