//
//  DownloadViewController.m
//  iSoul
//
//  Created by Richard on 10/30/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "DownloadViewController.h"
#import "Constants.h"
#import "Transfer.h"
#import "User.h"
#import "MuseekdConnectionController.h"
#import "PathNode.h"
#import "DataStore.h"
#import "MainWindowController.h"
#import "iSoul_AppDelegate.h"

#define	kQueueTimerInterval	(5.0 * 60.0)

@implementation DownloadViewController

@synthesize managedObjectContext;
@synthesize museek;
@synthesize uploads;
@synthesize store;

#pragma mark initialisation and deallocation

- (id)init
{
	self = [super initWithNibName:@"DownloadView" bundle:nil];
	if (!self)
		return nil;
	
	[self setTitle:@"Transfers"];
	
	treeRoot = [[PathNode alloc] init];
	[treeRoot setIsFolder:YES];	
	transferNodes = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (void)dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	[queueTimer invalidate];
	[queueTimer release];
	[treeRoot release];
	[store release];
	[transferNodes release];
	[museek release];
	[managedObjectContext release];
	[super dealloc];
}

- (void)awakeFromNib
{
	// register for transfer update notifications
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		   selector:@selector(transferUpdated:) 
			   name:@"TransferStateUpdated" 
			 object:nil];
	
	[nc addObserver:self 
		   selector:@selector(transferRemoved:) 
			   name:@"TransferRemoved" 
			 object:nil];
	
	[nc addObserver:self 
		   selector:@selector(transferFinished:) 
			   name:@"TransferFinished" 
			 object:nil];
	
	// start the queue update timer
	queueTimer = [NSTimer scheduledTimerWithTimeInterval:kQueueTimerInterval 
												  target:self
												selector:@selector(updateQueuePositions:)
												userInfo:nil
												 repeats:YES];
	[queueTimer retain];
}

#pragma mark properties

- (NSArray *)selectedUsers
{
	NSIndexSet *rows = [outlineView selectedRowIndexes];
	if ([rows count] > 0) return [self usersAtIndexes:rows];
	else return nil;
}

- (NSArray *)selectedTransfers
{
	NSIndexSet *rows = [outlineView selectedRowIndexes];
	if ([rows count] > 0) return [self transfersAtIndexes:rows];
	else return nil;
}

- (void)setUploads:(BOOL)isUpload
{
	uploads = isUpload;
	
	// set the correct context menu
	if (isUpload) {
		[outlineView setMenu:uploadMenu];
	} else {
		[outlineView setMenu:downloadMenu];
	}	
	[self populateTree];
}

#pragma mark notification response

- (void)transferUpdated:(NSNotification *)notification
{
	// find the corresponding pathnode
	// if it is not there then create 
	BOOL isNew;
	Transfer *transfer = [notification object];
	if (!transfer) return;	// sent with a nil object when a transfer is removed
	
	// only add down or uploads, depending on which mode we are in
	if ([[transfer isUpload] boolValue] != uploads) return;
	
	PathNode *node = [self findOrCreateNodeForTransfer:transfer isNew:&isNew];
	
	if (isNew) {
		// get the place in the queue for newly added transfers
		[museek getTransferState:transfer];
		[outlineView reloadData];
	} else {
		[outlineView reloadItem:node];
		[outlineView reloadItem:[node parent]];
	}	
}

- (void)transferRemoved:(NSNotification *)notification
{
	Transfer *transfer = [notification object];
	
	// need to remove from the tree and from the cache
	// if the node is not cached, it has been cleared already
	// so just ignore the notification
	PathNode *node = [transferNodes objectForKey:transfer];
	if (node == nil) return;	
	
	[transferNodes removeObjectForKey:transfer];
	PathNode *parent = [node parent];
	if (parent) {
		[[parent children] removeObject:node];
		if ([[parent children] count] == 0) {
			[[[parent parent] children] removeObject:parent];
			[outlineView reloadData];
		} else if ([[parent children] count] == 1) {
			[outlineView reloadData];
		} else {
			[outlineView reloadItem:parent reloadChildren:YES];
		}
	}
	
}

- (void)transferFinished:(NSNotification *)notification
{
	Transfer *transfer = [notification object];
	
	// we want to fetch all transfers from this user
	// that are queued remotely to get a queue update
	if ([[[transfer user] status] unsignedIntValue] != usOffline) 
    {
		NSPredicate *pred = [NSPredicate predicateWithFormat:
							 @"user == %@ && state == %u", 
							 [transfer user], tfQueuedRemotely];
		NSArray *queuedTransfers = [store findArrayOf:@"Transfer" withPredicate:pred];
		
		for (Transfer *t in queuedTransfers) {
			[museek getTransferState:t];
		}							 
	}
}

- (void)updateQueuePositions:(NSTimer *)timer
{
	// only update if the view is visible
	if ([[[NSApp delegate] currentView] isEqual:[self view]]) {
		NSPredicate *pred = [NSPredicate predicateWithFormat:
							 @"state == %u", tfQueuedRemotely];
		NSArray *queuedTransfers = [store findArrayOf:@"Transfer" withPredicate:pred];
		debug_NSLog(@"requesting %lu queue updates", [queuedTransfers count]);
		for (Transfer *t in queuedTransfers) {
			[museek getTransferState:t];
		}		
	}
}

