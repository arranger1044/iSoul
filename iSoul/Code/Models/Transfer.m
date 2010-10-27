// 
//  Transfer.m
//  iSoul
//
//  Created by Richard on 12/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Transfer.h"

#import "User.h"

@implementation Transfer 

@dynamic placeInQueue;
@dynamic size;
@dynamic path;
@dynamic position;
@dynamic state;
@dynamic rate;
@dynamic error;
@dynamic isUpload;
@dynamic user;

- (id)copyWithZone:(NSZone*)zone
{
	return [self retain];
}


@end
