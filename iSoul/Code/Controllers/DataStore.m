//
//  DataStore.m
//  iSoul
//
//  Created by Richard on 10/27/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "DataStore.h"
#import "Constants.h"
#import "SidebarItem.h"
#import "Ticket.h"
#import "User.h"
#import "Transfer.h"
#import "Room.h"
#import "ChatMessage.h"
#import "MainWindowController.h"
#import "iSoul_AppDelegate.h"

@implementation DataStore

@synthesize managedObjectContext;
@synthesize downloads;
@synthesize uploads;

#pragma mark initialisation and deallocation

- (void)dealloc
{
	[managedObjectContext release];
	[super dealloc];
}

#pragma mark public methods

- (void)addDefaultSidebarItems
{
	debug_NSLog(@"adding items to the sidebar");
	
	// create network heading
	SidebarItem *network = [self addSidebarItemWithName:@"NETWORK" 
												 parent:nil 
											  sortIndex:0
													tag:0 
												   type:sbNetworkType];
	[network setIsExpanded:[NSNumber numberWithBool:YES]];
	
	// add the upload and download children
	downloads = [self addSidebarItemWithName:@"Downloads" 
									  parent:network 
								   sortIndex:100
										 tag:0 
										type:sbDownloadMenuType];
	uploads = [self addSidebarItemWithName:@"Uploads" 
									parent:network 
								 sortIndex:200
									   tag:0 
									  type:sbUploadMenuType];
	friends = [self addSidebarItemWithName:@"Friends" 
									parent:network 
								 sortIndex:300 
									   tag:0 
									  type:sbFriendType];
	
	// create empty chats heading
	chatRoot = [self addSidebarItemWithName:@"CHATS" 
									 parent:nil 
								  sortIndex:1 
										tag:0 
									   type:sbChatMenuType];
	[chatRoot setIsExpanded:[NSNumber numberWithBool:YES]];
	
	// create empty shares heading
	shareRoot = [self addSidebarItemWithName:@"SHARES" 
									  parent:nil 
								   sortIndex:2 
										 tag:0 
										type:sbShareMenuType];
	[shareRoot setIsExpanded:[NSNumber numberWithBool:YES]];
	
	// create empty searches heading
	searchRoot = [self addSidebarItemWithName:@"SEARCHES" 
						  parent:nil 
					   sortIndex:3 
							 tag:0 
							type:sbSearchType];
	[searchRoot setIsExpanded:[NSNumber numberWithBool:YES]];
	
	sidebarSortIndex = 20;
}

- (NSManagedObject *)createEntity:(NSString *)entityName
{
	return [NSEntityDescription insertNewObjectForEntityForName:entityName 
										 inManagedObjectContext:managedObjectContext];
}

- (User *)getOrAddUserWithName:(NSString *)username
{
	// search for the user in the store
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"name == %@",username];
	User *user = (User *)[self find:@"User" withPredicate:predicate];
	if (user == nil) {
		user = (User *)[self createEntity:@"User"];
		[user setName:username];
	}
	return user;
}

#pragma mark search methods

// this is called from the main window controller
// the search term will be typed manually and 
// the ticket number will be updated later
- (SidebarItem *)newSearch
{
	debug_NSLog(@"adding new empty search for editing");
	SidebarItem *item = [self addSidebarItemWithName:@"New Search" 
								 parent:searchRoot 
							  sortIndex:kSearchIndexStart + sidebarSortIndex++ 
									tag:0 
								   type:sbSearchType];
	
	// force the moc to process the changes
	[managedObjectContext processPendingChanges];
	return [item retain];
}

- (SidebarItem *)newWishlistItem
{
	debug_NSLog(@"adding new empty wishlist item for editing");
	SidebarItem *item = [self addSidebarItemWithName:@"New Wishlist" 
								 parent:searchRoot 
							  sortIndex:kWishIndexStart + sidebarSortIndex++ 
									tag:0 
								   type:sbWishType];
	
	// force the moc to process the changes
	[managedObjectContext processPendingChanges];
	return [item retain];
}

- (Ticket *)findTicketWithNumber:(uint32_t)ticketNumber
{
	NSPredicate *predicate = 
		[NSPredicate predicateWithFormat:@"number == %u", ticketNumber];
	return (Ticket *)[self find:@"Ticket" withPredicate:predicate];
}

