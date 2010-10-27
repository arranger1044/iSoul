//
//  PathTransformer.m
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "PathTransformer.h"


@implementation PathTransformer

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
	NSString *fullPath = (NSString *)value;
	
	// remove the folder name from the path
	NSRange range = [fullPath rangeOfString:@"\\" options:NSBackwardsSearch];
	if (range.location != NSNotFound) {
		return [fullPath substringFromIndex:(range.location + 1)];
	}
	return fullPath;
}


@end
