//
//  CountryNameTransformer.m
//  iSoul
//
//  Created by Richard on 1/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CountryNameTransformer.h"


@implementation CountryNameTransformer

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
	NSString *countryCode = (NSString *)value;
	
	NSLocale *locale = [NSLocale currentLocale];	
    return [locale displayNameForKey:NSLocaleCountryCode
							   value:countryCode];	
}


@end
