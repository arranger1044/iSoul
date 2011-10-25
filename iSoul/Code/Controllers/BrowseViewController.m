//
//  BrowseViewController.m
//  iSoul
//
//  Created by Richard on 11/11/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "BrowseViewController.h"
#import "PathNode.h"
#import "Result.h"
#import "Constants.h"
#import "User.h"
#import "MuseekdConnectionController.h"
#import "DataStore.h"
#import "MainWindowController.h"

@implementation BrowseViewController

@synthesize managedObjectContext;
@synthesize museek;
@synthesize root;
@synthesize store;
@synthesize tableSortDescriptors;

- (id)init
{
	if (![super initWithNibName:@"BrowseView" bundle:nil]) {
		return nil;
	}
	[self setTitle:@"Browse"];
	
	// cache the images shown in the browser cells
	smallIcons = [[NSMutableDictionary alloc] init];
	trees = [[NSMutableDictionary alloc] init];
	dummyRoot = [[PathNode alloc] init];
	[dummyRoot setName:@"File List Loading ..."];
	[dummyRoot setIsFolder:YES];
	[dummyRoot setIsExpanded:YES];
	
	NSSortDescriptor *isFolder = [[NSSortDescriptor alloc] 
								   initWithKey:@"isFolder" 
								   ascending:NO];	
	NSSortDescriptor *name = [[NSSortDescriptor alloc] 
							   initWithKey:@"name" 
							   ascending:YES
							   selector:@selector(localizedCaseInsensitiveCompare:)];
	[self setTableSortDescriptors:[NSArray arrayWithObjects:isFolder,name,nil]];
	[isFolder release];
	[name release];
	
	return self;
}

- (void)dealloc
{
	[tableSortDescriptors release];
	[store release];
	[smallIcons release];
	[dummyRoot release];
	[museek release];
	[managedObjectContext release];
	[username release];
	[root release];
	[trees release];
	[super dealloc];
}

- (void)awakeFromNib
{
	[outlineView setTarget:self];
	[outlineView setDoubleAction:@selector(transferFiles:)];
}

- (NSArray *)selectedUsers
{
	if (username) {
		User *u = [store getOrAddUserWithName:username];
		return [NSArray arrayWithObject:u];
	} 
	return nil;
}

- (void)setFiles:(User *)user
{
	if (user) {
		// check if it is the same user
		if (![username isEqualToString:[user name]]) {
			[username release];
			username = [[user name] copy];
		}
				
		// check the dictionary for this tree path
		PathNode *tree = [trees valueForKey:username];
		
		if (tree) {
			[self setRoot:tree];
		}
		else {
			// check if the user has any files
			if (![user files] || [[user files] count] == 0) {
				
				if ([[user browseListReceived] boolValue]) {
					// an empty list has loaded
					// so create a dummy file node
					[dummyRoot setName:@"No Files Shared ..."];
				} else {
					// the list is still loading
					[dummyRoot setName:@"File List Loading ..."];
				}
				
				[self setRoot:dummyRoot];
				return;
			}			
			
			// takes about 5 seconds to sort 30000 files on a macmini
			debug_NSLog(@"started splitting new tree");
			[NSThread detachNewThreadSelector:@selector(splitTree:) 
									 toTarget:self withObject:[user files]];	
		}		
	} else {
		// just clear the current resources
		[username release]; username = nil;
		[self setRoot:nil];
	}
}

- (void)splitTree:(NSSet *)files
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	PathNode *tree = [PathNode walkedTreeFromSet:files];
	[tree setIsExpanded:YES];
	debug_NSLog(@"finished splitting file tree");
	
	// point the tree folder to the user for the files
	[tree setRepresentedObject:[(Result *)[files anyObject] user]];
	
	[self performSelectorOnMainThread:@selector(storeTree:) 
						   withObject:tree waitUntilDone:YES];
	[pool release];
}

- (void)storeTree:(PathNode *)tree
{
	User *user = [tree representedObject];
	
	// add the tree to the dictionary if
	// we are looking at the whole file list
	if ([[user browseListReceived] boolValue]) {
		[trees setValue:tree forKey:[user name]];
	}	
	
	// if we are still looking at the same user
	// then set the tree root accordingly
	if ([username isEqualToString:[user name]]) {
		[self setRoot:tree];
	}
}

#pragma mark IBAction methods

