//
//  MainWindowController.m
//  iSoul
//
//  Created by Richard on 10/27/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "MainWindowController.h"
#import "iSoul_AppDelegate.h"
#import "MuseekdConnectionController.h"
#import "DataStore.h"
#import "BadgeCell.h"
#import "NSOutlineViewRowIndex.h"
#import "SearchViewController.h"
#import "SidebarItem.h"
#import "DownloadViewController.h"
#import "ChatViewController.h"
#import "Transfer.h"
#import "BottomBar.h"
#import "User.h"
#import "NSTreeController-DMExtensions.h"
#import "BrowseViewController.h"
#import "MuseekdController.h"
#import "PrefsWindowController.h"
#import "FriendViewController.h"
#import "DockBadge.h"
#import "NSStringSpeed.h"
#import "ExpandingSidebar.h"
#import "LoggingController.h"
#import "LoggingConsole.h"
#import <TCMPortMapper/TCMPortMapper.h>

#define kMinSplitPosition	150

@implementation MainWindowController

@synthesize managedObjectContext;
@synthesize userToShow;
@synthesize roomSortDescriptors;
@synthesize store;
@synthesize museekdConnectionController;
@synthesize segmentEnabled;
@synthesize userControlsEnabled;
@synthesize transferToolsEnabled;
@synthesize downloadToolsEnabled;
@synthesize selectedView;
@synthesize console;

#pragma mark initialisation and deallocation

- (id)init
{
    DNSLog(@"init");
	self = [super init];
	if (self) {
        
		downloadIcon = [[NSImage imageNamed:@"SidebarDownloads"] retain];
		uploadIcon = [[NSImage imageNamed:@"SidebarUploads"] retain];
		searchIcon = [[NSImage imageNamed:@"SidebarSearch"] retain];
		wishIcon = [[NSImage imageNamed:@"SidebarWish"] retain];
		friendIcon = [[NSImage imageNamed:@"SidebarFriends"] retain];
		chatIcon = [[NSImage imageNamed:@"SidebarInstantMessage"] retain];
		chatRoomIcon = [[NSImage imageNamed:@"SidebarChatRoom"] retain];
		sharesIcon = [[NSImage imageNamed:@"SidebarShares"] retain];
        
		NSSortDescriptor *name = [[NSSortDescriptor alloc] 
								   initWithKey:@"name" 
								   ascending:YES
								   selector:@selector(localizedCaseInsensitiveCompare:)];
		[self setRoomSortDescriptors:[NSArray arrayWithObject:name]];
		[name release];
	}
	return self;
}

- (void)dealloc
{
	[managedObjectContext release];
	[roomSortDescriptors release];
	
	// stop observing changes
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	[museekdConnectionController removeObserver:self forKeyPath:@"state"];
	
	// deallocate the stored images
	[downloadIcon release];
	[uploadIcon release];
	[searchIcon release];
	[wishIcon release];
	[friendIcon release];
	[chatIcon release];
	[chatRoomIcon release];
	[sharesIcon release];
	
	// clean up museek connnection
	[museekdConnectionController release];
	[store release];
	
    self.console = nil;
    
	[super dealloc];
}

- (void)setSegmentEnabled:(BOOL)enabled {
    if (enabled)
    {
        NSInteger vState = [NSUserDefaults.standardUserDefaults integerForKey:@"SelectedSegmentView"];
        [viewSegment setSelectedSegment:vState];
        segmentEnabled = YES;        
    }
    else
    {
        [viewSegment setSelected:NO forSegment:0];
        [viewSegment setSelected:NO forSegment:1];
        [viewSegment setSelected:NO forSegment:2];
        segmentEnabled = NO;
    }
}