- (void)addNewSearch:(Ticket *)ticket
{	
	// the search may be relating to a wish list item, or	
	// if the bottom left button was used, the sidebar item will already exist
	// so we need to search for it before creating a new one
	// also, if we are searching multiple databases, there will be
	// multiple tickets for each search term
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"name == %@ && (type == %u OR type == %u)",
							  [ticket searchTerm], sbSearchType, sbWishType];
	SidebarItem *item = (SidebarItem *)[self find:@"SidebarItem" withPredicate:predicate];
	
	if (item) {
		// add the search ticket to the sidebar item
		debug_NSLog(@"appending ticket %u to search %@", 
					[[ticket number] unsignedIntValue], 
					[item name]);
		[item addTicketsObject:ticket];
	} else {
		debug_NSLog(@"adding new search with index %lu", kSearchIndexStart + sidebarSortIndex);
		
		// search created with search field, create new sidebar item
		SidebarItem *newSearch = [self addSidebarItemWithName:[ticket searchTerm] 
							  parent:searchRoot 
						   sortIndex:kSearchIndexStart + sidebarSortIndex++ 
								 tag:[[ticket number] unsignedIntValue] 
								type:sbSearchType];
		[newSearch addTicketsObject:ticket];
	}	
}

- (void)updateSearchWithTicketNumber:(uint32_t)ticketNumber increase:(NSUInteger)count
{
	// find the connected sidebar item
	Ticket *ticket = [self findTicketWithNumber:ticketNumber];
	SidebarItem *item = ticket.sidebarItem;
	
	if (item) {
		//debug_NSLog(@"updating ticket %u with count %u", ticket, count);
		unsigned newCount = item.count.unsignedIntValue + (unsigned) count;
		[item setCount:[NSNumber numberWithUnsignedInt:newCount]];
		
		// send notification to inform MainWindowController to update the sidebar
		NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
		[nc postNotificationName:@"SidebarCountUpdated" object:item];
	} else {
		debug_NSLog(@"error finding sidebar item for ticket %p", ticket);
	}
}

- (void)clearSearchWithTickets:(NSSet *)tickets
{
	// get the side item
	SidebarItem *item = [tickets.anyObject sidebarItem];
	
	// first clear the tickets
	for (Ticket *t in item.tickets) {
		[managedObjectContext deleteObject:t];
	}		
	
	// also remove the corresponding sidebar item
	if (item) [managedObjectContext deleteObject:item];
}

- (void)addNewWishlist:(NSString *)searchTerm
{
	debug_NSLog(@"adding new wishlist item with index %lu", kWishIndexStart + sidebarSortIndex);
	
	[self addSidebarItemWithName:searchTerm 
						  parent:searchRoot
					   sortIndex:kWishIndexStart + sidebarSortIndex++
							 tag:0
							type:sbWishType];
}

#pragma mark transfer methods

- (Transfer *)findOrAddTransferWithPath:(NSString *)path forUser:(NSString *)username isNew:(BOOL *)new
{
	// first find the user
	User *user = [self getOrAddUserWithName:username];
	
	// search for present transfer
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"user.name == %@ && path == %@",username,path];
	
	Transfer *transfer = (Transfer *)[self find:@"Transfer" withPredicate:predicate];
	
	// if we could not find one, make a new one
	if (!transfer) {
		transfer = (Transfer *)[self createEntity:@"Transfer"];
		[transfer setPath:path];
		[transfer setUser:user];
		if (new) *new = YES;
	} else {
		if (new) *new = NO;
	}
	
	return transfer;
}

- (void)clearAllTransfers
{
	[self clearAllEntities:@"Transfer"];	
}

- (void)clearCompleteTransfers
{
    
}

- (void)removeTransfer:(Transfer *)transfer sendUpdates:(BOOL)sendUpdates
{	
	// first inform the download view that the transfer should be removed
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (sendUpdates) {		
		[nc postNotificationName:@"TransferRemoved" object:transfer];
	}
	DNSLog(@"Remove frome store");
	// now remove the transfer object	
	[managedObjectContext deleteObject:transfer];
	
	// finally inform the main window controller to update the count
	if (sendUpdates)
		[nc postNotificationName:@"TransferStateUpdated" object:nil];
}

#pragma mark chat methods

