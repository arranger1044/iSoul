//
//  User.h
//  iSoul
//
//  Created by Richard on 1/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ChatMessage;
@class Result;
@class Room;
@class Ticker;
@class Transfer;

@interface User :  NSManagedObject  
{
}

@property (nonatomic, retain) NSData * icon;
@property (nonatomic, retain) NSNumber * numberOfFiles;
@property (nonatomic, retain) NSNumber * browseListReceived;
@property (nonatomic, retain) NSNumber * hasFreeSlots;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSNumber * queueLength;
@property (nonatomic, retain) NSNumber * numberOfDownloads;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSNumber * numberOfUploads;
@property (nonatomic, retain) NSNumber * isBanned;
@property (nonatomic, retain) NSNumber * averageSpeed;
@property (nonatomic, retain) NSData * picture;
@property (nonatomic, retain) NSNumber * isFriend;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSSet* transfers;
@property (nonatomic, retain) NSSet* tickers;
@property (nonatomic, retain) NSSet* files;
@property (nonatomic, retain) NSSet* rooms;
@property (nonatomic, retain) NSSet* messages;

@end


@interface User (CoreDataGeneratedAccessors)
- (void)addTransfersObject:(Transfer *)value;
- (void)removeTransfersObject:(Transfer *)value;
- (void)addTransfers:(NSSet *)value;
- (void)removeTransfers:(NSSet *)value;

- (void)addTickersObject:(Ticker *)value;
- (void)removeTickersObject:(Ticker *)value;
- (void)addTickers:(NSSet *)value;
- (void)removeTickers:(NSSet *)value;

- (void)addFilesObject:(Result *)value;
- (void)removeFilesObject:(Result *)value;
- (void)addFiles:(NSSet *)value;
- (void)removeFiles:(NSSet *)value;

- (void)addRoomsObject:(Room *)value;
- (void)removeRoomsObject:(Room *)value;
- (void)addRooms:(NSSet *)value;
- (void)removeRooms:(NSSet *)value;

- (void)addMessagesObject:(ChatMessage *)value;
- (void)removeMessagesObject:(ChatMessage *)value;
- (void)addMessages:(NSSet *)value;
- (void)removeMessages:(NSSet *)value;

- (NSUInteger)queueTime;

@end