- (void)awakeFromNib
{
	// resize the window to the last setting
	[[self window] setFrameUsingName:@"Main Window"];
    
    LoggingConsole * logConsole = [[LoggingConsole alloc] initWithWindowNibName:nil];
    self.console = logConsole;
    [logConsole release];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowConsoleStartUp"])
    {
        //[[console window] orderOut:self];
        [[console window] orderWindow:NSWindowBelow relativeTo:[self.window windowNumber]];
    }
		
    /* Adding the double click action on the chat room list table */
    [chatRoomsTable setTarget:self];
    [chatRoomsTable setDoubleAction:NSSelectorFromString(@"joinRooms:")];

	// the 3 windows are manually added to the menu
	// so no need to automatically add them
	[[self window] setExcludedFromWindowsMenu:YES];
	[userInfoWindow setExcludedFromWindowsMenu:YES];
	[chatRoomWindow setExcludedFromWindowsMenu:YES];
    [[console window] setExcludedFromWindowsMenu:YES];
	
	// connect the main window controller
	[self setManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	[self setStore:[[NSApp delegate] store]];
	[self setMuseekdConnectionController:
	 [[NSApp delegate] museekdConnectionController]];
	
	// register to be notified when a sidebarItem count is updated
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		   selector:@selector(sidebarCountUpdated:) 
			   name:@"SidebarCountUpdated" 
			 object:nil];
	
	// be notified when a transfer begins, ends, or is updated
	[nc addObserver:self 
		   selector:@selector(transferUpdated:) 
			   name:@"TransferStateUpdated" 
			 object:nil];
	
	// be notified when a new transfer has been added
	[nc addObserver:self 
		   selector:@selector(transferAdded:) 
			   name:@"NewTransferAdded" 
			 object:nil];
	
	// be notified when a sidebar cell is finished editing
	[nc addObserver:self 
		   selector:@selector(finishedEditing:) 
			   name:@"NSControlTextDidEndEditingNotification" 
			 object:sidebar];
	
	// be notified when a new file list has been received
	[nc addObserver:self 
		   selector:@selector(browseListLoaded:) 
			   name:@"UserFilelistUpdated" 
			 object:nil];
	
	// be notified when user status changes
	// this is used to calculate the friends badge count
	[nc addObserver:self 
		   selector:@selector(buddiesUpdated:) 
			   name:@"BuddiesUpdated" 
			 object:nil];

	// be notified when the museekd daemon needs a restart
	[nc addObserver:self 
		   selector:@selector(restartMuseek:) 
			   name:@"MuseekRestartRequired" 
			 object:nil];
	
	// be notified if there is a connection error with the museek daemon
	[nc addObserver:self 
		   selector:@selector(displayError:) 
			   name:@"MuseekConnectionError" 
			 object:nil];
	
	// be notified when a new child is added to the outline view
	// this will require the outline view to expand the item
	[nc addObserver:self 
		   selector:@selector(expandNode:) 
			   name:@"ExpandNode" object:nil];
	
	// observe the connection state, to update the status icon
	[museekdConnectionController addObserver:self 
								  forKeyPath:@"state" 
									 options:NSKeyValueObservingOptionNew 
									 context:NULL];
	
	// observe status messages for the UPNP framework
	TCMPortMapper *pm = [TCMPortMapper sharedInstance];
	[nc addObserver:self 
		   selector:@selector(portMapperDidStartWork:) 
			   name:TCMPortMapperDidStartWorkNotification 
			 object:pm];
	[nc addObserver:self 
		   selector:@selector(portMapperDidFinishWork:)
			   name:TCMPortMapperDidFinishWorkNotification 
			 object:pm];
	
	// set the correct image for the bottom bar
	[bottomBar setBackground:[NSImage imageNamed:@"SidebarMenuBackground"]];
	
	// set double clicks to work on the room list
	[roomList setTarget:self];
	[roomList setDoubleAction:@selector(joinRooms:)];
	
	// disable all the toolbar controls
	[self setSegmentEnabled:NO];
	[self setUserControlsEnabled:NO];
	[self setTransferToolsEnabled:NO];
	[self setDownloadToolsEnabled:NO];
	
	// become the delegate for the chat view
	// so that divider positions are stored in the sidebar tag	
	ChatViewController *chatViewController = [[NSApp delegate] chatViewController];
	[chatViewController setDelegate:self];	
	
	// finally, connect to museekd
	NSNumber *localMuseekd = [[NSUserDefaults standardUserDefaults] 
							  valueForKey:@"LocalMuseekd"];
	[[NSApp delegate] performSelector:@selector(connectToMuseekd:) 
						   withObject:localMuseekd afterDelay:2.0];
}

- (void)checkUsername
{
	// check if a username has been set, if not
	// then tell the user to sort it out
	NSString *username = [[NSUserDefaults standardUserDefaults]
						  valueForKey:@"Username"];
	if ([username isEqualToString:@""]) {
		[NSApp beginSheet:noUsernamePanel 
		   modalForWindow:[self window]
			modalDelegate:self
		   didEndSelector:nil
			  contextInfo:NULL];
	}
}

#pragma mark Notification responses

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{

	// update the status icon in the corner to reflect connection status
	if ([object isEqual:museekdConnectionController]) {
		[sidebar setConnectionState:[museekdConnectionController state]];
	}
}

// occurs when a search count is updated
- (void)sidebarCountUpdated:(NSNotification *)notification
{
	SidebarItem *sideItem = (SidebarItem *)[notification object];
	
	// get the corresponding row, have to do it this way
	// as the outlineview has treenodes, not the acutal items
	NSInteger row = [sidebar rowForActualItem:sideItem];
	if (row >= 0) {
		[sidebar reloadItem:[sidebar itemAtRow:row]];
	}
}

- (void)transferUpdated:(NSNotification *)notification
{
	// search through all the transfers, totting up the
	// download and upload speeds
	NSUInteger numDownloads = 0;
	NSUInteger numUploads = 0;
	float downSpeed = 0;
	float upSpeed = 0;
	
    /* Maybe I shall get only the active transfers */
    NSPredicate * pred = [NSPredicate predicateWithFormat:
                         @"state != %u", tfFinished];
	// fetch all the transfers from the moc
	NSArray *transfers = [store findArrayOf:@"Transfer" withPredicate:pred];
	
	for (Transfer *transfer in transfers) {
		// the transfer rate in KB/s for active transfers
		float transferRate = 0;
		TransferState state = [[transfer state] unsignedIntValue];
		if (state == tfTransferring) {
			transferRate = transfer.rate.floatValue / 1000.0f;
		}
		
		if (transfer.isUpload.boolValue) {
			numUploads++;
			upSpeed += transferRate;
		} else {
			numDownloads++;
			downSpeed += transferRate;
		}
	}
	
	// update the parameters for the sidebar
	SidebarItem *downloads = store.downloads;
	SidebarItem *uploads = store.uploads;	
	
	[downloads setCount:[NSNumber numberWithUnsignedInt: (unsigned) numDownloads]];
	[uploads setCount:[NSNumber numberWithUnsignedInt: (unsigned) numUploads]];
	
	// if not requested, do not display the bandwidth usage
	NSNumber *shouldDisplay = [NSUserDefaults.standardUserDefaults 
							   valueForKey:@"BandwidthSidebar"];
	BOOL displayBandwidth = [shouldDisplay boolValue];
	
	if (displayBandwidth && (downSpeed > 0)) {
		[downloads setName:[NSString stringForSpeed:downSpeed]];
	} else {
		[downloads setName:@"Downloads"];
	}
	
	if (displayBandwidth && (upSpeed > 0)) {
		[uploads setName:[NSString stringForSpeed:upSpeed]];
	} else {
		[uploads setName:@"Uploads"];
	}
	
	// force redisplay of the two rows
	[sidebar reloadItem:[sidebar itemAtRow:0] reloadChildren:YES];
	
	// update the badge on the dock icon
	NSNumber *updateIcon = [NSUserDefaults.standardUserDefaults 
							valueForKey:@"BandwidthIcon"];
	DockBadge *icon = (DockBadge *)[[NSApp dockTile] contentView];
	float u, d;
	if ([updateIcon boolValue]) {
		u = upSpeed;
		d = downSpeed;
	} else {
		u = 0;
		d = 0;
	}
	if ([icon setDownloadRate:d uploadRate:u]) {
		[[NSApp dockTile] display];
	}
	
}

