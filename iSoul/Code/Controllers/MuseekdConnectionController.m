//
//  MuseekdController.m
//  Museeki
//
//  Created by Richard on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MuseekdConnectionController.h"
#import "Constants.h"
#import "MuseekReader.h"
#import "MuseekWriter.h"
#import "MuseekMessage.h"
#import "NSStringHash.h"
#import "Ticket.h"
#import "User.h"
#import "Result.h"
#import "Transfer.h"
#import "DataStore.h"
#import "Room.h"
#import "Ticker.h"
#import "iTunes.h"
#import "MainWindowController.h"
#import "iSoul_AppDelegate.h"
#import "NSNumber-Utilities.h"

@implementation MuseekdConnectionController

@synthesize state;
@synthesize connectedToMuseekd;
@synthesize store;

#pragma mark initialization and dealloction

- (id)init 
{
	if ((self = [super init])) {
		state = usOffline;
		connectedToMuseekd = NO;
		importedFiles = [[NSMutableArray alloc] init];
		clearedTransfers = [[NSMutableSet alloc] init];
		input = [[MuseekReader alloc] init];
		output = [[MuseekWriter alloc] init];
		[input setDelegate:self];
		[output setDelegate:self];
	}
	return self;
}

- (void)dealloc
{
	[importedFiles release];
	[clearedTransfers release];
	[store release];
	[input release];
	[output release];
	[ownName release];
	[password release];
	[super dealloc];
}

#pragma mark properties

- (NSString *)username
{
	return ownName;
}

#pragma mark stream connection

- (void)connectToHost:(NSHost*)host port:(NSUInteger)port password:(NSString*)thePassword 
{
	// store the museekd password
	[password release];
	password = [thePassword retain];
	
	NSInputStream *inputStream = nil;
	NSOutputStream *outputStream = nil;
	
	// get the streams
	[NSStream getStreamsToHost:host 
						  port:port 
				   inputStream:&inputStream 
				  outputStream:&outputStream];
	
	// check the connection succeeded
	if (!inputStream || !outputStream) {
		NSString *errorMessage = [NSString stringWithFormat:
								  @"Error connecting to the Museek daemon at address %@:%u. Is the destination reachable?",
								  [host address], port];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:@"MuseekConnectionError" 
						  object:errorMessage];
		NSLog(@"failed to connect to museekd server %@", host);
		return;
	}
	
	// assign the streams to the controllers
	[input setInputStream:inputStream];
	[output setOutputStream:outputStream];
	
	// open the connections
	[input open];
	[output open];
}

- (void)disconnect
{
	// if connected, disconnect from the soulseek network
	if (state != usOffline) {
		MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
		[msg appendUInt32:mdDisconnect];
		[output send:msg];
	}
	
	// close the connections
	[input close];
	[output close];
	[self setState:usOffline];
	[self setConnectedToMuseekd:NO];
}

#pragma mark museek send message functions

- (void)search:(NSString *)term type:(SearchType)type
{
	if (state == usOffline) return;
	
	debug_NSLog(@"searching for %@", term);
	
	// form the message based on soulseek protocol
	MuseekMessage *msg = [[MuseekMessage alloc] init];
	[msg appendUInt32:mdSearch];	// command type
	[msg appendUInt32:type];		// 0 = global search, 1 = buddies, 2 = rooms
	[msg appendString:term];		// search parameter
	
	// output the desired message
	[output send:msg];
	[msg release];
}

- (void)addWishlistItem:(NSString *)term
{
	if (state == usOffline) return;
	
	debug_NSLog(@"adding %@ to the wishlist", term);
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdAddWishlistItem];
	[msg appendString:term];
	
	[output send:msg];
}

- (void)removeWishlistItem:(NSString *)term
{
	if (state == usOffline) return;
	
	debug_NSLog(@"removing wishlist item %@", term);
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdRemoveWishItem];
	[msg appendString:term];
	
	[output send:msg];
}

- (void)downloadFile:(Result *)result
{
	if (state == usOffline) return;
	
	BOOL success = YES;
	MuseekMessage *msg = [[MuseekMessage alloc] init];
	[msg appendUInt32:mdDownloadFile];			// command type
	success &= [msg appendString:[[result user] name]];	// username string
	success &= [msg appendString:[result fullPath]];	// full path string
	[msg appendUInt64:[[result size] longLongValue]];	// I64 file size
	
	if (success) {
		[output send:msg];
	} else {
		NSLog(@"aborting download file, string conversion failed");
	}
	[msg release];
}

- (void)resumeTransfer:(Transfer *)transfer
{
	if (state == usOffline) return;
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdDownloadFile];			// command type
	[msg appendString:[[transfer user] name]];	// username string
	[msg appendString:[transfer path]];			// full path string
	[msg appendUInt64:[[transfer size] longLongValue]];	// I64 file size
	
	[output send:msg];
}

- (void)downloadFolder:(NSString *)path fromUser:(NSString *)username
{
	if (state == usOffline) return;
	
	BOOL success = YES;
	MuseekMessage *msg = [[MuseekMessage alloc] init];
	[msg appendUInt32:mdDownloadFolder];		// command type
	success &= [msg appendString:username];	// username string
	success &= [msg appendString:path];		// full path string
	
	if (success) {
		[output send:msg];
	} else {
		NSLog(@"aborting download folder, string conversion failed");
	}	
	[msg release];
}

- (void)removeTransfer:(Transfer *)transfer
{
	if (!connectedToMuseekd) return;
	
	MuseekMessage *msg = [[MuseekMessage alloc] init];
	[msg appendUInt32:mdTransferRemove];	// command type
	[msg appendBool:[[transfer isUpload] boolValue]];	// upload or download?
	[msg appendString:[[transfer user] name]];		// username to remove transfer from
	[msg appendString:[transfer path]];		// path of the file to remove
	
	[output send:msg];
	[msg release];
	
	// cache the transfer so that no further status updates are sent
	[clearedTransfers addObject:transfer];
}

