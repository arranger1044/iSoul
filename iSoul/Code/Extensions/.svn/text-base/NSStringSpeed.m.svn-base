//
//  NSStringSpeed.m
//  iSoul
//
//  Created by Richard on 12/11/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "NSStringSpeed.h"


@implementation NSString (Speed)

+ (NSString *)stringForSpeed:(float)speed
{
    if (speed <= 999.95) //0.0 K to 999.9 K
        return [NSString localizedStringWithFormat:@"%.1f KB", speed];
    
    speed /= 1024.0;
    
    if (speed <= 99.995) //0.98 M to 99.99 M
        return [NSString localizedStringWithFormat:@"%.2f MB", speed];
    else if (speed <= 999.95) //100.0 M to 999.9 M
        return [NSString localizedStringWithFormat:@"%.1f MB", speed];
    else //insane speeds
        return [NSString localizedStringWithFormat: @"%.2f GB", (speed / 1024.0f)];
}

+ (NSString *)stringForTime:(float)t
{
	if (t <= 60.0)
		return [NSString stringWithFormat:@"%.0f seconds", t];
	
	// time in minutes
	t /= 60.0;
	
	if (t < 59.995) // 2 mins - 60 mins
		return [NSString stringWithFormat:@"%.0f minutes", t + 1.0];
	
	// time in hours
	t /= 60.0;
	
	if (t < 24.0) // 1.0 - 23.9 hours
		return [NSString stringWithFormat:@"%.1f hours", t];
	else // 1.0 - 999.9 days
		return [NSString stringWithFormat:@"%.1f days", t/24.0];

}


@end
