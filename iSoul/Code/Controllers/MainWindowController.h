//
//  MainWindowController.h
//  iSoul
//
//  Created by Richard on 10/27/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"

@class BottomBar;
@class DataStore;
@class ExpandingSidebar;
@class MuseekdConnectionController;
@class MuseekdController;
@class SidebarItem;
@class User;
@class LoggingConsole;

@interface MainWindowController : NSWindowController {
	IBOutlet NSSplitView *splitView;
	IBOutlet NSView *splitterLeftPane;
	IBOutlet NSView *splitterRightPane;
	IBOutlet ExpandingSidebar *sidebar;
	IBOutlet NSTreeController *treeController;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSButton *removeButton;
	IBOutlet NSPopUpButton *popUp;
	IBOutlet NSWindow *chatRoomWindow;
	IBOutlet NSArrayController *roomController;
	IBOutlet NSTableView *roomList;
	IBOutlet NSWindow *userInfoWindow;
    //IBOutlet NSWindow * console;
	IBOutlet NSPanel *newFriendPanel;
    IBOutlet NSPanel *createChatRoomPanel;
	IBOutlet NSPanel *noUsernamePanel;
	IBOutlet NSPanel *upnpPanel;
	IBOutlet NSTextField *newFriendName;
	IBOutlet NSButton *newFriendOK;
	IBOutlet NSSegmentedControl *viewSegment;
	IBOutlet NSMenuItem *connectToSoulseek;
	IBOutlet NSMenuItem *setOnlineStatus;
	IBOutlet BottomBar *bottomBar;
	IBOutlet NSButton *openPreferencesButton;
	IBOutlet NSButton *openRouterButton;
	IBOutlet NSMenuItem *menuShowMainWindow;
	IBOutlet NSMenuItem *menuShowUserInfo;
	IBOutlet NSMenuItem *menuShowChatRooms;
    IBOutlet NSMenuItem * menuShowConsole;
	IBOutlet NSMenu *soulseekMenu;
	IBOutlet NSMenu *windowMenu;
    IBOutlet NSToolbarItem * showRoomList;
	
	NSManagedObjectContext *managedObjectContext;
	MuseekdConnectionController *museekdConnectionController;
	DataStore *store;	
	User *userToShow;
    
    LoggingConsole * console;
	
	// controls which parts of the toolbar are enabled
	SidebarType selectedView;
	BOOL segmentEnabled;
	BOOL userControlsEnabled;
	BOOL transferToolsEnabled;
	BOOL downloadToolsEnabled;
	
	// preload the sidebar icons
	NSImage *downloadIcon;
	NSImage *uploadIcon;
	NSImage *searchIcon;
	NSImage *wishIcon;
	NSImage *friendIcon;
	NSImage *chatIcon;
	NSImage *chatRoomIcon;
	NSImage *sharesIcon;
	
	NSArray *roomSortDescriptors;
}

@property (retain) NSManagedObjectContext *managedObjectContext;
@property (retain) NSArray *roomSortDescriptors;
@property (retain) User *userToShow;
@property (retain) DataStore *store;
@property (retain) MuseekdConnectionController *museekdConnectionController;
@property (nonatomic) BOOL segmentEnabled;
@property BOOL userControlsEnabled;
@property BOOL transferToolsEnabled;
@property BOOL downloadToolsEnabled;
@property SidebarType selectedView;
@property (nonatomic, retain) LoggingConsole * console;

// toolbar methods
- (IBAction)connectOrDisconnect:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)changeViewStyle:(id)sender;
- (IBAction)privateChat:(id)sender;
- (IBAction)browseUser:(id)sender;
- (IBAction)userInfo:(id)sender;
- (IBAction)addOrRemoveFriend:(id)sender;
- (IBAction)banOrUnbanUser:(id)sender;
- (IBAction)resume:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)clearTransfer:(id)sender;
- (IBAction)clearAllTransfers:(id)sender;
- (IBAction)clearCompleteTransfers:(id)sender;
- (IBAction)downloadFolder:(id)sender;
- (IBAction)download:(id)sender;

// menu methods
- (IBAction)clearFinishedTransfers:(id)sender;
- (IBAction)addNewFriend:(id)sender;
- (IBAction)closeFriendSheet:(id)sender; 
- (IBAction)leaveChatroom:(id)sender;
- (IBAction)removeSearch:(id)sender;
- (IBAction)changeSearchStyle:(id)sender;
- (IBAction)toggleOnlineStatus:(id)sender;
- (IBAction)showOrHideWindow:(id)sender;

- (IBAction)closeUsernameSheet:(id)sender;
- (IBAction)closeUPNPSheet:(id)sender;
- (IBAction)changeView:(id)sender;
- (IBAction)removeSideItem:(id)sender;
- (IBAction)popUpMenu:(id)sender;
- (IBAction)newSearch:(id)sender;
- (IBAction)newChatroom:(id)sender;
- (IBAction)newWish:(id)sender;
- (IBAction)joinRooms:(id)sender;
- (IBAction)openPreferences:(id)sender;

- (void)sidebarCountUpdated:(NSNotification *)notification;
- (void)transferUpdated:(NSNotification *)notification;
- (void)transferAdded:(NSNotification *)notification;
- (void)finishedEditing:(NSNotification *)notification;
- (void)browseListLoaded:(NSNotification *)notification;
- (void)buddiesUpdated:(NSNotification *)notification;
- (void)restartMuseek:(NSNotification *)notification;
- (void)displayError:(NSNotification *)notification;
- (void)expandNode:(NSNotification *)notification;
- (void)portMapperDidStartWork:(NSNotification *)notification;
- (void)portMapperDidFinishWork:(NSNotification *)notification;

- (void)checkUsername;
- (void)editItem:(SidebarItem *)item;
- (void)selectItem:(SidebarItem *)item;
- (void)chatViewDidResize:(NSNumber *)newWidth;
- (void)performSearch:(NSString *)searchTerm;

@end