- (void)abortTransfer:(Transfer *)transfer
{
	if (!connectedToMuseekd) return;
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdAbortTransfer];					// command type
	[msg appendBool:[[transfer isUpload] boolValue]];	// abort upload?
	[msg appendString:[[transfer user] name]];			// username transferring from / to
	[msg appendString:[transfer path]];					// path of the transfer
	
	[output send:msg];	
}

- (void)sendMessage:(NSString *)line toRoom:(NSString *)room
{
	if (state == usOffline) return;
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdSayInRoom];		// command type
	[msg appendString:room];			// room to send message to
	[msg appendString:line];			// message to send
	
	[output send:msg];
	debug_NSLog(@"sent message to room %@", room);
}

- (void)joinRoom:(NSString *)room
{
	if (state == usOffline) return;
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdJoinRoom];		// command type
	[msg appendString:room];			// room name
	[msg appendBool:NO];				// private room?
	
	[output send:msg];
}

- (void)leaveRoom:(NSString *)room
{
	if (state == usOffline) return;
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdLeaveRoom];		// command type
	[msg appendString:room];			// room name
	
	[output send:msg];
}

- (void)sendPrivateChat:(NSString *)message toUser:(NSString *)username
{
	if (state == usOffline) return;
	
	// the message needs to be stored in the room, 
	// as we do not receive a copy of this message
	// as we do in a normal chatroom
	[store addMessage:message toRoom:username forUser:ownName isPrivate:YES];	
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdPrivateChat];	// command type
	[msg appendString:username];		// user to send message to
	[msg appendString:message];
	
	[output send:msg];
}

- (void)stopSearchForTicket:(uint32_t)ticket
{
	if (state == usOffline) 
    {
        DNSLog(@"Status: offline");
        return;
    }
	//printf("\nnn\n");
	MuseekMessage *msg = [[MuseekMessage alloc] init];
	[msg appendUInt32:mdSearchReply];
	[msg appendUInt32:ticket];	// the ticket to stop searching for
    DNSLog(@"Trying to remove ticket");
	[output send:msg];
	[msg release];
}

- (void)removeSearchForTickets:(NSSet *)tickets
{
	if (!tickets) return;
	
	// first stop the search with the server
	for (Ticket *t in tickets) {
		[self stopSearchForTicket:[[t number] unsignedIntValue]];
	}	
	
	// now remove the search ticket from core data
	[store clearSearchWithTickets:tickets];
}

- (void)browseUser:(NSString *)username
{
	if (state == usOffline) return;
	
	debug_NSLog(@"requesting file list for user %@", username);
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdUserShares];
	[msg appendString:username];	
	
	[output send:msg];
}

- (void)getUserInfo:(NSString *)username
{
	if (state == usOffline) return;
	
	debug_NSLog(@"getting user info for %@", username);
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	[msg appendUInt32:mdUserInfo];
	[msg appendString:username];	
	
	[output send:msg];
}

- (void)addOrRemoveFriend:(User *)user
{
	if (state == usOffline) return;
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	BOOL isFriend = [[user isFriend] boolValue];
	if (isFriend) {
		// remove from config domain
		[msg appendUInt32:mdConfigRemove];
		[msg appendCipher:@"buddies" withKey:password];	// domain to remove from
		[msg appendCipher:[user name] withKey:password];	// the config key
	} else {
		// request user info for the user
		// in case they have an image to show in friends view
		[self getUserInfo:[user name]];
		
		// add to config domain
		[msg appendUInt32:mdConfigSet];
		[msg appendCipher:@"buddies" withKey:password];	// domain to add to
		[msg appendCipher:[user name] withKey:password];	// the new config key
		[msg appendCipher:@"" withKey:password];	// empty value
	}
	[output send:msg];
	
	// change the buddy state of the user
	[user setIsFriend:[NSNumber numberWithBool:!isFriend]];
	
	// send a notification to update the main and friends view
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"BuddiesUpdated" object:user];
}

- (void)setConfigDomain:(NSString *)domain forKey:(NSString *)key toValue:(NSString *)value
{
	if (!connectedToMuseekd) {
		debug_NSLog(@"not connected to the Museek daemon");
		return;
	}
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	
	// add to config domain
	[msg appendUInt32:mdConfigSet];
	[msg appendCipher:domain withKey:password];	// domain to modify
	[msg appendCipher:key withKey:password];	// the key to add or update
	[msg appendCipher:value withKey:password];	// the new value
	
	[output send:msg];
}

- (void)reloadShares
{
	if (!connectedToMuseekd) {
		debug_NSLog(@"not connected to the Museek daemon");
		return;
	}
	
	debug_NSLog(@"reloading the shares database");
	
	MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
	
	[msg appendUInt32:mdReloadShares];
	[output send:msg];
}

- (void)checkPriveleges
{
	if (state == usOffline) return;
	
	debug_NSLog(@"requesting user priveleges");
	
	MuseekMessage *msg = [[MuseekMessage alloc] init];	
	[msg appendUInt32:mdCheckPriveleges];
	[output send:msg];
	[msg release];
}

- (void)sharePrivelegesWithUser:(NSString *)username days:(uint32_t)numDays
{
	if (state == usOffline) return;
	
	debug_NSLog(@"sharing %u days of priveleges with user %@", numDays, username);
	
	MuseekMessage *msg = [[MuseekMessage alloc] init];	
	[msg appendUInt32:mdGivePriveleges];
	[msg appendString:username];
	[msg appendUInt32:numDays];
	[output send:msg];
	[msg release];
}

- (void)toggleOnlineStatus
{
	uint32_t stateToSet;
	switch (state) {
		case usAway:
		{
			debug_NSLog(@"setting state to online");
			stateToSet = 0;	// set to online
			break;
		}
		case usOnline:
		{
			debug_NSLog(@"setting state to away");
			stateToSet = 1;	// set to away
			break;
		}
		default:
		{
			return;
		}
	}
	
	MuseekMessage *msg = [[MuseekMessage alloc] init];
	[msg appendUInt32:mdSetStatus];
	[msg appendUInt32:stateToSet];
	[output send:msg];
	[msg release];
}

