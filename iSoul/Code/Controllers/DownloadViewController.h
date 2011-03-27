//
//  DownloadViewController.h
//  iSoul
//
//  Created by Richard on 10/30/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DataStore;
@class ExpandingDatasourceOutlineView;
@class MuseekdConnectionController;
@class PathNode;
@class Transfer;

@interface DownloadViewController : NSViewController {

	IBOutlet ExpandingDatasourceOutlineView *outlineView;
	IBOutlet NSMenu *downloadMenu;
	IBOutlet NSMenu *uploadMenu;	
	IBOutlet NSMenuItem *downloadFriendMenuItem;
	IBOutlet NSMenuItem *uploadFriendMenuItem;
	IBOutlet NSMenuItem *banUserMenuItem;	
	
	MuseekdConnectionController *museek;
	NSManagedObjectContext *managedObjectContext;
	DataStore *store;
	id delegate;
	BOOL uploads;
	
	// the root of the transfer tree
	// to show in an outline view
	// the transfers need to be held
	// in a folder structure
	PathNode *treeRoot;
	NSMutableDictionary *transferNodes;
	
	// this timer causes the queue positions
	// for remotely queued transfers to be
	// updated, only requests when the view is visible
	NSTimer *queueTimer;
}

@property (retain) NSManagedObjectContext *managedObjectContext;
@property (retain) MuseekdConnectionController *museek;
@property (retain) DataStore *store;
@property (nonatomic) BOOL uploads;
@property (readonly) NSArray *selectedUsers;
@property (readonly) NSArray *selectedTransfers;

// menu methods
- (IBAction)pauseTransfers:(id)sender;
- (IBAction)resumeTransfers:(id)sender;
- (IBAction)clearSelectedTransfers:(id)sender;

// public methods
//- (void)clearTransfers:(BOOL)all;
//- (void)clearTransfers:(NSArray *)transfersToRemove;
- (void)clearAllTransfers;
- (void)clearCompleteTransfers;
// private methods
- (void)populateTree;
- (void)transferUpdated:(NSNotification *)notification;
- (void)transferRemoved:(NSNotification *)notification;
- (void)transferFinished:(NSNotification *)notification;
- (void)updateQueuePositions:(NSTimer *)timer;
- (NSArray *)transfersAtIndexes:(NSIndexSet *)indeces;
- (NSArray *)usersAtIndexes:(NSIndexSet *)indeces;
- (NSArray *)transfersInNode:(PathNode *)folder;
- (PathNode *)findOrCreateNodeForTransfer:(Transfer *)transfer isNew:(BOOL *)yesOrNo;

@end