- (IBAction)transferFiles:(id)sender
{
	NSArray *nodes = [treeController selectedObjects];
	NSMutableArray *folders = [[NSMutableArray alloc] init];
	
	for (PathNode *node in nodes) {
		if ([node isFolder]) {
			// cache the username so we do not download 
			// a file of a folder that is already downloading
			debug_NSLog(@"downloading folder %@", [node name]);
			[folders addObject:[node path]];
			[museek downloadFolder:[node path] fromUser:username];
		}
		else {
			// get the folder name
			NSRange r = [[node path] rangeOfString:@"\\" options:NSBackwardsSearch];
			if (r.location != NSNotFound) {
				NSString *folder = [[node path] substringToIndex:r.location];
				if ([folders containsObject:folder]) {
					// already downloading this entire folder
					debug_NSLog(@"skipping download of %@, already downloading folder", [node path]);
					continue;
				}
			}
			[museek downloadFile:[node representedObject]];
		}
	}
	[folders release];
}

- (IBAction)transferFolder:(id)sender
{
	NSArray *nodes = [treeController selectedObjects];
	NSMutableArray *folders = [[NSMutableArray alloc] init];
	
	for (PathNode *node in nodes) {
		PathNode *parent = [node parent];
		if (!parent) continue;
		
		// check if we are already downloading this folder
		// or any folder that is a parent of this one
		BOOL skip = NO;
		NSRange r;
		for (NSString *folder in folders) {
			if ([folder isEqual:[parent path]]) {
				debug_NSLog(@"skipping folder %@, already downloading", folder);
				skip = YES;
				break;
			}
			
			// check if the current folder is a child
			r = [[parent path] rangeOfString:folder];
			if (r.location != NSNotFound) {
				debug_NSLog(@"skipping folder %@, already downloading folder %@", [parent path], folder);
				skip = YES;
				break;
			}
		}
		
		if (skip) continue;
		
		debug_NSLog(@"downloading folder %@", [parent path]);
		[folders addObject:[parent path]];
		[museek downloadFolder:[parent path] fromUser:username];
	}
	[folders release];
}

#pragma mark OutlineView delegate methods

- (void)outlineView:(NSOutlineView *)outlineView 
	willDisplayCell:(id)cell 
	 forTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item
{
	PathNode *node = (PathNode *)[item representedObject];
	if ([[tableColumn identifier] isEqualToString:@"filename"]) {
				
		NSImage *myImage = nil;
		if ([node isFolder]) {
			if ([node isExpanded]) {
				myImage = [[NSWorkspace sharedWorkspace] 
						   iconForFileType:NSFileTypeForHFSTypeCode(kOpenFolderIcon)];
			} else {
				myImage = [[NSWorkspace sharedWorkspace] 
						   iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
			}
			[myImage setScalesWhenResized:YES];
			[myImage setSize:NSMakeSize(16.0, 16.0)];
		} else {
			// get correct image from filename
			NSString *extension = [[[node name] pathExtension] lowercaseString];
			
			// get the icon to use from the cache
			myImage = [smallIcons valueForKey:extension];
			if (!myImage) {
				// not cached, so fetch the image and resize it
				myImage = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
				[myImage setScalesWhenResized:YES];
				[myImage setSize:NSMakeSize(16.0, 16.0)];
				[smallIcons setValue:myImage forKey:extension];
			}
		}
		[cell setImage:myImage];
	}
}

// store the expanded state of the node
// so that the tree can be restored when changing between users
- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	PathNode *node = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];
	[node setIsExpanded:YES];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	PathNode *node = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];
	[node setIsExpanded:NO];
}

// expand a folder when it is selected in the outline view
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSIndexSet *selected = outlineView.selectedRowIndexes;
	if (selected.count != 1) return;
	
	NSInteger i = (NSInteger) selected.firstIndex;
	PathNode *node = [[outlineView itemAtRow:i] representedObject];
	if (node.isFolder && !node.isExpanded) {
		[outlineView expandItem:[outlineView itemAtRow:i]];
	}
}

#pragma mark menu delegate methods

// set the correct text for the friends menu item
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	// the user to send the message to
	User *u = [store getOrAddUserWithName:username];
	BOOL isFriend = [[u isFriend] boolValue];
	
	if (isFriend) {
		[friendMenuItem setTitle:@"Remove From Friends"];
	} else {
		[friendMenuItem setTitle:@"Add To Friends"];
	}
}

@end