- (void)transferAdded:(NSNotification *)notification
{
	NSNumber *changeView = [[NSUserDefaults standardUserDefaults] 
							valueForKey:@"SelectNewDownload"];
	if ([changeView boolValue]) {
		[self selectItem:[store downloads]];
	}
}

- (void)finishedEditing:(NSNotification *)notification
{
	NSInteger row = [sidebar editedRow];
	SidebarItem *item = [[sidebar itemAtRow:row] representedObject];
	SidebarType type = [[item type] unsignedIntValue];
	NSString *searchTerm = NULL;
	
	// perform different actions depending on which type we have
	switch (type) {
		case sbSearchType:
			searchTerm = [item name];
			[self performSearch:searchTerm];			
			break;
		case sbWishType:
			searchTerm = [item name];
			[museekdConnectionController addWishlistItem:searchTerm];
			break;
		default:
			break;
	}
	
	// force the view to reload
	[sidebar selectRowIndexes:[NSIndexSet indexSetWithIndex: (NSUInteger) row] byExtendingSelection:NO];
	[self changeView:sidebar];
}

- (void)browseListLoaded:(NSNotification *)notification
{
	// the user that we have just loaded files for
	User *user = (User *)[notification object];
	
	// create a new share entry if there is not one already
	SidebarItem *item = [store findOrCreateShare:user];
	[item setCount:[NSNumber numberWithUnsignedInt: (unsigned) user.files.count]];

	[self selectItem:item];
}

- (void)buddiesUpdated:(NSNotification *)notification
{
	// either a friend has been added or removed
	// or changed online status, so recount 
	// and update the badge number for the friends entry
	SidebarItem *friends = [store recountOnlineFriends];
	
	// now redraw the outline view
	NSInteger row = [sidebar rowForActualItem:friends];
	[sidebar reloadItem:[sidebar itemAtRow:row]];
}

- (void)restartMuseek:(NSNotification *)notification
{
	debug_NSLog(@"restarting the museekd daemon");
	
	// close the network connection to museekd
	[museekdConnectionController disconnect];
	
	// stop the museekd process, if we are not
	// using it this command will be ignored anyway
	MuseekdController *mc = [[NSApp delegate] museekdController];
	[mc stopMuseekd];
	
	// reconnect to different server if necessary
	NSNumber *localMuseekd = [[NSUserDefaults standardUserDefaults] 
							  valueForKey:@"LocalMuseekd"];
	if ([localMuseekd boolValue]) [mc startMuseekd];	
	
	// and reopen the connection in a few seconds
	[[NSApp delegate] performSelector:@selector(connectToMuseekd:) 
						   withObject:localMuseekd afterDelay:1.0];
}

- (void)displayError:(NSNotification *)notification
{
	NSString *errorMessage = [notification object];
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:@"Museek Connection Error"];
	[alert setInformativeText:errorMessage];
	[alert beginSheetModalForWindow:[sidebar window] 
					  modalDelegate:self 
					 didEndSelector:nil 
						contextInfo:NULL];
}

- (void)expandNode:(NSNotification *)notification
{
	// the sidebar item that needs to be expanded
	SidebarItem *item = (SidebarItem *)[notification object];
	
	// i know this is poor, but could not think of a better way
	NSInteger row = [sidebar rowForActualItem:item];
	if (row < 0) {
		// the outline view has not loaded the item yet
		debug_NSLog(@"row not present, not sure why");
	} else {
		[sidebar expandItem:[sidebar itemAtRow:row] expandChildren:NO];
	}	
}

- (void)portMapperDidStartWork:(NSNotification *)notification
{
	debug_NSLog(@"starting UPNP port mapping");
}

- (void)portMapperDidFinishWork:(NSNotification *)notification
{
	TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    TCMPortMapping *mapping = [[pm portMappings] anyObject];
    if ([mapping mappingStatus]==TCMPortMappingStatusMapped) {
        debug_NSLog(@"UPNP successfully mapped ports");
    } else {
        debug_NSLog(@"UPNP port mapping failed");
		[NSApp beginSheet:upnpPanel 
		   modalForWindow:[self window]
			modalDelegate:self
		   didEndSelector:nil
			  contextInfo:NULL];		
    }
}

#pragma mark Events

