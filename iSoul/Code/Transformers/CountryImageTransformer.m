//
//  CountryTransformer.m
//  iSoul
//
//  Created by Richard on 12/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CountryImageTransformer.h"


@implementation CountryImageTransformer

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
	NSString *country = (NSString *)value;
	
	return [NSImage imageNamed:[country lowercaseString]];	
}

@end
