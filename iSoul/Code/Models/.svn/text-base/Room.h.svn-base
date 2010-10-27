//
//  Room.h
//  iSoul
//
//  Created by Richard on 12/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ChatMessage;
@class Ticker;
@class User;

@interface Room :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * numberOfUsers;
@property (nonatomic, retain) NSNumber * joined;
@property (nonatomic, retain) NSNumber * isPrivate;
@property (nonatomic, retain) NSSet* messages;
@property (nonatomic, retain) NSSet* users;
@property (nonatomic, retain) NSSet* tickers;

@end


@interface Room (CoreDataGeneratedAccessors)
- (void)addMessagesObject:(ChatMessage *)value;
- (void)removeMessagesObject:(ChatMessage *)value;
- (void)addMessages:(NSSet *)value;
- (void)removeMessages:(NSSet *)value;

- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSSet *)value;
- (void)removeUsers:(NSSet *)value;

- (void)addTickersObject:(Ticker *)value;
- (void)removeTickersObject:(Ticker *)value;
- (void)addTickers:(NSSet *)value;
- (void)removeTickers:(NSSet *)value;

@end

