//
//  SpeedTransformer.m
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "SpeedTransformer.h"
#import "NSStringSpeed.h"

@implementation SpeedTransformer

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
	NSNumber *averageSpeed = (NSNumber *)value;
	
	if (!averageSpeed) return @"";
	
	float kbpsSpeed = averageSpeed.floatValue / 1000.0f;
	return [NSString stringForSpeed:kbpsSpeed];
}


@end
