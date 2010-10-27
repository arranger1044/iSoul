//
//  ChatMessage.h
//  iSoul
//
//  Created by Richard on 12/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Room;
@class User;

@interface ChatMessage :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * isPrivate;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Room * room;
@property (nonatomic, retain) User * user;

@end



