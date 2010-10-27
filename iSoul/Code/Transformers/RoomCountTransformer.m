//
//  RoomCountTransformer.m
//  iSoul
//
//  Created by Richard on 11/26/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "RoomCountTransformer.h"


@implementation RoomCountTransformer

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
	
	if ([number unsignedIntValue] == 1) {
		return @"1 User In Room";
	} else {
		return [NSString stringWithFormat:@"%@ Users In Room",number];
	}
}

@end
