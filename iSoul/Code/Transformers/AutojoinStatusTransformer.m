//
//  AutojoinStatusTransformer.m
//  iSoul
//
//  Created by valerio on 29/01/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "AutojoinStatusTransformer.h"

@implementation AutojoinStatusTransformer

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
	BOOL status = [(NSNumber *)value boolValue];
	
	NSImage * statusImage = nil;

    if (status) 
    {
        statusImage = [NSImage imageNamed:@"autojoin.png"];
    }
    
	return statusImage;
}

@end
