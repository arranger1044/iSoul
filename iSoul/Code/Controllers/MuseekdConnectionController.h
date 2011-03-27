//
//  MuseekdController.h
//  Museeki
//
//  Created by Richard on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@class MuseekReader;
@class MuseekWriter;
@class MuseekMessage;
@class DataStore;
@class Result;
@class Transfer;
@class User;

@interface MuseekdConnectionController : NSObject {
	ConnectionState state;
	BOOL connectedToMuseekd;
	MuseekReader *input;
	MuseekWriter *output;
	DataStore *store;
	NSString *ownName;
	NSString* password;
	NSMutableArray *importedFiles;
	NSMutableSet *clearedTransfers;
}

@property (readwrite) ConnectionState state;
@property (readwrite) BOOL connectedToMuseekd;
@property (retain) DataStore *store;
@property (readonly) NSString *username;

// public methods
- (void)connectToHost:(NSHost*)host port:(NSUInteger)port password:(NSString*)thePassword;
- (void)disconnect;
- (void)processMessage:(MuseekMessage *)msg;
- (void)search:(NSString *)term type:(SearchType)searchType;
- (void)addWishlistItem:(NSString *)term;
- (void)removeWishlistItem:(NSString *)term;
- (void)downloadFile:(Result *)result;
- (void)resumeTransfer:(Transfer *)transfer;
- (void)downloadFolder:(NSString *)path fromUser:(NSString *)username;
- (void)removeTransfer:(Transfer *)transfer;
- (void)abortTransfer:(Transfer *)transfer;
- (void)sendMessage:(NSString *)line toRoom:(NSString *)room;
- (void)joinRoom:(NSString *)room;
- (void)leaveRoom:(NSString *)room;
- (void)sendPrivateChat:(NSString *)message toUser:(NSString *)username;
- (void)stopSearchForTicket:(uint32_t)ticket;
- (void)removeSearchForTickets:(NSSet *)tickets;
- (void)browseUser:(NSString *)username;
- (void)getUserInfo:(NSString *)username;
- (void)addOrRemoveFriend:(User *)user;
- (void)setConfigDomain:(NSString *)domain forKey:(NSString *)key toValue:(NSString *)value;
- (void)reloadShares;
- (void)checkPriveleges;
- (void)sharePrivelegesWithUser:(NSString *)username days:(uint32_t)numDays;
- (void)toggleOnlineStatus;
- (void)getTransferState:(Transfer *)transfer;	// call this to get the q position
- (void)banOrUnbanUser:(User *)user;

// private methods
- (void)updateUserdata:(MuseekMessage *)msg forUser:(User *)user;
- (void)respondToChallenge:(MuseekMessage *)msg;
- (void)respondToLogin:(MuseekMessage *)msg;
- (void)readOnlineStatus:(MuseekMessage *)msg;
- (void)readServerState:(MuseekMessage *)msg;
- (void)readTransferState:(MuseekMessage *)msg;
- (void)readStatusMessage:(MuseekMessage *)msg;
- (void)startSearch:(MuseekMessage *)msg;
- (void)readSearchReply:(MuseekMessage *)msg;
- (void)readPeerExists:(MuseekMessage *)msg;
- (void)readPeerStatus:(MuseekMessage *)msg;
- (void)readPeerStatistics:(MuseekMessage *)msg;
- (void)readUserInfo:(MuseekMessage *)msg;
- (void)updateTransferState:(MuseekMessage *)msg;
- (void)transferRemoved:(MuseekMessage *)msg;
- (void)readConfiguration:(MuseekMessage *)msg;
- (void)readConfigurationChange:(MuseekMessage *)msg;
- (void)configKeyRemoved:(MuseekMessage *)msg;
- (void)readRoomState:(MuseekMessage *)msg;
- (void)readRoomList:(MuseekMessage *)msg;
- (void)readRoomMessage:(MuseekMessage *)msg;
- (void)roomJoined:(MuseekMessage *)msg;
- (void)roomLeft:(MuseekMessage *)msg;
- (void)userJoinedRoom:(MuseekMessage *)msg;
- (void)userLeftRoom:(MuseekMessage *)msg;
- (void)receivePrivateChat:(MuseekMessage *)msg;
- (void)readShares:(MuseekMessage *)msg;
- (NSSet *)readFolder:(MuseekMessage *)msg withPath:(NSString *)folderPath;
- (void)addFileToiTunes:(NSString *)remotePath;
- (void)growlNotify:(NSString *)title msg:(NSString *)msg;
- (void)growlNotify:(NSString *)title msg:(NSString *)msg name:(NSString *)name;

@end
