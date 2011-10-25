//
//  FilesizeTransformer.m
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "FilesizeTransformer.h"


@implementation FilesizeTransformer

+ (Class)transformedValueClass {
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

+ (void)initialize {
	NSString *name = @"FilesizeTransformer";
	
	[NSValueTransformer.class setValueTransformer:[[self new] autorelease] forName:name];
}

- (id)transformedValue:(id)value {
	NSNumber *fileSize = (NSNumber *)value;
	
	if (!fileSize) return @"";
	
	uint32_t intSize = [fileSize unsignedIntValue];
	float floatSize = [fileSize floatValue];
	
	if (intSize == 0)
		return @"";
	else if (intSize == 1)
		return @"1 byte";
	else if (intSize < 1000.0)
		return [NSString stringWithFormat:@"%d bytes", intSize];
	else if (intSize < 1000.0 * 1000.0)
		return [NSString stringWithFormat:@"%1.0f KB", floatSize / 1000.0];
	else if (intSize < 1000.0 * 1000.0 * 1000.0)
		return [NSString stringWithFormat:@"%1.1f MB", floatSize / (1000.0 * 1000.0)];
	else
		return [NSString stringWithFormat:@"%1.1f GB", floatSize / (1000.0 * 1000.0 * 1000.0)];
	
}

@end
