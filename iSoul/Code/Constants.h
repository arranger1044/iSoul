//
//  Constants.h
//  iSoul
//
//  Created by Richard on 10/27/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//#ifdef _DEBUG
#define debug_NSLog(format, ...) NSLog((@"%s [Line %d] " format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define DNSLog(format, ...) NSLog((@"%s@%d: " format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#define rect2Log(X) DNSLog(@"x:%f y:%f w:%f h:%f",X.origin.x, X.origin.y, X.size.width, X.size.height)
#define point2Log(X) DNSLog(@"x:%f y:%f", X.x, X.y)
//#else
//#define debug_NSLog(format, ...)
//#endif

#define kAverageFileSize	(7*1024*1024)
#define kChatRoomIndexStart	0
#define kChatIndexStart		10000
#define kWishIndexStart		0
#define kSearchIndexStart	10000
#define kUserIconSize		32.0

#define kDefaultDividerPosition	400

// museekd command constants
#define mdMessageMask		(0x01 | 0x02 | 0x04 | 0x08 | 0x10 | 0x40)
#define mdChallenge			0x0001
#define mdLogin				0x0002
#define mdServerState		0x0003
#define mdCheckPriveleges	0x0004
#define mdSetStatus			0x0005
#define mdStatusMessage		0x0010
#define mdConfigState		0x0100
#define mdConfigSet			0x0101
#define mdConfigRemove		0x0102
#define mdPeerExists		0x0201
#define mdPeerStatus		0x0202
#define mdPeerStatistics	0x0203
#define mdUserInfo			0x0204
#define mdUserShares		0x0205
#define mdPeerAddress		0x0206
#define mdGivePriveleges	0x0207
#define mdRoomState			0x0300
#define mdRoomList			0x0301
#define mdPrivateChat		0x0302
#define mdJoinRoom			0x0303
#define mdLeaveRoom			0x0304
#define mdUserJoinedRoom	0x0305
#define mdUserLeftRoom		0x0306
#define mdSayInRoom			0x0307
#define mdStartPublicChat	0x0313
#define mdStopPublicChat	0x0314
#define mdSearch			0x0401
#define mdSearchReply		0x0402
#define	mdUserSearch		0x0403
#define mdAddWishlistItem	0x0406
#define mdRemoveWishItem	0x0407
#define mdTransferState		0x0500
#define mdTransferUpdate	0x0501
#define mdTransferRemove	0x0502
#define mdDownloadFile		0x0503
#define mdDownloadFolder	0x0504
#define mdAbortTransfer		0x0505
#define mdConnect			0x0700
#define mdDisconnect		0x0701
#define mdReloadShares		0x0703

// search types
typedef enum {
	stGlobal = 0,
	stBuddies,
	stRooms
} SearchType;

// sidebar item type enum
typedef enum {
	sbNetworkType = 1,
	sbSearchType,
	sbChatType,
	sbChatRoomType,
	sbShareType,
	sbFolderType,
	sbWishType,
	sbFriendType,
	sbDownloadMenuType,
	sbUploadMenuType,
	sbFriendMenuType,
	sbChatMenuType,
	sbShareMenuType
} SidebarType;

// transfer state enum
typedef enum {
	tfFinished = 0,
	tfTransferring,
	tfNegotiating,
	tfWaiting,
	tfEstablishing,
	tfInitiating,
	tfConnecting,
	tfQueuedRemotely,
	tfGettingAddress,
	tfGettingStatus,
	tfAwaitingUser,
	tfConnectionClosed,
	tfCannotConnect,
	tfAborted,
	tfRemoteError,
	tfLocalError,
	tfQueuedLocally
} TransferState;

// user online state enum
typedef enum {
	usOffline = 0,
	usAway,
	usOnline
} ConnectionState;

// view state enum
typedef enum {
	vwList,
	vwFolder,
	vwBrowse
} ViewState;

// import files action
typedef enum {
	iaDoNotPlay = 0,
	iaPlayImmediately,
	iaPlayIfNotPlaying,
	iaAddToPartyShuffle
} ImportAction;

// path constants
extern NSString * const pathBaseFolder;
extern NSString * const pathDownloads;
extern NSString * const pathIncomplete;
extern NSString * const pathShares;
extern NSString * const pathShareState;
extern NSString * const pathUserImage;
extern NSString * const pathPidFile;
extern NSString * const logFileName;
extern NSString * const LOG_PATH;
extern NSString * const DIR_PATH;