#pragma mark private methods

- (void)populateTree
{
	[treeRoot clearChildren];
	
	// fetch the correct results from the store
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"isUpload == %u", uploads];
	NSArray *transfers = [store findArrayOf:@"Transfer" withPredicate:pred];
	for (Transfer *transfer in transfers) {
		// request the queue position for this transfer
		if ([[transfer state] unsignedIntValue] != tfFinished)
			[museek getTransferState:transfer];
		
		PathNode *node = [self findOrCreateNodeForTransfer:transfer isNew:NULL];
		
		// need to reattach the node to the root
		// so find the top level folder
		while (![[node parent] isEqual:treeRoot] &&
			   [node parent]) {
			node = [node parent];
		} 
		if (![[treeRoot children] containsObject:node]) {
			[treeRoot addChild:node];
		}
		
	}	
	[outlineView reloadData];
}

- (PathNode *)findOrCreateNodeForTransfer:(Transfer *)transfer isNew:(BOOL *)yesOrNo
{
	// check if this transfer has been cached already
	PathNode *node = [transferNodes objectForKey:transfer];
	if (node) {
		if (yesOrNo) *yesOrNo = NO;
		return node;
	}
	
	// not cached, no we need a new node
	// first get the filename and the top folder
	NSString *path = [transfer path];
	NSString *filename, *foldername;
	NSArray *pathComponents = [path componentsSeparatedByString:@"\\"];
	filename = [pathComponents lastObject];
	if ([pathComponents count] == 1) {
		foldername = @"/";
	} else {
		foldername = [pathComponents objectAtIndex:([pathComponents count] - 2)];
	}
	
	// search for a folder with this name and current user
	PathNode *parent = nil;
	for (PathNode *child in [treeRoot children]) {
		if ([child isFolder] && 
			[[child user] isEqual:[transfer user]] &&
			[[child name] isEqualToString:foldername]) {
			parent = child;
			break;
		}
	}
	
	if (!parent) {
		// no matching folder found, create a new one
		parent = [[PathNode alloc] init];
		[parent setIsFolder:YES];
		[parent setName:foldername];
		[parent setRepresentedObject:[transfer user]];
		[treeRoot addSortedChild:parent];
		[parent release];
	}
	
	// now create a new node for this transfer
	node = [[PathNode alloc] init];
	[node setIsFolder:NO];
	[node setName:filename];
	[node setRepresentedObject:transfer];
	[parent addSortedChild:node];
	if (yesOrNo) *yesOrNo = YES;
	
	// cache it for easy retrieval later
	[transferNodes setObject:node forKey:transfer];
	return [node autorelease];	
}

#pragma mark public methods

- (NSArray *)transfersAtIndexes:(NSIndexSet *)indeces
{
	NSMutableArray *selected = [[NSMutableArray alloc] init];
	
	// get all the selected transfers 
	NSUInteger i = indeces.lastIndex;
	while (i != NSNotFound) {
		PathNode *node = [outlineView itemAtRow: (NSInteger) i];
		NSArray *transferList;
		if (node.isFolder) {
			transferList = [self transfersInNode:node];			
		} else {
			transferList = [NSArray arrayWithObject:node.representedObject];
		}
		for (Transfer *t in transferList) {
			if (![selected containsObject:t]) {
				[selected addObject:t];
			}
		}
		i = [indeces indexLessThanIndex:i];
	}	
	
	return [selected autorelease];
}

- (NSArray *)usersAtIndexes:(NSIndexSet *)indeces
{
	NSMutableArray *selected = [[NSMutableArray alloc] init];
	
	// get all the selected transfers 
	NSUInteger i = indeces.lastIndex;
	while (i != NSNotFound) {
		PathNode *node = [outlineView itemAtRow: (NSInteger) i];
		User *u = node.user;
		
		if (![selected containsObject:u]) [selected addObject:u];	
		
		i = [indeces indexLessThanIndex:i];
	}	
	
	return [selected autorelease];
}

// traverse a path tree, adding Transfer objects
// to an array that is returned
- (NSArray *)transfersInNode:(PathNode *)folder
{
	NSMutableArray *toRemove = [[NSMutableArray alloc] init];
	
	for (PathNode *child in [folder children]) {
		if ([child isFolder]) {
			[toRemove addObjectsFromArray:[self transfersInNode:child]];
		} else {
			[toRemove addObject:[child representedObject]];
		}
	}
	NSArray *ret = [NSArray arrayWithArray:toRemove];
	[toRemove release];
	return ret;
}

