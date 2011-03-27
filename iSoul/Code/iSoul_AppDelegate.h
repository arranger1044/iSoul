//
//  iSoul_AppDelegate.h
//  iSoul
//
//  Created by Richard on 10/26/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@class SearchViewController;
@class MainWindowController;
@class DownloadViewController;
@class ChatViewController;
@class BrowseViewController;
@class FriendViewController;
@class DataStore;
@class MuseekdController;
@class MuseekdConnectionController;

@interface iSoul_AppDelegate : NSObject<GrowlApplicationBridgeDelegate>
{
    NSWindow *window;
    
	// holds the different views for the main window
	IBOutlet NSSplitView *splitView;
	IBOutlet NSScrollView *mainView;
	IBOutlet MainWindowController * mainWindowController;
	SearchViewController *searchViewController;
	DownloadViewController *downloadViewController;
	ChatViewController *chatViewController;
	BrowseViewController *browseViewController;
	FriendViewController *friendViewController;
	DataStore *store;
	MuseekdController *museekdController;
	MuseekdConnectionController *museekdConnectionController;
	NSViewController *currentViewController;
	
	// core data gubbins
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

@property (readonly) SearchViewController *searchViewController;
@property (readonly) DownloadViewController *downloadViewController;
@property (readonly) ChatViewController *chatViewController;
@property (readonly) BrowseViewController *browseViewController;
@property (readonly) FriendViewController *friendViewController;
@property (readonly) DataStore *store;
@property (readonly) MuseekdController *museekdController;
@property (readonly) MuseekdConnectionController *museekdConnectionController;
@property (readonly) MainWindowController *mainWindowController;
@property (readonly) NSView *currentView;
@property (readonly) id currentViewController;
@property (readonly) NSArray *selectedUsers;
@property (readonly) NSArray *selectedTransfers;
@property (nonatomic, retain) IBOutlet NSWindow *window;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;
- (void)displayViewController:(NSViewController *)vc;
- (void)scanSharesFile:(id)sender;
- (void)connectToMuseekd:(NSNumber *)localMuseekd;

@end
