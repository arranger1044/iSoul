//
//  StatusTransformer.m
//  iSoul
//
//  Created by Richard on 12/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "StatusTransformer.h"
#import "Constants.h"

@implementation StatusTransformer

+ (Class)transformedValueClass 
{
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	NSNumber *status = (NSNumber *)value;
	
	NSImage *statusImage = nil;
	switch ([status unsignedIntValue]) {
		case usOffline:
		{
			statusImage = [NSImage imageNamed:@"StatusOffline"];
			break;
		}
		case usOnline:
		{
			statusImage = [NSImage imageNamed:@"StatusOnline"];
			break;
		}
		case usAway:
		{
			statusImage = [NSImage imageNamed:@"StatusAway"];
			break;
		}						
	}
	return statusImage;
}


@end