- (void)keyDown:(NSEvent *)theEvent
{
	unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	
	// backspace or delete should remove a sidebar item
	// and also clear selected transfers
	if (key == NSBackspaceCharacter) {
		[self removeSideItem:nil];
		[self clearTransfer:nil];
		return;
	} else if (key == NSDeleteCharacter) {
		[self removeSideItem:nil];
	}
	
	[super keyDown:theEvent];
}

#pragma mark Private Methods

- (void)performSearch:(NSString *)searchTerm
{
	// do not allow short searches
	if ([searchTerm length] < 4) return;
	
	// first check if we are already searching for this
	NSManagedObject *result = [store find:@"Ticket" withPredicate:
							   [NSPredicate predicateWithFormat:@"searchTerm == %@", 
								searchTerm]];
	
	// if not, do a new search
	if (!result) {
		// check the preferences to see which types of search to perform
		NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
		NSNumber *searchDatabase = [def valueForKey:@"SearchMainDatabase"];
		NSNumber *searchFriends = [def valueForKey:@"SearchFriendsList"];
		NSNumber *searchChatRooms = [def valueForKey:@"SearchChatRooms"];
		
		if ([searchDatabase boolValue]) 
			[museekdConnectionController search:searchTerm type:stGlobal];
		if ([searchFriends boolValue])
			[museekdConnectionController search:searchTerm type:stBuddies];
		if ([searchChatRooms boolValue])
			[museekdConnectionController search:searchTerm type:stRooms];
	}  	
}

#pragma mark IBAction toolbar methods

- (IBAction)connectOrDisconnect:(id)sender
{
	if ([museekdConnectionController state] == usOffline) {
		debug_NSLog(@"attempting to connect to museekd");
		NSNumber *localMuseekd = [[NSUserDefaults standardUserDefaults] 
								  valueForKey:@"LocalMuseekd"];
		[[NSApp delegate] connectToMuseekd:localMuseekd];
	} else {
		debug_NSLog(@"disconnecting network connection to museekd");
		[museekdConnectionController disconnect];
	}
}

- (IBAction)search:(id)sender
{
	NSString *searchTerm = [searchField stringValue];
	[self performSearch:searchTerm];
}

- (IBAction)changeViewStyle:(id)sender
{
	NSInteger i = [sender selectedSegment];
	SearchViewController *svc = [[NSApp delegate] searchViewController];
	
	ViewState newState = vwList;
	switch (i) {
		case 0:
		{
			newState = vwList;
			break;
		}
		case 1:
		{
			newState = vwFolder;
			break;
		}
		case 2:
		{
			newState = vwBrowse;
			break;
		}
	}
	[svc setViewState:newState];
	
	// reload the view
	[self changeView:sidebar];
}

- (IBAction)privateChat:(id)sender
{
	// the action changes depending on what is selected
	// the app delegate will send the message to the current controller
	NSArray *selectedUsers = [[NSApp delegate] selectedUsers];
	
	SidebarItem *item = nil;
	for (User *u in selectedUsers) {
		// create a new sidebar item to contain the chat
		item = [store startPrivateChat:[u name]];
	}
	if (item) [self selectItem:item];
}

- (IBAction)browseUser:(id)sender
{
	// the action changes depending on what is selected
	// the app delegate will send the message to the current controller
	NSArray *selectedUsers = [[NSApp delegate] selectedUsers];
	
	SidebarItem *item = nil;
	for (User *u in selectedUsers) {
		// check if the item already exists
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"(name == %@) && (type == %u)", 
								  [u name], sbShareType];
		item = (SidebarItem *)[store find:@"SidebarItem" withPredicate:predicate];
		
		if (!item) {
			// create a new share entry
			item = [store findOrCreateShareForName:[u name]];
			
			// request the file list
			[museekdConnectionController browseUser:[u name]];
		}		
	}
	if (item) [self selectItem:item];
}

- (IBAction)userInfo:(id)sender
{
	// the action changes depending on what is selected
	// the app delegate will send the message to the current controller
	NSArray *selectedUsers = [[NSApp delegate] selectedUsers];
	
	if ([selectedUsers count] > 0) {
		for (User *u in selectedUsers) {
			// request updated information
			[museekdConnectionController getUserInfo:[u name]];
		}
		// set the property to the correct user
		[self setUserToShow:[selectedUsers lastObject]];
		
		// show the user info window
		[userInfoWindow makeKeyAndOrderFront:self];
	}
}

- (IBAction)addOrRemoveFriend:(id)sender
{
	// the action changes depending on what is selected
	// the app delegate will send the message to the current controller
	NSArray *selectedUsers = [[NSApp delegate] selectedUsers];
	
	for (User *u in selectedUsers) {
		[museekdConnectionController addOrRemoveFriend:u];
	}
}

- (IBAction)banOrUnbanUser:(id)sender
{
	// the action changes depending on what is selected
	// the app delegate will send the message to the current controller
	NSArray *selectedUsers = [[NSApp delegate] selectedUsers];
	
	for (User *u in selectedUsers) {
		[museekdConnectionController banOrUnbanUser:u];
	}
}

- (IBAction)resume:(id)sender
{
	// only the download view can resume
	if ((selectedView == sbDownloadMenuType) ||
		(selectedView == sbUploadMenuType)) {
		DownloadViewController *dvc = [[NSApp delegate] downloadViewController];
		[dvc resumeTransfers:self];
	}
}