- (void)getTransferState:(Transfer *)transfer
{
	if (state == usOffline) return;
	
	//debug_NSLog(@"getting q position for transfer %@", [transfer path]);
	
	MuseekMessage *msg = [[MuseekMessage alloc] init];	
	[msg appendUInt32:mdTransferUpdate];
	[msg appendString:[[transfer user] name]];
	[msg appendString:[transfer path]];
	[output send:msg];
	[msg release];
}

- (void)banOrUnbanUser:(User *)user
{
	if (!connectedToMuseekd) {
		debug_NSLog(@"not connected to the Museek daemon");
		return;
	}
	
	MuseekMessage *msg = [[MuseekMessage alloc] init];
	if (![[user isBanned] boolValue]) {
		debug_NSLog(@"banning user %@", [user name]);
		
		// add to config domain
		[msg appendUInt32:mdConfigSet];
		[msg appendCipher:@"banned" withKey:password];		// domain to add to
		[msg appendCipher:[user name] withKey:password];	// the new config key
		[msg appendCipher:@"" withKey:password];			// empty value		
		
	} else {
		debug_NSLog(@"unbanning user %@", [user name]);
		
		// remove from config domain
		[msg appendUInt32:mdConfigRemove];
		[msg appendCipher:@"banned" withKey:password];		// domain to remove from
		[msg appendCipher:[user name] withKey:password];	// the config key
		
	}
	[output send:msg];
	[msg release];	
}

#pragma mark private methods

- (void)updateUserdata:(MuseekMessage *)msg forUser:(User *)user
{
	uint32_t status = [msg readUInt32];
	uint32_t avgSpeed = [msg readUInt32];
	uint32_t numDownloads = [msg readUInt32];
	uint32_t numFiles = [msg readUInt32];
	[msg readUInt32];	// number of directories
	BOOL slotsFree = [msg readBool];
	NSString *countryCode = [msg readString];
	[user setStatus:[NSNumber numberWithUnsignedInt:status]];
	[user setAverageSpeed:[NSNumber numberWithUnsignedInt:avgSpeed]];
	[user setHasFreeSlots:[NSNumber numberWithBool:slotsFree]];
	[user setNumberOfDownloads:[NSNumber numberWithUnsignedInt:numDownloads]];
	[user setNumberOfFiles:[NSNumber numberWithUnsignedInt:numFiles]];
	[user setCountry:countryCode];
}

- (void)growlNotify:(NSString *)title msg:(NSString *)msg  {
	[self growlNotify: title msg: msg name: title];
}

- (void)growlNotify:(NSString *)title msg:(NSString *)msg name:(NSString *)name {
	[GrowlApplicationBridge notifyWithTitle: title
								description: msg
						   notificationName: name
								   iconData: nil
								   priority: 0
								   isSticky: NO
							   clickContext: NSDate.date];
}


#pragma mark museek reponse methods

- (void)respondToChallenge:(MuseekMessage *)msg
{
	[msg readUInt32];	// museekd version number
	NSString *challenge = [msg readString];
	
	// to reply we must append the password
	// and perform an MD5 hash of the message
	NSString *reply = [NSString stringWithFormat:@"%@%@", challenge, password];
	NSString *digest = [NSString md5StringWithString:reply];
	
	// now create a message with this response
	MuseekMessage *response = [[[MuseekMessage alloc] init] autorelease];
	[response appendUInt32:mdLogin];		// reply with login message
	[response appendString:@"MD5"];			// hash type
	[response appendString:digest];			// MD5 hash response
	[response appendUInt32:mdMessageMask];	// respond to required message types
	[output send:response];
}

- (void)respondToLogin:(MuseekMessage *)msg
{
	BOOL ok = [msg readBool];
	
	if (ok) {
		debug_NSLog(@"museekd login successful");
		[self setConnectedToMuseekd:YES];
		
		// now connect to soulseek
		MuseekMessage *connectMsg = [[MuseekMessage alloc] init];
		[connectMsg appendUInt32:mdConnect];
		[output send:connectMsg];
		[connectMsg release];
		
	} else {
		[self setConnectedToMuseekd:NO];
		NSString *error = [msg readString];
		NSString *errorMessage;
		if ([error isEqualToString:@"INVHASH"]) {
			errorMessage = @"Failed to connect to the Museek daemon, the MD5 hash has failed";
		} else {
			errorMessage = @"Failed to connect to the Museek daemon, the password is incorrect";
		}
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:@"MuseekConnectionError" object:errorMessage];
		debug_NSLog(@"museekd login failed with message: %@", error);
	}
}

- (void)readOnlineStatus:(MuseekMessage *)msg
{
	BOOL away = [msg readBool];
	[self setState:(away ? usAway : usOnline)];
	
	debug_NSLog(@"Online status set to %@", (away ? @"away" : @"online"));
}

- (void)readServerState:(MuseekMessage *)msg
{
	BOOL connected = [msg readBool];
	[self setState:(connected ? usOnline : usOffline)];	
	
	if (connected) {
		ownName = [[msg readString] retain];
		debug_NSLog(@"connected to soulseek with username %@", ownName);
		
		// request the user info so we can display pics for friends
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFriend == YES"];
		NSArray *friends = [store findArrayOf:@"User" withPredicate:predicate];
		for (User *friend in friends) {
			[self getUserInfo:[friend name]];
		}		
	} else {
		debug_NSLog(@"not connected to soulseek");
	}
	
}