- (SidebarItem *)startPrivateChat:(NSString *)username
{
    DNSLog(@"Starting private chat");
	// first check the chat does not already exist
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"name == %@ && type == %u",username,sbChatType];
	SidebarItem *item = (SidebarItem *)[self find:@"SidebarItem" withPredicate:predicate];
	if (item) return item;
	
	// item not found, so create a new one
	item = [self addSidebarItemWithName:username 
								 parent:chatRoot 
							  sortIndex:kChatIndexStart + sidebarSortIndex++ 
									tag:(uint32_t) -1 
								   type:sbChatType];
	
	// create a new room to contain the chat messages
	Room *chatRoom = [self addRoomWithName:username withCount:2];
	[chatRoom setIsPrivate:[NSNumber numberWithBool:YES]];
	[chatRoom setJoined:[NSNumber numberWithBool:YES]];
	
	// get the users to add to the room
	predicate = [NSPredicate predicateWithFormat:@"name == %@", username];
	User *user = (User *)[self find:@"User" withPredicate:predicate];
	if (!user) {
		NSLog(@"error finding user %@ to start private chat", username);
	} else {
		[chatRoom addUsersObject:user];
	}	
	
	// get the current username from the preferences
	NSString *ourself = [[NSUserDefaults standardUserDefaults] 
						  valueForKey:@"Username"];
	predicate = [NSPredicate predicateWithFormat:@"name == %@", ourself];
	user = (User *)[self find:@"User" withPredicate:predicate];
	if (!user) {
		NSLog(@"error finding user %@ to start private chat", ourself);
	} else {
		[chatRoom addUsersObject:user];
	}	
	
	// force the moc to process the changes
	[managedObjectContext processPendingChanges];
	return item;
}

- (Room *)addRoomWithName:(NSString *)name withCount:(uint32_t)count
{
	// first check if the room exists
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
	Room *room = (Room *)[self find:@"Room" withPredicate:predicate];
	
	// if it does, return
	if (room != nil) return room;
	
	// does not exist, so create a new one
	room = (Room *)[self createEntity:@"Room"];
	[room setName:name];
	[room setNumberOfUsers:[NSNumber numberWithUnsignedInt:count]];
		
	return room;
}

- (Ticker *)addTickerWithUsername:(NSString *)name message:(NSString *)msg
{
	// fetch or create a new user
	User *user = [self getOrAddUserWithName:name];
	
	// create the new ticker object
	Ticker *ticker = (Ticker *)[self createEntity:@"Ticker"];
	[ticker setUser:user];
	[ticker setMessage:msg];
	return ticker;
}

- (unsigned int)resetSidebarCount:(NSString *)name{
    
    unsigned int readMessages = 0;
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(name == %@) && ((type == %u) || (type == %u))", name, sbChatType, sbChatRoomType];
    
    SidebarItem *item = (SidebarItem *)[self find:@"SidebarItem" withPredicate:predicate];
    if (item == nil) 
    {
        DNSLog(@"Could not find sidebar item for room %@", name);
    } 
    else 
    {
        readMessages = [[item count] unsignedIntValue];
        //DNSLog(@"%@", [item count]);
        [item resetCount];
        //DNSLog(@"%@", [item count]);
        // send a notification to inform the main window controller
        // and the chat view controller
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"SidebarCountUpdated" object:item];
    }
    
    return readMessages;
}

- (void)updateSidebar:(NSString *)name withCount:(NSNumber *)count{

    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(name == %@) && ((type == %u) || (type == %u))", name, sbChatType, sbChatRoomType];

    SidebarItem *item = (SidebarItem *)[self find:@"SidebarItem" withPredicate:predicate];
    if (item == nil) 
    {
        DNSLog(@"Could not find sidebar item for room %@", name);
    } 
    else 
    {
        //DNSLog(@"%@", [item count]);
        
        NSNumber * newCount = [NSNumber numberWithUnsignedInt:([[item count] unsignedIntValue] + 
                                                               [count unsignedIntValue])];
        [item setCount:newCount];
        //DNSLog(@"%@", [item count]);
        // send a notification to inform the main window controller
        // and the chat view controller
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:@"SidebarCountUpdated" object:item];
    }

}

- (void)addMessage:(NSString *)msg toRoom:(NSString *)roomname forUser:(NSString *)username isPrivate:(BOOL)privateMsg
{
	// find or create user and room objects
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"name == %@ && isPrivate == %u", roomname, privateMsg];
	
	Room *room = (Room *)[self find:@"Room" withPredicate:predicate];
	if (room == nil) 
    {
		// if this is a private chat, create a new room
		if (privateMsg) 
        {
			SidebarItem *item = [self startPrivateChat:username];
			room = (Room *)[self find:@"Room" withPredicate:predicate];
			
			// select the room in the main view
			[managedObjectContext processPendingChanges];
			[[[NSApp delegate] mainWindowController] selectItem:item];
		} 
        else 
        {			
			NSLog(@"could not find room %@ for message %@", roomname, msg);
			return;
		}
	}

	predicate = [NSPredicate predicateWithFormat:@"name == %@",username];
	User *user = (User *)[self find:@"User" withPredicate:predicate];
	if (user == nil) {
		NSLog(@"could not find user %@ for room %@", username, roomname);
		return;
	}
	
	ChatMessage *chat = (ChatMessage *)[self createEntity:@"ChatMessage"];
	[chat setMessage:msg];
	[chat setTimestamp:[NSDate date]];
	[chat setUser:user];
	[chat setIsPrivate:[NSNumber numberWithBool:privateMsg]];
	[chat setRoom:room];	// set the room last, as this triggers the kvo in chatViewController
    DNSLog(@"%@", [[chat room] name]);
    

}