- (IBAction)pause:(id)sender
{
	// only the download view can pause
	if ((selectedView == sbDownloadMenuType) ||
		(selectedView == sbUploadMenuType)) {
		DownloadViewController *dvc = [[NSApp delegate] downloadViewController];
		[dvc pauseTransfers:self];
	}	
}

- (IBAction)clearTransfer:(id)sender
{
	// only the download view can clear
	if ((selectedView == sbDownloadMenuType) ||
		(selectedView == sbUploadMenuType)) {
		DownloadViewController *dvc = [[NSApp delegate] downloadViewController];
		[dvc clearSelectedTransfers:self];
	}
}

- (IBAction)clearAllTransfers:(id)sender
{
	// only the download view can clear
	if ((selectedView == sbDownloadMenuType) ||
		(selectedView == sbUploadMenuType)) {
		DownloadViewController *dvc = [[NSApp delegate] downloadViewController];
		//[dvc clearTransfers:YES];
        [dvc clearAllTransfers];
	}
}

- (IBAction)clearCompleteTransfers:(id)sender
{
	// only the download view can clear
	if ((selectedView == sbDownloadMenuType) ||
		(selectedView == sbUploadMenuType)) {
		DownloadViewController *dvc = [[NSApp delegate] downloadViewController];
		[dvc clearCompleteTransfers];
	}
}

- (IBAction)downloadFolder:(id)sender
{
	switch (selectedView) {
		case sbSearchType:
			[[[NSApp delegate] searchViewController] downloadFolder:self];
			break;
		case sbShareType:
			[[[NSApp delegate] browseViewController] transferFolder:self];
			break;
		default:
			break;
	}
}

- (IBAction)download:(id)sender
{
	switch (selectedView) {
		case sbSearchType:
			// get the selected items from the search view
			[[[NSApp delegate] searchViewController] downloadFile:self];
			
			break;
		case sbShareType:
			// download the selected item in the browse view
			[[[NSApp delegate] browseViewController] transferFiles:self];
			
			break;
		default:
			break;
	}
}

#pragma mark IBAction menu methods

- (IBAction)clearFinishedTransfers:(id)sender
{
	NSPredicate *pred = [NSPredicate predicateWithFormat:
						 @"state == %u OR state == %u", 
						 tfFinished, tfAborted];
	NSArray *transfers = [store findArrayOf:@"Transfer" withPredicate:pred];
	for (Transfer *t in transfers) {
		[museekdConnectionController removeTransfer:t];
	}
}

- (IBAction)addNewFriend:(id)sender
{
	[NSApp beginSheet:newFriendPanel 
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:NULL];
}

- (IBAction)closeFriendSheet:(id)sender
{
	if ([sender isEqual:newFriendOK]) {
		NSString *username = [newFriendName stringValue];
		if ([username length] > 0) {
			User *newFriend = [store getOrAddUserWithName:username];
			
			// check if not already a friend, if so do not remove from friends
			if (![[newFriend isFriend] boolValue]) {
				[museekdConnectionController addOrRemoveFriend:newFriend];
			}
		}
	}
	[newFriendPanel orderOut:nil];
	[NSApp endSheet:newFriendPanel];
	[newFriendName setStringValue:@""];
}

- (IBAction)leaveChatroom:(id)sender
{
    NSInteger row = sidebar.selectedRow;
    id itemAtRow = [sidebar itemAtRow:row];
    if (!itemAtRow) return;
    SidebarItem *selected = [itemAtRow representedObject];
    SidebarType type = [[selected type] unsignedIntValue];
    SidebarItem * sbItem = nil;
    
	if ((type == sbChatType) ||
		(type == sbChatRoomType)) 
    {
		
		// reset the chat view
		ChatViewController *cvc = [[NSApp delegate] chatViewController];
		//[cvc setRoomName:@"" isPrivate:YES];

        if (type == sbChatType)
        {
            [cvc leaveRoom:[selected name] private:YES];
        }
        else
        {
            [cvc leaveRoom:[selected name] private:NO];
        }
        
		
		// leave chatroom
		[museekdConnectionController leaveRoom: selected.name];
        id prevItem = [sidebar itemAtRow:(row - 1)];
        if (prevItem)
        {
            sbItem = [prevItem representedObject];

            if (!([[sbItem type] unsignedIntValue] == sbChatType || [[sbItem type] unsignedIntValue] == sbChatRoomType)) 
            {
                sbItem = [store downloads];
            }
            
        }
        
        // remove the side panel object
		[managedObjectContext deleteObject:selected];
        [self selectItem:sbItem];
	}
}

- (IBAction)removeSearch:(id)sender {
	NSInteger row = sidebar.selectedRow;
	id itemAtRow = [sidebar itemAtRow:row];
	if (!itemAtRow) return;
	
	SidebarItem *selected = [itemAtRow representedObject];
	SearchViewController *svc = [[NSApp delegate] searchViewController];
	
	switch (selectedView) {
		case sbSearchType:
			// clear the search view first
			[svc setCurrentTickets:nil];
			
			// now remove the search ticket from core data
			[museekdConnectionController removeSearchForTickets:selected.tickets];	
			
			// now remove the side item
			[managedObjectContext deleteObject:selected];
			break;
		case sbWishType:
			// clear the search view first
			[svc setCurrentTickets:nil];
			
			// clear the selected wish from the server
			[museekdConnectionController removeWishlistItem:selected.name];
			
			// remove the search ticket if present
			if (selected.tickets) {
				[museekdConnectionController removeSearchForTickets:selected.tickets];
			} 
			[managedObjectContext deleteObject:selected];
			
			break;
		default:
			break;
	}	
}