- (void)readConfiguration:(MuseekMessage *)msg
{
	// get the shared defaults so the settings can be updated
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	// number of domains
	NSUInteger n = [msg readUInt32];

	// iterate the domains
	for (NSUInteger i = 0; i < n; i++) {
		NSString *domain = [msg readCipherWithKey:password];
		uint32_t numKeys = [msg readUInt32];
				
		
		// iterate the keys
		for (NSUInteger j = 0; j < numKeys; j++) {
			NSString *key = [msg readCipherWithKey:password];
			NSString *val = [msg readCipherWithKey:password];
			
			if ([domain isEqualToString:@"wishlist"]) {
				// add each wish list to the side pane
				// key is the search term
				// val is the last search timestamp
				[store addNewWishlist:key];
			}
			
			else if ([domain isEqualToString:@"banned"]) {
				// note all the banned users
				User *user = [store getOrAddUserWithName:key];
				[user setIsBanned:[NSNumber numberWithBool:YES]];
			}
			
			else if ([domain isEqualToString:@"buddies"]) {
				// register each user as a friend
				User *user = [store getOrAddUserWithName:key];
				[user setIsFriend:[NSNumber numberWithBool:YES]];
				
				// send a notification to update the main and friends view
				NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
				[nc postNotificationName:@"BuddiesUpdated" object:user];
			}
			
			else if ([domain isEqualToString:@"clients.bind"]) {
				if ([key isEqualToString:@"first"]) {
					[prefs setInteger:[val intValue] forKey:@"PortLow"];
				}
				else if ([key isEqualToString:@"last"]) {
					[prefs setInteger:[val intValue] forKey:@"PortHigh"];
				}
			}
			
			else if ([domain isEqualToString:@"server"]) {
				if ([key isEqualToString:@"host"]) {
					[prefs setObject:val forKey:@"ServerUrl"];
				}
				else if ([key isEqualToString:@"password"]) {
					[prefs setObject:val forKey:@"Password"];
				}
				else if ([key isEqualToString:@"port"]) {
					[prefs setInteger:[val intValue] forKey:@"ServerPort"];
				}
				else if ([key isEqualToString:@"username"]) {
					[prefs setObject:val forKey:@"Username"];
					[[[NSApp delegate] mainWindowController] checkUsername];
				}
			}
			
			else if ([domain isEqualToString:@"transfers"]) {
				
				if ([key isEqualToString:@"upload_rate"]) {
					[prefs setInteger:[val intValue] forKey:@"UploadRate"];
				}
				else if ([key isEqualToString:@"upload_slots"]) {
					[prefs setInteger:[val intValue] forKey:@"UploadSlots"];
				}
				else if ([key isEqualToString:@"download-dir"]) {
					[prefs setObject:val forKey:@"DownloadPath"];
				}
				else if ([key isEqualToString:@"incomplete-dir"]) {
					[prefs setObject:val forKey:@"IncompletePath"];
				}
				else if ([key isEqualToString:@"download_rate"]) {
					[prefs setInteger:[val intValue] forKey:@"DownloadRate"];
				}
				else if ([key isEqualToString:@"download_slots"]) {
					[prefs setInteger:[val intValue] forKey:@"DownloadSlots"];
				}
			}
			
			else if ([domain isEqualToString:@"userinfo"]) {
				
				if ([key isEqualToString:@"text"]) {
					[prefs setObject:val forKey:@"Description"];
				}
				
			}
			
		}
		
	}	
}

- (void)readConfigurationChange:(MuseekMessage *)msg
{
	NSString *domain = [msg readCipherWithKey:password];
	NSString *key = [msg readCipherWithKey:password];
	
#ifdef _DEBUG 
	NSString *value = [msg readCipherWithKey:password];		
	NSLog(@"configuration domain %@ update key %@ with value %@",
				domain, key, value);
#endif
	
	if ([domain isEqualToString:@"banned"]) {
		User *user = [store getOrAddUserWithName:key];
		[user setIsBanned:[NSNumber numberWithBool:YES]];
	}
}

- (void)configKeyRemoved:(MuseekMessage *)msg
{
	NSString *domain = [msg readCipherWithKey:password];
	NSString *key = [msg readCipherWithKey:password];
	
	debug_NSLog(@"configuration domain %@ removed key %@",
				domain, key);
	
	if ([domain isEqualToString:@"banned"]) {
		User *user = [store getOrAddUserWithName:key];
		[user setIsBanned:[NSNumber numberWithBool:NO]];
	}
}

- (void)readPeerExists:(MuseekMessage *)msg
{
#ifdef _DEBUG
	NSString *username = [msg readString];
	BOOL exists = [msg readBool];
	
	if (exists) {
		NSLog(@"user %@ exists", username);
	} else {
		NSLog(@"user %@ does not exist", username);
	}
#endif
}

- (void)readPeerStatus:(MuseekMessage *)msg
{
	NSString *username = [msg readString];
	uint32_t status = [msg readUInt32];
	
	// update user status
	User *user = [store getOrAddUserWithName:username];
	[user setStatus:[NSNumber numberWithUnsignedInt:status]];
	
	// send a notification to update the chat view
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"UserStatusUpdated" object:user];
	
	if ([[user isFriend] boolValue]) {
		// send a notification to update the main and friends view
		[nc postNotificationName:@"BuddiesUpdated" object:user];
	}
}

- (void)readPeerStatistics:(MuseekMessage *)msg
{
	NSString *username = [msg readString];
	uint32_t averageSpeed = [msg readUInt32];
	uint32_t numDownloads = [msg readUInt32];
	uint32_t numFiles = [msg readUInt32];
	[msg readUInt32];	// number of directories
	[msg readBool];		// user slots full (not sure about this)
	NSString *countryCode = [msg readString];
	
	// update the user stats
	User *user = [store getOrAddUserWithName:username];
	[user setAverageSpeed:[NSNumber numberWithUnsignedInt:averageSpeed]];
	[user setNumberOfDownloads:[NSNumber numberWithUnsignedInt:numDownloads]];
	[user setNumberOfFiles:[NSNumber numberWithUnsignedInt:numFiles]];
	[user setCountry:countryCode];
	
	// inform the chat view so they can reload the row
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"UserStatusUpdated" object:user];
	
	if ([[user isFriend] boolValue]) {
		// send a notification to update the main and friends view
		[nc postNotificationName:@"BuddiesUpdated" object:user];
	}
}