- (User *)addUser:(NSString *)username toRoom:(NSString *)roomname
{
	// find the room
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",roomname];
	Room *room = (Room *)[self find:@"Room" withPredicate:predicate];
	if (room == nil) {
		NSLog(@"could not find room %@", roomname);
		return nil;
	}
	
	// find or create the user
	User *user = [self getOrAddUserWithName:username];
	
	// create the relationship
	[user addRoomsObject:room];
	
	// update the room count
	[room setNumberOfUsers:[NSNumber numberWithUnsignedInt: (unsigned) room.users.count]];
	
//	// update the sidebar item count
//	SidebarItem *item = (SidebarItem *)[self find:@"SidebarItem" withPredicate:predicate];
//	if (item == nil) {
//		NSLog(@"could not find sidebar item for room %@", roomname);
//	} else {
//		[item setCount:[room numberOfUsers]];
//		
//		// send a notification to inform the main window controller
//		// and the chat view controller
//		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//		[nc postNotificationName:@"SidebarCountUpdated" object:item];
//	}

	return user;
}

- (void)removeUser:(NSString *)username fromRoom:(NSString *)roomname
{
	// find the room
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",roomname];
	Room *room = (Room *)[self find:@"Room" withPredicate:predicate];
	if (room == nil) {
		NSLog(@"could not find room %@", roomname);
		return;
	}
	
	// find the user
	predicate = [NSPredicate predicateWithFormat:@"name == %@",username];
	User *user = (User *)[self find:@"User" withPredicate:predicate];
	if (user == nil) {
		NSLog(@"could not find user %@", username);
		return;
	}
	
	// remove the relationship
	[user removeRoomsObject:room];
	
	// update the room count
	[room setNumberOfUsers:[NSNumber numberWithUnsignedInt: (unsigned) room.users.count]];
	
//	// update the sidebar count
//	predicate = [NSPredicate predicateWithFormat:@"name == %@",roomname];
//	SidebarItem *item = (SidebarItem *)[self find:@"SidebarItem" withPredicate:predicate];
//	if (item == nil) {
//		NSLog(@"could not find sidebar item for room %@", roomname);
//	} else {
//		[item setCount:[room numberOfUsers]];
//		
//		// send a notification to inform the main window controller
//		// and the chat view controller
//		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//		[nc postNotificationName:@"SidebarCountUpdated" object:item];
//	}
	
}

- (void)leaveRoom:(NSString *)roomname
{
	// find the room
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",roomname];
	Room *room = (Room *)[self find:@"Room" withPredicate:predicate];
	if (room == nil) {
		NSLog(@"could not find room %@ to remove", roomname);
		return;
	}
	
	[room setJoined:[NSNumber numberWithBool:NO]];
	
	// find the sidebar item
	SidebarItem *item = (SidebarItem *)[self find:@"SidebarItem" withPredicate:predicate];
	if (item != nil) {
		[managedObjectContext deleteObject:item];
	}	
	
}

- (Room *)joinRoom:(NSString *)roomname withUserCount:(uint32_t)count
{
	// find the room
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",roomname];
	Room *room = (Room *)[self find:@"Room" withPredicate:predicate];
	if (room == nil) {
		// this is a new room, so create a new room object
		DNSLog(@"creating new room %@", roomname);
		room = (Room *)[self createEntity:@"Room"];
		[room setName:roomname];
	}
	
	// update the user count in the room
	[room setNumberOfUsers:[NSNumber numberWithUnsignedInt:count]];
	
	if ([[room joined] boolValue]) 
    {
		DNSLog(@"the room %@ has already been joined", roomname);
	} 
    else 
    {
		[room setJoined:[NSNumber numberWithBool:YES]];
		
		// add the room to the sidebar
		SidebarItem *item = [self addSidebarItemWithName:roomname 
												  parent:chatRoot 
											   sortIndex:kChatRoomIndexStart + sidebarSortIndex++ 
													 tag:(uint32_t) -1 
													type:sbChatRoomType];
		//[item setCount:[room numberOfUsers]];
        [item setCount:[NSNumber numberWithUnsignedInt:0]];
		
		// now select the room in the sidebar
		[managedObjectContext processPendingChanges];
		[[[NSApp delegate] mainWindowController] selectItem:item];		
	}
	return room;
}

