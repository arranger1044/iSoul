//
//  NoZeroTransformer.m
//  iSoul
//
//  Created by Richard on 11/18/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "NoZeroTransformer.h"


@implementation NoZeroTransformer

+ (Class)transformedValueClass 
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	NSNumber *number = (NSNumber *)value;
	
	if ([number unsignedIntValue] == 0) {
		return nil;
	} else {
		return [number stringValue];
	}
}

@end