- (void)readUserInfo:(MuseekMessage *)msg
{
	NSString *username = [msg readString];
	NSString *description = [msg readString];
	NSImage *picture = [msg readImage];
	uint32_t uploads = [msg readUInt32];
	uint32_t queueLength = [msg readUInt32];
	BOOL slotsFree = [msg readBool];
	
	// get and update the user object
	User *user = [store getOrAddUserWithName:username];
	
	// if a picture is set, we need to resize
	// to create the icon for use in chat and friends list
	if (picture) {
		debug_NSLog(@"resizing user picture for %@", username);
		NSSize originalSize = [picture size];
		
		// to keep the pictures aspect ratio
		// find a square clip region in the middle
		float squareSize = MIN(originalSize.width, originalSize.height);
		NSRect square = NSMakeRect(0, 0, squareSize, squareSize);
		square.origin.x += (originalSize.width - squareSize) / 2.0;
		square.origin.y += (originalSize.height - squareSize) / 2.0;
		
		NSImage *icon = [[NSImage alloc] 
						 initWithSize:NSMakeSize(kUserIconSize, kUserIconSize)];
		[icon lockFocus];
		[picture drawInRect:NSMakeRect(0, 0, kUserIconSize, kUserIconSize) 
				   fromRect:square
				  operation:NSCompositeSourceOver fraction:1.0];
		[icon unlockFocus];
		
		[user setPicture:[picture TIFFRepresentation]];
		[user setIcon:[icon TIFFRepresentation]];
		[icon release];
	}
	[user setInfo:description];
	[user setNumberOfUploads:[NSNumber numberWithUnsignedInt:uploads]];
	[user setQueueLength:[NSNumber numberWithUnsignedInt:queueLength]];
	[user setHasFreeSlots:[NSNumber numberWithBool:slotsFree]];
	
	// send a notification that the user info is updated
	debug_NSLog(@"received user info for %@", username);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"UserInfoUpdated" object:user];
}

- (void)readTransferState:(MuseekMessage *)msg
{
	uint32_t numberOfTransfers = [msg readUInt32];
	debug_NSLog(@"there are %u transfers", numberOfTransfers);
	
	for (NSUInteger i = 0; i < numberOfTransfers; i++) {
		// add the current transfers
		[self updateTransferState:msg];
	}
}

- (void)updateTransferState:(MuseekMessage *)msg
{
	// now read the transfer structure
	BOOL isUpload = [msg readBool];
	NSString *user = [msg readString];
	NSString *path = [msg readString];
	uint32_t placeInQueue = [msg readUInt32];
	uint32_t transferState = [msg readUInt32];
	NSString *error = [msg readString];
	uint64_t position = [msg readUInt64];
	uint64_t size = [msg readUInt64];
	uint32_t rate = [msg readUInt32];

	// get the corresponding transfer entity
	// or create a new one 
	BOOL newTransfer;
	Transfer *transfer = [store findOrAddTransferWithPath:path 
												  forUser:user 
													isNew:&newTransfer];
	
	// if the transfer is to be cleared, do not bother
	// sending any more status updates
	if ([clearedTransfers containsObject:transfer]) return;
	
	// populate the updated settings
	NSNumber *oldTransferState = transfer.state;
	transfer.isUpload = [NSNumber numberWithBool:isUpload];
	transfer.placeInQueue = [NSNumber numberWithUnsignedInt:placeInQueue];
	transfer.state = [NSNumber numberWithUnsignedInt:transferState];
	transfer.error = error;
	transfer.position = [NSNumber numberWithLongLong:position];
	transfer.size = [NSNumber numberWithLongLong:size];
	transfer.rate = [NSNumber numberWithUnsignedInt:rate];
	
	// send a notification to inform the DownloadView controller to reload the item
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"TransferStateUpdated" object:transfer];
	
	// send a notification if the transfer is new and a download
	if (newTransfer && !isUpload) {
		[nc postNotificationName:@"NewTransferAdded" object:transfer];
	}
	
	// if required, remove the transfer when finished
	if (transferState == tfFinished) {
		// send a notification that the transfer has finished
		// this is used in the download view to refresh q positions
		[nc postNotificationName:@"TransferFinished" object:transfer];
		
		NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
		NSNumber *shouldRemove = [def valueForKey:@"RemoveCompleteDownload"];
		if ([shouldRemove boolValue]) {
			[self removeTransfer:transfer];
		}
		
		// now perform the scripting bridge calls
		// to add the track to iTunes if necessary				
		// check if we have seen this file before
		// if so, then ignore it
		if ([importedFiles containsObject:[transfer path]]) {
			return;
		}
		
		NSNumber *importAudio = [def valueForKey:@"ImportAudio"];
		NSNumber *importVideo = [def valueForKey:@"ImportVideo"];
		
		// first determine if the file is a music or video file
		NSString *extension = [[transfer.path pathExtension] lowercaseString];
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		BOOL audioFile = [ws filenameExtension:extension isValidForType:@"public.audio"];
		BOOL videoFile = [ws filenameExtension:extension isValidForType:@"public.video"];		
		
		if (([importAudio boolValue] && audioFile) ||
			([importVideo boolValue] && videoFile)) {
			[importedFiles addObject:[transfer path]];
			[NSThread detachNewThreadSelector:@selector(addFileToiTunes:) 
									 toTarget:self withObject:[transfer path]];
		}		
	}
	
	// Growl notifications
	NSString *fileName = [[transfer.path componentsSeparatedByString:@"\\"] lastObject];
	NSString *transferredSize = [transfer.size humanReadableBase10];
	
	if ([oldTransferState compare:transfer.state] != NSOrderedSame) {
		switch (transferState) {
			case tfTransferring:
				[self growlNotify: (isUpload) ? @"Upload started" : @"Download started"
							  msg: [NSString stringWithFormat:@"'%@' started transferring", fileName]];
				break;
			case tfFinished:
				[self growlNotify: (isUpload) ? @"Upload finished" : @"Download finished"
							  msg: [NSString stringWithFormat:@"'%@' (%@) successfully transferred", fileName, transferredSize]];
				break;
			case tfLocalError:
			case tfRemoteError:
				[self growlNotify: (isUpload) ? @"Upload failed" : @"Download failed"
							  msg: [NSString stringWithFormat:@"'%@' failed transferring", fileName]];
				break;
		}
	}
}