#pragma mark share methods

- (SidebarItem *)findOrCreateShare:(User *)user
{
	// first check the share has not been added already
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(name == %@) && (type == %u)",
							  [user name], sbShareType];
	SidebarItem *item = (SidebarItem *)[self find:@"SidebarItem" withPredicate:predicate];
	
	if (item == nil) {
		item = [self addSidebarItemWithName:[user name] 
									 parent:shareRoot 
								  sortIndex:sidebarSortIndex++ 
										tag:0 
									   type:sbShareType];
		[item setCount:[NSNumber numberWithUnsignedInt: (unsigned) user.files.count]];
		[managedObjectContext processPendingChanges];
	}

	return item;
}

- (SidebarItem *)findOrCreateShareForName:(NSString *)username
{
	// first check the share has not been added already
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(name == %@) && (type == %u)",
							  username, sbShareType];
	SidebarItem *item = (SidebarItem *)[self find:@"SidebarItem" withPredicate:predicate];
	
	if (item == nil) {
		item = [self addSidebarItemWithName:username 
									 parent:shareRoot 
								  sortIndex:sidebarSortIndex++ 
										tag:0 
									   type:sbShareType];
		[managedObjectContext processPendingChanges];
	}
	
	return item;
}

#pragma mark friends methods

- (SidebarItem *)recountOnlineFriends
{
	// search for all online or away friends
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(isFriend == YES) && (status > 0)"];
	NSArray *results = [self findArrayOf:@"User" withPredicate:predicate];
	
	// update the badge count for the sidebar item
	[friends setCount:[NSNumber numberWithUnsignedInt: (unsigned) results.count]];
	
	// return the item to be redrawn
	return friends;
}

#pragma mark private methods

- (SidebarItem *)addSidebarItemWithName:(NSString *)name 
								 parent:(SidebarItem *)parent
							  sortIndex:(NSUInteger)sortIndex
									tag:(uint32_t)tag 
								   type:(SidebarType)type;
{
	// add a new item to the data store
	SidebarItem *item = (SidebarItem *)[self createEntity:@"SidebarItem"];
	
	[item setName:name];
	[item setParent:parent];
	[item setSortIndex:[NSNumber numberWithUnsignedInt: (unsigned) sortIndex]];
	[item setTag:[NSNumber numberWithUnsignedInt:tag]];
	[item setType:[NSNumber numberWithUnsignedInt:type]];
	
	// add the item as a child of parent
	[parent addChildrenObject:item];
	
	// if the parent should be expanded, and this is the first child
	// we need to get the outline view to reload data
	if ([[parent isExpanded] boolValue] && 
		([[parent children] count] == 1)) {
		[managedObjectContext processPendingChanges];
		NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
		[nc postNotificationName:@"ExpandNode" object:parent];
	}
	
	return item;
}

- (NSManagedObject *)find:(NSString *)entity withPredicate:(NSPredicate *)predicate
{
	NSArray *results = [self findArrayOf:entity withPredicate:predicate];
	
	if (results) {
		if ([results count] > 1) {
			NSLog(@"error finding %@, more than one result", entity);
		}
		return [results objectAtIndex:0];
	}
	return nil;
}

- (NSArray *)findArrayOf:(NSString *)entity withPredicate:(NSPredicate *)predicate
{
	// from Core Data Programming Guide
	NSEntityDescription *entityDescription = [NSEntityDescription 
											  entityForName:entity 
											  inManagedObjectContext:managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	[request setPredicate:predicate];
	
	// perform the fetch
	NSError *error;
	NSArray *array = [managedObjectContext executeFetchRequest:request error:&error];
	if (array) {
		if ([array count] == 0) return nil;
		return array;
	} else {
		// error searching
		NSLog(@"%@ search failed with reason %@", entity, [error localizedFailureReason]);
		return nil;
	}
}
							
- (void)clearAllEntities:(NSString *)entity
{
	NSArray *results = [self findArrayOf:entity withPredicate:nil];
	
	for (id obj in results) {
		[managedObjectContext deleteObject:obj];
	}
}							

@end
