//
//  BubbleTextView.h
//  iSoul
//
//  Created by Richard on 12/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class User;

@interface BubbleTextView : NSTextView {
	NSMutableParagraphStyle *statusParagraphStyle;
	NSDictionary *usernameAttributes;
	NSImage *personIcon;
	NSArray *blueBalloon;
	NSArray *balloons;
	NSMutableDictionary *userColours;
	NSUInteger balloonIndex;
    NSDateFormatter * formatter;
}

@property (retain) NSMutableParagraphStyle *statusParagraphStyle;

- (NSArray *)balloonTileArray:(NSImage *)balloon;
- (BOOL)lastMessageVisible;
- (void)drawBubbleAroundTextInRect:(NSRect)rect user:(User *)user outgoing:(BOOL)outgoing;

@end