- (void)clearTransfers:(NSArray *)transfersToRemove
{
    // prompt user if any of the transfers are incomplete
	NSNumber *promptUser = [[NSUserDefaults standardUserDefaults] 
							valueForKey:@"PromptPartialFile"];
	if ([promptUser boolValue]) {
		// check the transfers to clear, see if any are incomplete
		BOOL incomplete = NO;
		for (Transfer *transfer in transfersToRemove) {
			if ([[transfer state] unsignedIntValue] != tfFinished) {
				incomplete = YES;
				break;
			}
		}
		
		if (incomplete) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert setMessageText:@"Transfers Incomplete"];
			[alert setInformativeText:@"Some of the transfers are incomplete. Are you sure you want to remove them?"];
			[alert addButtonWithTitle:@"OK"];
			[alert addButtonWithTitle:@"Cancel"];
			
			if ([alert runModal] == NSAlertSecondButtonReturn) {
				return;
			}	
		}
	}
	
	debug_NSLog(@"removing %lu transfers", [transfersToRemove count]);
	for (Transfer *transfer in transfersToRemove) {
		
		[museek removeTransfer:transfer];
		
		// need to remove from the tree and from the cache
		PathNode *node = [self findOrCreateNodeForTransfer:transfer isNew:NULL];
		[transferNodes removeObjectForKey:transfer];
		PathNode *parent = [node parent];
		if (parent) {
			[[parent children] removeObject:node];
			if ([[parent children] count] == 0) {
				[[[parent parent] children] removeObject:parent];
			}
		}		
	}
	[outlineView reloadData];
}

- (void)clearAllTransfers
{
	NSIndexSet * rows = [NSIndexSet indexSetWithIndexesInRange:
                         NSMakeRange(0, (NSUInteger) [outlineView numberOfRows])];

	NSArray * transfersToRemove = [self transfersAtIndexes:rows];
	[self clearTransfers:transfersToRemove];
}

- (void)clearCompleteTransfers
{
    /* Shall get the completed transfers */
}

- (IBAction)pauseTransfers:(id)sender
{
	NSArray *selectedTransfers = [self selectedTransfers];
	
	debug_NSLog(@"pausing %lu transfers", [selectedTransfers count]);
	for (Transfer *transfer in selectedTransfers) {
		[museek abortTransfer:transfer];
	}
}

- (IBAction)resumeTransfers:(id)sender
{
	NSArray *selectedTransfers = [self selectedTransfers];
	
	debug_NSLog(@"resuming %lu transfers", [selectedTransfers count]);
	for (Transfer *transfer in selectedTransfers) {
		[museek resumeTransfer:transfer];
	}	
}

- (IBAction)clearSelectedTransfers:(id)sender
{
    NSIndexSet * rows = [outlineView selectedRowIndexes];
    
	NSArray * transfersToRemove = [self transfersAtIndexes:rows];
	[self clearTransfers:transfersToRemove];
	//[self clearTransfers:NO];
}

#pragma mark outline view datasource methods

// use a datasource instead of a tree controller
// so only children can be displayed as root items
// while still keeping a more useful folder structure
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)i ofItem:(id)item
{
	if (item) {
		PathNode *node = (PathNode *)item;
		return [node.children objectAtIndex: (NSUInteger) i];
	} else {
		PathNode *child = [treeRoot.children objectAtIndex: (NSUInteger) i];
		if (child.isFolder && (child.children.count == 1)) {
			return child.children.lastObject;
		} else {
			return child;
		}
	}	
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	PathNode *node = (PathNode *)item;
	
	return node.isFolder;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	PathNode *node;
	if (item) {
		node = (PathNode *)item;
	} else {
		node = treeRoot;
	}
	
	return (NSInteger) node.children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
		   byItem:(id)item
{
	return item;
}

#pragma mark outline view delegate methods

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	PathNode *node = (PathNode *)item;
	
	// big row if top level, or if only child
	if ([node.parent isEqual:treeRoot] ||
		(node.parent.children.count == 1)) {
		return 32.0;
	} else {
		return 16.0;
	}
}

// store the expanded state of the node
// so that the tree can be restored when changing between users
- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	PathNode *node = [[notification userInfo] valueForKey:@"NSObject"];
	[node setIsExpanded:YES];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	PathNode *node = [[notification userInfo] valueForKey:@"NSObject"];
	[node setIsExpanded:NO];
}


#pragma mark outlineview delegate methods

// set the correct text for the friends menu item
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSArray *results = [self selectedTransfers];
	if ([results count] > 0) {

		Transfer *transfer = [results lastObject];
		BOOL isFriend = [[[transfer user] isFriend] boolValue];
	
		if ([menu isEqual:downloadMenu]) {
			if (isFriend) {
				[downloadFriendMenuItem setTitle:@"Remove From Friends"];
			} else {
				[downloadFriendMenuItem setTitle:@"Add To Friends"];
			}
		} else {
			if (isFriend) {
				[uploadFriendMenuItem setTitle:@"Remove From Friends"];
			} else {
				[uploadFriendMenuItem setTitle:@"Add To Friends"];
			}
			
			if ([[[transfer user] isBanned] boolValue]) {
				[banUserMenuItem setTitle:@"Unban User"];
			} else {
				[banUserMenuItem setTitle:@"Ban User"];
			}
		}		
		
	} 
}


@end
