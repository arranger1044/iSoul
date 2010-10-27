//
//  EveryoneOrFriendTransformer.m
//  iSoul
//
//  Created by Richard on 12/10/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "EveryoneOrFriendTransformer.h"


@implementation EveryoneOrFriendTransformer

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
	BOOL isBuddyShare = [value boolValue];
	
	if (isBuddyShare) {
		return @"Friends";
	} else {
		return @"Everyone";
	}
}


@end
