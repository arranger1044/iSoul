//
//  NSImageSection.m
//  iSoul
//
//  Created by Richard on 11/17/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "NSImageSection.h"


@implementation NSImage (ImageSection)

+ (NSImage *)imageWithRect:(NSRect)rect ofImage:(NSImage *)original;
{
	NSPoint zero = { 0.0, 0.0 };
	NSImage *result = [[self alloc] initWithSize:rect.size];
	
	[result lockFocus];
	[original compositeToPoint:zero fromRect:rect 
					 operation:NSCompositeCopy];
	[result unlockFocus];
	return [result autorelease];
}

@end
