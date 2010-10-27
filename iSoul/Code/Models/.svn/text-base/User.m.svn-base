// 
//  User.m
//  iSoul
//
//  Created by Richard on 1/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "User.h"

#import "ChatMessage.h"
#import "Result.h"
#import "Room.h"
#import "Ticker.h"
#import "Transfer.h"
#import "Constants.h"

@implementation User 

@dynamic icon;
@dynamic numberOfFiles;
@dynamic browseListReceived;
@dynamic hasFreeSlots;
@dynamic name;
@dynamic info;
@dynamic queueLength;
@dynamic numberOfDownloads;
@dynamic country;
@dynamic numberOfUploads;
@dynamic isBanned;
@dynamic averageSpeed;
@dynamic picture;
@dynamic isFriend;
@dynamic status;
@dynamic transfers;
@dynamic tickers;
@dynamic files;
@dynamic rooms;
@dynamic messages;

- (id)copyWithZone:(NSZone*)zone
{
	return [self retain];
}

- (NSUInteger)queueTime
{
	// if there are slots available, then no q
	[self willAccessValueForKey:@"hasFreeSlots"];
	NSNumber *freeSlots = [self hasFreeSlots];
	[self didAccessValueForKey:@"hasFreeSlots"];
	if ([freeSlots boolValue]) return 0;
	
	// estimate the q time on an average file size
	[self willAccessValueForKey:@"averageSpeed"];
	NSNumber *speed = [self averageSpeed];
	[self didAccessValueForKey:@"averageSpeed"];
	[self willAccessValueForKey:@"queueLength"];
	NSNumber *queueLength = [self queueLength];
	[self didAccessValueForKey:@"queueLength"];
	
	return ([queueLength unsignedIntValue] * kAverageFileSize) / 
	([speed unsignedIntValue] + 1); // add 1 to prevent /0  
}


@end
