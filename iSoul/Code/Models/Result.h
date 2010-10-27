//
//  Result.h
//  iSoul
//
//  Created by Richard on 12/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Ticket;
@class User;

@interface Result :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * bitrate;
@property (nonatomic, retain) NSString * fullPath;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSNumber * vbr;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) Ticket * ticket;
@property (nonatomic, retain) User * user;

@end