- (IBAction)changeSearchStyle:(id)sender
{
	[viewSegment setSelectedSegment:[(NSView *) sender tag]];
	[self changeViewStyle:viewSegment];
}

- (IBAction)toggleOnlineStatus:(id)sender
{
	[museekdConnectionController toggleOnlineStatus];
}

- (IBAction)showOrHideWindow:(id)sender
{
	NSWindow *w = nil;
	if ([sender isEqual:menuShowUserInfo]) 
    {
		w = userInfoWindow;
	} 
    else if ([sender isEqual:menuShowChatRooms] || 
             [sender isEqual:showRoomList]) 
    {
		w = chatRoomWindow;
	} 
    else if ([sender isEqual:menuShowMainWindow]) 
    {
		w = [self window];
	}
	else if ([sender isEqual:menuShowConsole])
    {
        w = [console window];
    }
    
	if ([w isKeyWindow]) {
		[w orderOut:self];
	} else {
		[w makeKeyAndOrderFront:self];
	}
}

#pragma mark Mixed IBAction methods

- (IBAction)closeUsernameSheet:(id)sender
{
	[noUsernamePanel orderOut:nil];
	[NSApp endSheet:noUsernamePanel];
	if ([sender isEqual:openPreferencesButton]) {
		[self openPreferences:nil];
	}
}

- (IBAction)closeUPNPSheet:(id)sender
{
	[upnpPanel orderOut:nil];
	[NSApp endSheet:upnpPanel];
	if ([sender isEqual:openRouterButton]) {
		TCMPortMapper *pm = [TCMPortMapper sharedInstance];
		NSURL *url = [NSURL URLWithString:
					  [NSString stringWithFormat:@"http://%@",[pm routerIPAddress]]];
		[[NSWorkspace sharedWorkspace] openURL:url];
	}
}


- (IBAction)removeSideItem:(id)sender {
	NSInteger row = sidebar.selectedRow;
	id itemAtRow = [sidebar itemAtRow:row];
    id prevItem = nil;
	if (!itemAtRow) return;
	SidebarItem *selected = [itemAtRow representedObject];

    SidebarItem * sbItem = nil;
    SidebarType type = [[selected type] unsignedIntValue];
	switch (type) 
    {
		case sbSearchType:
			// clear the search view first
			[[[NSApp delegate] searchViewController] setCurrentTickets:nil];
			
			// now remove the search ticket from core data
			[museekdConnectionController removeSearchForTickets:[selected tickets]];	
			
			// now remove the side item
			[managedObjectContext deleteObject:selected];
			break;
		case sbChatType:
            [[[NSApp delegate] chatViewController] leaveRoom:[selected name] private:YES];
			
			// leave chatroom
			[museekdConnectionController leaveRoom:[selected name]];    
            prevItem = [sidebar itemAtRow:(row - 1)];
            if (prevItem)
            {
                sbItem = [prevItem representedObject];
                if (!([[sbItem type] unsignedIntValue] == sbChatType || [[sbItem type] unsignedIntValue] == sbChatRoomType)) 
                {
                    sbItem = [store downloads];
                }

            }
            
            // remove the side panel object
			[managedObjectContext deleteObject:selected];
            
            [self selectItem:sbItem];
            
            break;
		case sbChatRoomType:
            
			// reset the chat view
			//[[[NSApp delegate] chatViewController] setRoomName:@"" isPrivate:YES];
            [[[NSApp delegate] chatViewController] leaveRoom:[selected name] private:NO];
			
			// leave chatroom
			[museekdConnectionController leaveRoom:[selected name]];
            prevItem = [sidebar itemAtRow:(row - 1)];
            if (prevItem)
            {
                sbItem = [prevItem representedObject];
                if (!([[sbItem type] unsignedIntValue] == sbChatType || [[sbItem type] unsignedIntValue] == sbChatRoomType)) 
                {
                    sbItem = [store downloads];
                }
                
            }
            // remove the side panel object
			[managedObjectContext deleteObject:selected];
            
            [self selectItem:sbItem];
            
			break;
		case sbWishType:
			// clear the search view first
			[[[NSApp delegate] searchViewController] setCurrentTickets:nil];
			
			// clear the selected wish from the server
			[museekdConnectionController removeWishlistItem:[selected name]];
			
			// remove the search ticket if present
			[museekdConnectionController removeSearchForTickets:[selected tickets]];
 
			[managedObjectContext deleteObject:selected];
			
			break;
		case sbShareType:
			// clear the browse view
			[[[NSApp delegate] browseViewController] setFiles:nil];
			
			// then just delete the sidebar entry
			// if the user is browsed again, the
			// file list will be cleared 
			[managedObjectContext deleteObject:selected];			
			
			break;
		default:
			break;
	}
}

