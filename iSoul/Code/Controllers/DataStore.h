//
//  DataStore.h
//  iSoul
//
//  Created by Richard on 10/27/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"

@class SidebarItem;
@class Ticket;
@class Transfer;
@class User;
@class Room;
@class Ticker;

@interface DataStore : NSObject {

	NSManagedObjectContext *managedObjectContext;
	SidebarItem *searchRoot;
	SidebarItem *chatRoot;
	SidebarItem *shareRoot;
	SidebarItem *downloads;
	SidebarItem *uploads;
	SidebarItem *friends;
	NSUInteger sidebarSortIndex;
}

@property (retain) NSManagedObjectContext *managedObjectContext;
@property (readonly) SidebarItem *downloads;
@property (readonly) SidebarItem *uploads;

// public methods
- (void)addDefaultSidebarItems;
- (NSManagedObject *)createEntity:(NSString *)entityName;
- (User *)getOrAddUserWithName:(NSString *)username;

// search methods
- (SidebarItem *)newSearch;
- (SidebarItem *)newWishlistItem;
- (Ticket *)findTicketWithNumber:(uint32_t)ticket;
- (void)addNewSearch:(Ticket *)ticket;
- (void)updateSearchWithTicketNumber:(uint32_t)ticket increase:(NSUInteger)count;
- (void)clearSearchWithTickets:(NSSet *)tickets;
- (void)addNewWishlist:(NSString *)searchTerm;

// transfer methods
- (Transfer *)findOrAddTransferWithPath:(NSString *)path forUser:(NSString *)username isNew:(BOOL *)new;
- (void)clearAllTransfers;
- (void)removeTransfer:(Transfer *)transfer sendUpdates:(BOOL)yesOrNo;

// chat methods
- (SidebarItem *)startPrivateChat:(NSString *)username;
- (Room *)addRoomWithName:(NSString *)roomName withCount:(uint32_t)count;
- (Ticker *)addTickerWithUsername:(NSString *)name message:(NSString *)msg;
- (void)addMessage:(NSString *)msg toRoom:(NSString *)room forUser:(NSString *)user isPrivate:(BOOL)privateMsg;
- (User *)addUser:(NSString *)name toRoom:(NSString *)room;
- (void)removeUser:(NSString *)name fromRoom:(NSString *)room;
- (void)leaveRoom:(NSString *)roomname;
- (Room *)joinRoom:(NSString *)roomname withUserCount:(uint32_t)count;

// share methods
- (SidebarItem *)findOrCreateShare:(User *)user;
- (SidebarItem *)findOrCreateShareForName:(NSString *)username;

// friends methods
- (SidebarItem *)recountOnlineFriends;

// private methods
- (SidebarItem *)addSidebarItemWithName:(NSString *)name parent:(SidebarItem *)parent sortIndex:(NSUInteger)index tag:(uint32_t)tag type:(SidebarType)type;
- (NSManagedObject *)find:(NSString *)entity withPredicate:(NSPredicate *)predicate;
- (NSArray *)findArrayOf:(NSString *)entity withPredicate:(NSPredicate *)predicate;
- (void)clearAllEntities:(NSString *)entity;

@end
