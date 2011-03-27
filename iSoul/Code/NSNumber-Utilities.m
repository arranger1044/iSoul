//
//  NSNumber-Utilities.m
//  iSoul
//
//  Created by David Jennes on 28/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSNumber-Utilities.h"

@implementation NSNumber (Utilities)

- (NSString *)humanReadableBase10 {
    if (self == nil) return nil;
	
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumFractionDigits:1];
	
    NSString *formattedString = nil;
    uint64_t size = [self unsignedLongLongValue];
    if (size < 1000) {
        NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size]];
        formattedString = [NSString stringWithFormat:@"%@ B", formattedNumber];
    }
    else if (size < 1000 * 1000) {
        NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1000.0]];
        formattedString = [NSString stringWithFormat:@"%@ KB", formattedNumber];
    }
    else if (size < 1000 * 1000 * 1000) {
        NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1000.0 / 1000.0]];
        formattedString = [NSString stringWithFormat:@"%@ MB", formattedNumber];
    }
    else {
        NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1000.0 / 1000.0 / 1000.0]];
        formattedString = [NSString stringWithFormat:@"%@ GB", formattedNumber];
    }
    [formatter release];
	
    return formattedString;
}

- (NSString *)humanReadableBase2 {
    if (self == nil)
        return nil;
	
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumFractionDigits:1];
	
    NSString *formattedString = nil;
    uint64_t size = [self unsignedLongLongValue];
    if (size < 1024) {
        NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size]];
        formattedString = [NSString stringWithFormat:@"%@ B", formattedNumber];
    }
    else if (size < 1024 * 1024) {
        NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1024.0]];
        formattedString = [NSString stringWithFormat:@"%@ KB", formattedNumber];
    }
    else if (size < 1024 * 1024 * 1024) {
        NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1024.0 / 1024.0]];
        formattedString = [NSString stringWithFormat:@"%@ MB", formattedNumber];
    }
    else {
        NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1024.0 / 1024.0 / 1024.0]];
        formattedString = [NSString stringWithFormat:@"%@ GB", formattedNumber];
    }
    [formatter release];
	
    return formattedString;
}

@end
