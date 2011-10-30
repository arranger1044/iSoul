//
//  DataImageTransformer.m
//  iSoul
//
//  Created by David Jennes on 30/10/11.
//  Copyright (c) 2011. All rights reserved.
//

#import "DataImageTransformer.h"

@implementation DataImageTransformer

+ (Class) transformedValueClass {
	return [NSImage class];
}

+ (BOOL) allowsReverseTransformation {
	return YES;
}

- (id) transformedValue: (id) value {
	if (value == nil) return nil;
	if (![value isKindOfClass: [NSData class]]) return nil;
	
	NSImage *image = [[NSImage alloc] initWithData: value];
	
	return [image autorelease];
}

- (id) reverseTransformedValue: (id) value {
	if (value == nil) return nil;
	if (![value isKindOfClass: [NSImage class]]) return nil;
	
	return [(NSImage *) value TIFFRepresentation];
}

@end