// add the files to itunes in a separate thread
// as this has to wait for itunes to launch etc
// and could block the main thread for some time
- (void)addFileToiTunes:(NSString *)remotePath
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// need to determine the local path for the file	
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	NSArray *pathComponents = [remotePath componentsSeparatedByString:@"\\"];
	NSString *filename = [pathComponents lastObject];
	NSString *foldername = nil;
	if ([pathComponents count] > 1) {
		foldername = [pathComponents objectAtIndex:([pathComponents count] - 2)];
	}
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *downloadPath = [def valueForKey:@"DownloadPath"];
	NSString *localPath = [NSString stringWithFormat:@"%@/%@", downloadPath,filename];
	if (![fm fileExistsAtPath:localPath]) {
		// might be part of a folder download
		localPath = [NSString stringWithFormat:@"%@/%@/%@",
					 downloadPath,foldername,filename];
		if (![fm fileExistsAtPath:localPath]) {
			NSLog(@"failed to find local path for file %@", filename);
			return;
		}							 
	}
	
	// now add the file to itunes playlist
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	SBElementArray *iSources = [iTunes sources];
	iTunesSource *library = nil;
	for (iTunesSource *source in iSources) {
		if ([[source name] isEqualToString:@"Library"]) {
			library = source;
			break;
		}
	}
	
	// could not find the itunes library
	if (!library) {
		NSLog(@"Could not connect to the iTunes library");
		return;
	}
	
	// now search for the correct playlist
	SBElementArray *playlists = [library userPlaylists];
	iTunesUserPlaylist *playlist = nil;
	NSNumber *importToList = [def valueForKey:@"ImportToPlaylist"];
	NSString *playlistName = [def valueForKey:@"ImportPlaylist"];
	
	if ([importToList boolValue]) {
		// need to find the playlist to add to
		for (iTunesUserPlaylist *thisList in playlists) {
			if ([[thisList name] isEqualToString:playlistName]) {
				playlist = thisList;
				break;
			}
		}
		
		// if the playlist was not found, create it
		if (!playlist) {
			playlist = [[[iTunes classForScriptingClass:@"playlist"] alloc] 
						initWithProperties:
						[NSDictionary dictionaryWithObjectsAndKeys:
						 playlistName, @"name", nil]];
			[[library userPlaylists] insertObject:playlist atIndex:0];
			[playlist release];
		}			
	} 
	NSArray *filesArray = [NSArray arrayWithObject:[NSURL fileURLWithPath:localPath]];
	iTunesTrack *track = [iTunes add:filesArray to:playlist];
	
	// play the file if necessary
	NSNumber *playAction = [def valueForKey:@"ImportAction"];
	switch ([playAction unsignedIntValue]) {
		case iaPlayImmediately:
		{
			[track playOnce:YES];			
			break;
		}
		case iaPlayIfNotPlaying:
		{
			iTunesEPlS playState = [iTunes playerState];
			if ((playState == iTunesEPlSPaused) ||
				(playState == iTunesEPlSStopped)) {
				[track playOnce:YES];
			}
			break;
		}
		case iaAddToPartyShuffle:
		{
			iTunesPlaylist *partyShuffle = nil;
			for (iTunesPlaylist *pl in playlists) {
				if ([[pl name] isEqualToString:@"Party Shuffle"]) {
					partyShuffle = pl;
					break;
				}
			}
			if (playlist) {
				[track duplicateTo:partyShuffle];
			}
			break;
		}
	}
	 
	[pool release];
}

- (void)transferRemoved:(MuseekMessage *)msg
{
	[msg readBool];		// is an upload?
	NSString *username = [msg readString];
	NSString *path = [msg readString];
	
	// first get the associated transfer and remove it from the cache
	Transfer *t = [store findOrAddTransferWithPath:path forUser:username isNew:NULL];
	[clearedTransfers removeObject:t];
	//BOOL allGone = [clearedTransfers count] == 0;
	DNSLog(@"send to remove");
	//[store removeTransfer:t sendUpdates:allGone];
    [store removeTransfer:t sendUpdates:YES];
}

- (void)readStatusMessage:(MuseekMessage *)msg
{
#ifdef _DEBUG
	BOOL isPeer = [msg readBool];
	NSString *status = [msg readString];
	
	NSLog(@"receieved status message %@ from %@", 
		  status, (isPeer ? @"peer" : @"server"));
#endif
}

- (void)readRoomState:(MuseekMessage *)msg
{
	[self readRoomList:msg];
	
	// number of joined rooms
	uint32_t numberJoined = [msg readUInt32];
	for (uint32_t j = 0; j < numberJoined; j++) {
		NSString *roomname = [msg readString];
		uint32_t numberOfUsers = [msg readUInt32];
		
		// join the room
		Room *room = [store joinRoom:roomname withUserCount:numberOfUsers];
		
		// for each user, read name and data
		for (uint32_t k = 0; k < numberOfUsers; k++) {
			
			NSString *username = [msg readString];
			User *user = [store getOrAddUserWithName:username];

			// update the userdata
			[self updateUserdata:msg forUser:user];
			
			// add the user to the room
			[room addUsersObject:user];
		}
		
		// now create all the ticker objects
		uint32_t numberOfTickers = [msg readUInt32];
		for (uint32_t t = 0; t < numberOfTickers; t++) {
			NSString *tickerOwner = [msg readString];
			NSString *tickerMessage = [msg readString];
			Ticker *ticker = [store addTickerWithUsername:tickerOwner 
												  message:tickerMessage];
			[room addTickersObject:ticker];
			[ticker setRoom:room];
		}
		
		
		debug_NSLog(@"added room %@ with %lu users and %lu tickers", 
					[room name], [[room users] count], [[room tickers] count]);
	}	
}

