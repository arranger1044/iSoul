//
//  BrowseViewController.h
//  iSoul
//
//  Created by Richard on 11/11/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DataStore;
@class MuseekdConnectionController;
@class PathNode;
@class User;

@interface BrowseViewController : NSViewController {

	IBOutlet NSTreeController *treeController;
	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSMenuItem *friendMenuItem;
	 
	DataStore *store;
	NSManagedObjectContext *managedObjectContext; 
	MuseekdConnectionController *museek;
	NSString *username;
	NSMutableDictionary *smallIcons;
	NSArray *tableSortDescriptors;
	
	// this is the root node for the file tree
	PathNode *root;
	
	// point to this while the file list is loading
	// or if the user has no files to share
	PathNode *dummyRoot;

	// this holds all the path trees split so far
	NSMutableDictionary *trees;
}

@property (retain) DataStore *store;
@property (retain) NSManagedObjectContext *managedObjectContext;
@property (retain) MuseekdConnectionController *museek;
@property (retain) PathNode *root;
@property (retain) NSArray *tableSortDescriptors;
@property (readonly) NSArray *selectedUsers;

- (void)setFiles:(User *)user;
- (void)splitTree:(NSSet *)files;
- (void)storeTree:(PathNode *)tree;

- (IBAction)transferFiles:(id)sender;
- (IBAction)transferFolder:(id)sender;

@end