- (IBAction)changeView:(id)sender
{
	NSInteger row = [sender selectedRow];
	if (row < 0) return;
	
	id itemAtRow = [sender itemAtRow:row];
	if (!itemAtRow) return;
	
	SidebarItem *selected = [itemAtRow representedObject];
	SidebarType type = [[selected type] unsignedIntValue];
	[self setSelectedView:type];
	
	// choose the correct view based on the type
	[self setSegmentEnabled:NO];
	[self setUserControlsEnabled:NO];
	[self setTransferToolsEnabled:NO];
	[self setDownloadToolsEnabled:NO];
	
	id desiredViewController;
	switch (type) {
		case sbSearchType:
		case sbWishType:
		{
			desiredViewController = [[NSApp delegate] searchViewController];
			
			// filter for the correct search 
			[desiredViewController setValue:[selected tickets] forKey:@"currentTickets"];
			
			[self setSegmentEnabled:YES];
			[self setUserControlsEnabled:YES];
			[self setDownloadToolsEnabled:YES];
			break;
		}
		case sbDownloadMenuType:
		case sbUploadMenuType:
		{
			desiredViewController = [[NSApp delegate] downloadViewController];
			[desiredViewController setValue:[NSNumber numberWithBool:(type == sbUploadMenuType)]
									 forKey:@"uploads"];
			
			[self setUserControlsEnabled:YES];
			[self setTransferToolsEnabled:YES];
			break;
		}		
		case sbChatRoomType:
		case sbChatType:
		{
			desiredViewController = [[NSApp delegate] chatViewController];
			ChatViewController *cvc = desiredViewController;
			
			// filter for the correct room
			[cvc setRoomName:[selected name] isPrivate:(type == sbChatType)];
            //DNSLog(@"Divider %d", [[selected tag] intValue]);
            /* Check for 0 tags, in that case the current tag is assigned */
            if ([[selected tag] intValue] == -1)
            {
                [selected setTag:[cvc getDividerPosition]];
            }
			[cvc setDividerPosition:[[selected tag] floatValue]];
			
			[self setUserControlsEnabled:YES];
			break;
		}
		case sbShareType:
		{
			desiredViewController = [[NSApp delegate] browseViewController];
			
			// get the user for this share
			User *user = [store getOrAddUserWithName:[selected name]];
			
			// set the files in the browse view
			[desiredViewController performSelector:@selector(setFiles:)
										withObject:user];
			
			[self setUserControlsEnabled:YES];
			[self setDownloadToolsEnabled:YES];
			break;
		}
		case sbFriendType:
		{
			desiredViewController = [[NSApp delegate] friendViewController];
			[self setUserControlsEnabled:YES];
			break;
		}
		default:
		{
			desiredViewController = nil;
			break;
		}			
	}
	
	// if set, change the view
	if (desiredViewController) {
		debug_NSLog(@"switching view to %@", [desiredViewController title]);
		[[NSApp delegate] displayViewController:desiredViewController];
	}
}

- (IBAction)popUpMenu:(id)sender
{
	[popUp selectItem:nil];
	[[popUp cell] performClickWithFrame:[sender frame] inView:removeButton];
}

- (IBAction)newSearch:(id)sender
{
	// add a new item to the moc
	// and start editing it
	SidebarItem *item = [[store newSearch] autorelease];
	
	// edit the new row
	[self editItem:item];
}

- (IBAction)newChatroom:(id)sender
{
	// bring up the window to choose chat rooms
	[chatRoomWindow makeKeyAndOrderFront:self];
    
    [self createAndJoinRoom:nil];
}

- (IBAction)newWish:(id)sender
{
	// add a new item to the moc
	// and start editing it
	SidebarItem *item = [[store newWishlistItem] autorelease];
	debug_NSLog(@"New wishlist!");
	[self editItem:item];
}

- (IBAction)joinRooms:(id)sender
{
	// get the selected rooms and add to museek
	NSArray *selected = [roomController selectedObjects];
	debug_NSLog(@"joining %lu rooms", [selected count]);
	
	for (Room *room in selected) {
		[museekdConnectionController joinRoom:[room name]];
	}
	
    //
	// now hide the room list window
	//[chatRoomWindow orderOut:self];
    
    /* I guess we shall move behind the main window not disapper */
    [chatRoomWindow orderWindow:NSWindowBelow relativeTo:[self.window windowNumber]];
    
    //[chatRoomWindow orderBack:self];
}

- (IBAction)createAndJoinRoom:(id)sender
{
    [NSApp beginSheet: createChatRoomPanel
	   modalForWindow: chatRoomWindow
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:NULL];
    
	// get the selected rooms and add to museek
//	NSArray *selected = [roomController selectedObjects];
//	debug_NSLog(@"joining %u rooms", [selected count]);
//	
//	for (Room *room in selected) {
//		[museekdConnectionController joinRoom:[room name]];
//	}
	
}

- (IBAction)acceptCreateChatSheet:(id)sender
{
    NSString * chatName = newChatRoomName.stringValue;
    if ([chatName length] != 0) 
    {        
        SidebarItem * item = nil;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"(name == %@) && (type == %u)", 
                                  chatName, sbChatRoomType];
        item = (SidebarItem *)[store find:@"SidebarItem" withPredicate:predicate];
        
        DNSLog(@"Creating new chat with name %@", chatName);
        [museekdConnectionController joinRoom:chatName];
        
        if (item) 
            [self selectItem:item];
        
        [NSApp endSheet:createChatRoomPanel 
             returnCode: NSOKButton];
        [createChatRoomPanel orderOut:nil];
        
        //[[[NSApp delegate] museekdConnectionController] autojoinChats:@"rano"];
        
        /* Hiding the char room list window */
        [chatRoomWindow orderWindow:NSWindowBelow relativeTo:[self.window windowNumber]];
    }
}

- (IBAction)cancelCreateChatSheet:(id)sender
{
    [NSApp endSheet:createChatRoomPanel 
         returnCode: NSCancelButton];
	[createChatRoomPanel orderOut:nil];
}

