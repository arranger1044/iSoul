//
//  DownloadViewController.h
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"

@class MuseekdConnectionController;
@class PathNode;
@class Ticket;

@interface SearchViewController : NSViewController {
	// the three separate views correspond to the 
	// different represenations of search results
	IBOutlet NSView *listView;
	IBOutlet NSView *folderView;
	IBOutlet NSView *browserView;	
	
	IBOutlet NSArrayController *resultsController;	// controls all the search results
	IBOutlet NSTreeController *treeController;		// controls the current file tree
	IBOutlet NSArrayController *browseController;	// controls the currently selected browse folder
	IBOutlet NSTableView *listTable;
	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSBrowser *userBrowser;
	IBOutlet NSTableView *browseTable;
	IBOutlet NSMenuItem *friendMenuItem;
	IBOutlet NSMenuItem *downloadMenuItem;
	
	MuseekdConnectionController *museek;
	NSManagedObjectContext *managedObjectContext;
	NSSet *currentTickets;
	BOOL isAwake;
	BOOL sortPending;
	NSTimer *sortTimer;
	
	// holds the icons for the file list
	NSMutableDictionary *smallIcons;
	
	// holds the current tree representation
	// for the entire folder view
	PathNode *treeRoot; 
	
	// holds the sorted trees for each user
	// stored as a tree with each user
	// having a root folder with their username
	PathNode *userRoot;
	
	// holds the contents of the currently
	// selected user folder
	NSArray *folderContents;
	
	// the current view style
	ViewState viewState;
	
	// performs the file tree splitting
	// on other threads, should speed things a bit
	NSOperationQueue *queue;
	
	NSArray *listSortDescriptors;
	NSArray *treeSortDescriptors;
}

@property (retain) MuseekdConnectionController *museek;
@property (retain) NSManagedObjectContext *managedObjectContext;
@property (retain) NSSet *currentTickets;
@property (retain) NSArray *listSortDescriptors;
@property (retain) NSArray *treeSortDescriptors;
@property (retain) PathNode *treeRoot;
@property (retain) NSArray *folderContents;
@property (readwrite) ViewState viewState;
@property (readonly) NSArray *selectedUsers;

// public methods
- (IBAction)downloadFile:(id)sender;
- (IBAction)downloadFolder:(id)sender;
- (IBAction)browserSelected:(id)sender;

// private methods
- (void)setFetchPredicate;
- (void)addSetToFileTree:(NSSet *)fileSet sortImmediately:(BOOL)yesOrNo;
- (void)addFolderToTree:(NSMutableArray *)list shouldSort:(BOOL)yesOrNo;
- (void)resortTables:(NSTimer *)timer;
- (void)splitFinished:(NSNotification *)notification;
- (void)addTreesToRoots:(NSNotification *)notification;

@end
