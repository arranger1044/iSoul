//
//  BitrateTransformer.m
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "BitrateTransformer.h"


@implementation BitrateTransformer

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
	NSNumber *bitrate = (NSNumber *)value;
	
	if ([bitrate intValue] > 1411) {
		// some badly scanned files are reported
		// with very large bitrates, so ignore
		return @"";
	}
	if ([bitrate intValue] > 0) {
		return [NSString stringWithFormat:@"%@ kbps",bitrate]; 
	}
	return @"";
}

@end