- (IBAction)reloadChatRoomList:(id)sender
{
    DNSLog(@"Reloading the chat room list");
    [[[NSApp delegate] museekdConnectionController] reloadRoomList];
}

- (IBAction)openPreferences:(id)sender {
    //DNSLog(@"capro");
	[[PrefsWindowController sharedPrefsWindowController] showWindow:nil];
}

- (void)editItem:(SidebarItem *)item
{
	// select the item in the tree controller
	NSIndexPath *path = [treeController indexPathToObject:item];
	[treeController setSelectionIndexPath:path];
	
	// force the sidebar to reload
	[sidebar reloadData];
	
	// get the tree node item selected
	NSInteger row = [sidebar rowForActualItem:item];
	if (row < 0) {
		NSLog(@"failed to select item %@", item);
		return;
	}
	[sidebar editColumn:0 row:row withEvent:nil select:YES];	
}

- (void)selectItem:(SidebarItem *)item
{
	// select the item in the tree controller
	NSIndexPath *path = [treeController indexPathToObject:item];
	[treeController setSelectionIndexPath:path];
	
	// force the sidebar to reload
	[sidebar reloadData];
	
	// select the item in the sidepanel
	NSInteger row = [sidebar rowForActualItem:item];
	if (row < 0) 
    {
		NSLog(@"failed to select item %@", item);
		return;
	}
	[sidebar selectRowIndexes:[NSIndexSet indexSetWithIndex: (NSUInteger) row] 
		 byExtendingSelection:NO];
	[self changeView:sidebar];
}

#pragma mark menu delegate methods

// set the correct text for the friends menu item
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if ([menu isEqual:soulseekMenu]) {
		switch ([museekdConnectionController state]) {
			case usOnline:
			{
				[connectToSoulseek setTitle:@"Disconnect From Soulseek"];
				[setOnlineStatus setTitle:@"Set Status To Away"];
				[setOnlineStatus setEnabled:YES];
				break;
			}
			case usOffline:
			{
				[connectToSoulseek setTitle:@"Connect To Soulseek"];
				[setOnlineStatus setEnabled:NO];
				break;
			}
			case usAway:
			{
				[connectToSoulseek setTitle:@"Disconnect From Soulseek"];
				[setOnlineStatus setTitle:@"Set Status To Online"];
				[setOnlineStatus setEnabled:YES];
				break;
			}
		}
	}
	else if ([menu isEqual:windowMenu]) {
		[menuShowUserInfo setState:([userInfoWindow isKeyWindow] ? NSOnState : NSOffState)];
		[menuShowChatRooms setState:([chatRoomWindow isKeyWindow] ? NSOnState : NSOffState)];
		[menuShowMainWindow setState:([[self window] isKeyWindow] ? NSOnState : NSOffState)];
        [menuShowConsole setState:([[console window] isKeyWindow] ? NSOnState : NSOffState)];
	}
}

#pragma mark Split View delegate methods

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
	if ([subview isEqual:splitterLeftPane]) return NO;
	return YES;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	return MAX(proposedMin, kMinSplitPosition);
}

#pragma mark Chat view delegate methods

- (void)chatViewDidResize:(NSNumber *)newWidth
{
	// get the currently selected chat view
	NSInteger row = [sidebar selectedRow];
	if (row < 0) return;
	
	// store the width in the tag
	SidebarItem *selected = [[sidebar itemAtRow:row] representedObject];
	SidebarType type = [[selected type] unsignedIntValue];
	if ((type == sbChatType) || (type == sbChatRoomType)) {
		[selected setTag:newWidth];
	}
}

#pragma mark Outline View delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return ([outlineView levelForItem:item] == 0); 
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return ([outlineView levelForItem:item] > 0);
}

// assign icons to the relevant outlineview entries
- (void)outlineView:(NSOutlineView *)outlineView 
	willDisplayCell:(NSCell*)cell 
	 forTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item
{
	SidebarItem *sideItem = (SidebarItem *)[item representedObject];
	
	// if not a top level item, assign an image
	NSImage *myImage;
	if ([sideItem parent]) 
	{
		// set the correct image icon		
		SidebarType type = [[sideItem type] unsignedIntValue];
		
		switch (type) {
				
			case sbSearchType:
			{
				myImage = searchIcon;
				break;
			}
			case sbWishType:
			{
				myImage = wishIcon;
				break;
			}
			case sbFriendType:
			{
				myImage = friendIcon;
				break;
			}
			case sbDownloadMenuType:
			{
				myImage = downloadIcon;
				break;
			}
			case sbUploadMenuType:
			{
				myImage = uploadIcon;
				break;
			}
			case sbChatType:
			{
				myImage = chatIcon;
				break;
			}
			case sbChatRoomType:
			{
				myImage = chatRoomIcon;
				break;
			}
			case sbShareType:
			{
				myImage = sharesIcon;
				break;
			}
			default:
			{
				myImage = nil;
				break;
			}
		}		
	}
	else {
		myImage = nil;
	}
	[(BadgeCell *)cell setImage:myImage];
	NSUInteger count = [(NSNumber *)[sideItem count] unsignedIntValue];
	[(BadgeCell *)cell setBadgeCount:count];
}


// gives the tree sort descriptors for the list
- (NSArray *)treeNodeSortDescriptors
{
	return [NSArray arrayWithObject:[[[NSSortDescriptor alloc] 
									  initWithKey:@"sortIndex" 
									  ascending:YES] 
									 autorelease]];
}


@end