- (void)readRoomList:(MuseekMessage *)msg
{
	uint32_t numberOfRooms = [msg readUInt32];
	debug_NSLog(@"received list of %u rooms", numberOfRooms);
	
	// number of rooms in the list
	for (uint32_t i = 0; i < numberOfRooms; i++) {
		NSString *name = [msg readString];
		uint32_t usersPerRoom = [msg readUInt32];
		
		// create rooms for each of these
		[store addRoomWithName:name withCount:usersPerRoom];
	}
}

- (void)receivePrivateChat:(MuseekMessage *)msg
{
	[msg readUInt32];	// direction, 0 == incoming, 1 == outgoing
	[msg readUInt32];	// server timestamp, just use local timestamps
	NSString *username = [msg readString];
	NSString *message = [msg readString];
	
	// add the message with room the same as the user
	[store addMessage:message toRoom:username forUser:username isPrivate:YES];
	
	// Growl notification
	if (![NSApp isActive])
		[self growlNotify:username msg:message name:@"Received message"];
}

- (void)roomJoined:(MuseekMessage *)msg
{
	NSString *roomname = [msg readString];
	uint32_t numUsers = [msg readUInt32];
	
	// create the new room
	Room *room = [store joinRoom:roomname withUserCount:numUsers];
	
	for (uint32_t i = 0; i < numUsers; i++) {
		NSString * username = [msg readString];
		
		// get or create the user object
		User *user = [store getOrAddUserWithName:username];
		
		// update the userdata 
		[self updateUserdata:msg forUser:user];
		
		// add the user to the room and vice versa
		[room addUsersObject:user];
	}
}

- (void)roomLeft:(MuseekMessage *)msg
{
	NSString *roomname = [msg readString];
	[store leaveRoom:roomname];
	debug_NSLog(@"left room %@", roomname);
}

- (void)userJoinedRoom:(MuseekMessage *)msg
{
	NSString *roomname = [msg readString];
	NSString *username = [msg readString];
	
	// add the user to the room
	User *user = [store addUser:username toRoom:roomname];
	
	// update the user statistics
	[self updateUserdata:msg forUser:user];
	
	debug_NSLog(@"user %@ joined room %@",username,roomname);
}

- (void)userLeftRoom:(MuseekMessage *)msg
{
	NSString *roomname = [msg readString];
	NSString *username = [msg readString];
	
	[store removeUser:username fromRoom:roomname];
	debug_NSLog(@"removed user %@ from room %@",username,roomname);
}

- (void)readRoomMessage:(MuseekMessage *)msg
{
	NSString *roomname = [msg readString];
	NSString *username = [msg readString];
	NSString *line = [msg readString];
	
	// add the data as a new message object
	[store addMessage:line toRoom:roomname forUser:username isPrivate:NO];
	debug_NSLog(@"added new message to room %@ for user %@", roomname, username);
}

- (void)startSearch:(MuseekMessage *)msg
{
	NSString *searchTerm = [msg readString];
	uint32_t ticket = [msg readUInt32];
	
	debug_NSLog(@"starting new search for %@ with ticket %u", searchTerm, ticket);
	
	Ticket *newSearch = (Ticket *)[store createEntity:@"Ticket"];
	[newSearch setNumber:[NSNumber numberWithUnsignedInt:ticket]];
	[newSearch setSearchTerm:searchTerm];
	
	// add the search to the side bar
	[store addNewSearch:newSearch];
}

- (void)readSearchReply:(MuseekMessage *)msg
{
	// read the message header
	uint32_t ticketNumber = [msg readUInt32];
	NSString *name = [msg readString];
	BOOL slotFree = [msg readBool];
	uint32_t averageSpeed = [msg readUInt32];
	uint32_t queueLength = [msg readUInt32];
	
	// weird bug where the first search result has the username
	// set to the current login username, which causes a lot of grief
	if ([name isEqualToString:ownName]) {
		debug_NSLog(@"error, received spurious search results from own username");
		return;
	}
	
	// retrieve ticket object for this search
	Ticket *ticket = [store findTicketWithNumber:ticketNumber];
	if (ticket == nil) {
		// if the ticket has been deleted then bounce
		debug_NSLog(@"ticket %u is has been removed, ignoring search results", ticketNumber);
        [self stopSearchForTicket:ticketNumber];
		return;
	}
	
	// retrieve or create the user object
	User *user = [store getOrAddUserWithName:name];
	[user setAverageSpeed:[NSNumber numberWithUnsignedInt:averageSpeed]];
	[user setHasFreeSlots:[NSNumber numberWithBool:slotFree]];
	[user setQueueLength:[NSNumber numberWithUnsignedInt:queueLength]];
	
	// now read the folder results and add to the user
	NSSet *fileList = [self readFolder:msg withPath:nil];	
	
	// add the files to the user
	[user addFiles:fileList];
	
	// add the list of files as children to the ticket
	[ticket addFiles:fileList];
	
	// update the item count for the sidebar
	[store updateSearchWithTicketNumber:ticketNumber 
							   increase:[fileList count]];
	
	// cancel search when a certain number of searchs have been reached
	if (![[ticket stopped] boolValue]) {
		NSNumber *maxCount = [[NSUserDefaults standardUserDefaults] 
							  valueForKey:@"MaxSearchResults"];
		if ([[ticket files] count] > [maxCount unsignedIntValue]) {
			debug_NSLog(@"stopping searching for %@, obtained %lu results", 
						[ticket searchTerm], [[ticket files] count]);
//            for (Ticket * t in [store find:@"Ticket"withPredicate:[NSPredicate predicateWithFormat:@"searchTerm == %@", 
//                                 [ticket searchTerm]]])
//                {
                    [self stopSearchForTicket:ticketNumber];                
//                }
			
			[ticket setStopped:[NSNumber numberWithBool:YES]];
		}		
	}
}

- (void)readShares:(MuseekMessage *)msg
{	
	NSString *username = [msg readString];
	uint32_t numFolders = [msg readUInt32];
	
	debug_NSLog(@"received %u folders for user %@", numFolders, username);
	
	// get the corresponding user object
	User *user = [store getOrAddUserWithName:username];
	
	// remove any files currently stored
	[user removeFiles:[user files]];
	
	// add the files to the user object
	for (uint32_t i = 0; i < numFolders; i++) {
		NSString *folderPath = [msg readString];
		NSSet *fileList = [self readFolder:msg withPath:folderPath];
		[user addFiles:fileList];
	}
	[user setBrowseListReceived:[NSNumber numberWithBool:YES]];
	debug_NSLog(@"finished reading files for user %@", username);
	
	// send a notification to inform the window controller
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"UserFilelistUpdated" object:user];
}

- (NSSet *)readFolder:(MuseekMessage *)msg withPath:(NSString *)folderPath
{
	uint32_t numberOfFiles = [msg readUInt32];
	NSMutableSet *fileList = [NSMutableSet setWithCapacity:numberOfFiles];
	
	// create all the core data objects in one shot
	NSManagedObjectContext *moc = [[NSApp delegate] managedObjectContext];
	NSEntityDescription *e = [NSEntityDescription entityForName:@"Result" 
										 inManagedObjectContext:moc];
	for (uint32_t i = 0; i < numberOfFiles; i++) {
		NSManagedObject *obj = [[NSManagedObject alloc] initWithEntity:e 
										insertIntoManagedObjectContext:moc];
		[fileList addObject:obj];
		[obj release];
	}
	
	// now read the file info and set the properties
	for (Result *file in fileList) {
		NSString *filename = [msg readString];

		// read fileentry structure
		uint64_t filesize = [msg readUInt64];
		[msg readString]; // file extension, what is the use in it?
		uint32_t numAttributes = [msg readUInt32];
		uint32_t bitrate = 0;
		uint32_t length = 0;
		uint32_t vbr = 0;
		if (numAttributes >= 1) bitrate = [msg readUInt32];
		if (numAttributes >= 2) length = [msg readUInt32];
		if (numAttributes >= 3) vbr = [msg readUInt32];
		if (numAttributes > 3) {
			NSLog(@"error, reply has %u attributes, should only be 3", numAttributes);
			for (uint32_t j = 3; j < numAttributes; j++) [msg readUInt32];
		}
		
		// the folder path will be set to nil for search results
		// and the filename will contain the full path
		if (folderPath) {
			[file setFilename:filename];
			[file setFullPath:[NSString stringWithFormat:
							   @"%@\\%@", folderPath, filename]];
		} else {
			// get the filename from the full path
			[file setFullPath:filename];
			NSRange r = [filename rangeOfString:@"\\" options:NSBackwardsSearch];
			if (r.location == NSNotFound) {
				[file setFilename:filename];
			} else {
				[file setFilename:[filename substringFromIndex:r.location + 1]];
			}
		}
		
		[file setSize:[NSNumber numberWithUnsignedLongLong:filesize]];
		[file setBitrate:[NSNumber numberWithUnsignedInt:bitrate]];			
		[file setLength:[NSNumber numberWithUnsignedInt:length]];
		[file setVbr:[NSNumber numberWithUnsignedInt:vbr]];	
	}
	return [NSSet setWithSet:fileList];
}

 
#pragma mark museek reader delegate methods

- (void)processMessage:(MuseekMessage *)msg
{
	NSUInteger code = [msg code];
		
	// skip the current message position to after the code
	[msg setPos:sizeof(uint32_t)];	
	
	switch (code) {
		case mdChallenge:
		{
			[self respondToChallenge:msg];
			break;
		}
		case mdLogin:
		{
			[self respondToLogin:msg];
			break;
		}
		case mdServerState:
		{
			[self readServerState:msg];
			break;
		}
		case mdSetStatus:
		{
			[self readOnlineStatus:msg];
			break;
		}
		case mdStatusMessage:
		{
			[self readStatusMessage:msg];
			break;
		}
		case mdConfigState:
		{
			[self readConfiguration:msg];
			break;
		}
		case mdConfigSet:
		{
			[self readConfigurationChange:msg];
			break;
		}
		case mdConfigRemove:
		{
			[self configKeyRemoved:msg];
			break;
		}
		case mdPeerExists:
		{
			[self readPeerExists:msg];
			break;
		}
		case mdPeerStatus:
		{
			[self readPeerStatus:msg];
			break;
		}
		case mdPeerStatistics:
		{
			[self readPeerStatistics:msg];
			break;
		}
		case mdUserInfo:
		{
			[self readUserInfo:msg];
			break;
		}
		case mdUserShares:
		{
			[self readShares:msg];
			break;
		}
		case mdRoomState:
		{
			[self readRoomState:msg];
			break;
		}
		case mdRoomList:
		{
			[self readRoomList:msg];
			break;
		}
		case mdPrivateChat:
		{
			[self receivePrivateChat:msg];
			break;
		}
		case mdJoinRoom:
		{
			[self roomJoined:msg];
			break;
		}
		case mdLeaveRoom:
		{
			[self roomLeft:msg];
			break;
		}
		case mdUserJoinedRoom:
		{
			[self userJoinedRoom:msg];
			break;
		}
		case mdUserLeftRoom:
		{
			[self userLeftRoom:msg];
			break;
		}
		case mdSayInRoom:
		{
			[self readRoomMessage:msg];
			break;
		}
		case mdSearch:
		{
			[self startSearch:msg];
			break;
		}
		case mdSearchReply:
		{
			[self readSearchReply:msg];
			break;
		}
		case mdTransferState:
		{
			[self readTransferState:msg];
			break;
		}
		case mdTransferUpdate:
		{
			[self updateTransferState:msg];
			break;
		}
		case mdTransferRemove:
		{
			[self transferRemoved:msg];
			break;
		}
		default:
		{
			debug_NSLog(@"received museek message with code 0x%04lx", code);
			break;
		}
	}
}

@end
