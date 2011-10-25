//
//  DownloadViewController.m
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "SearchViewController.h"
#import "ImageAndTextCell.h"
#import "Result.h"
#import "User.h"
#import "MuseekdConnectionController.h"
#import "Ticket.h"
#import "PathNode.h"
#import "SplitOperation.h"
#import "MainWindowController.h"

#define kSortInterval	3.0

@implementation SearchViewController
@synthesize managedObjectContext;
@synthesize currentTickets;
@synthesize museek;
@synthesize treeRoot;
@synthesize viewState;
@synthesize folderContents;
@synthesize listSortDescriptors;
@synthesize treeSortDescriptors;

- (void)loadLastViewState{
    
    NSInteger vState = [NSUserDefaults.standardUserDefaults integerForKey:@"SelectedSegmentView"];
    switch (vState) 
    {
        case 0:
            viewState = vwList;
            break;
        case 1:
            viewState = vwFolder;
            break;
        case 2:
            viewState = vwBrowse;
            break;
        default:
            break;
    }
}

- (id)init {
	self = [super initWithNibName:@"SearchView" bundle:nil];
	if (!self)
		return nil;
	
	[self setTitle:@"Search"];
	
	// do not bother splitting files until the nib is awake
	// otherwise the result notifications are ignored
	isAwake = NO;
	
	// cache the resized icon images
	smallIcons = [[NSMutableDictionary alloc] init];
	
	// stores the current file tree
	treeRoot = [[PathNode alloc] init];
	
	// stores each users tree separately
	userRoot = [[PathNode alloc] init];
	
	// indicates which of the search views is showing
    /* This shall be read from NSUserDefaults */
    //viewState = vwList;
    [self loadLastViewState];
	
	// splits file trees in the background
	// otherwise the main thread is totally blocked
	queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:
	 NSOperationQueueDefaultMaxConcurrentOperationCount];	
	
	// only sort the search results every so often
	// otherwise the folder view blocks the ui
	sortTimer = [NSTimer scheduledTimerWithTimeInterval:kSortInterval 
												 target:self
											   selector:@selector(resortTables:)
											   userInfo:nil
												repeats:YES];
	[sortTimer retain];
	sortPending = NO;
	
	// set the default sort descriptors
	NSSortDescriptor *freeSlots = [[NSSortDescriptor alloc] 
									initWithKey:@"user.hasFreeSlots.boolValue" 
									ascending:NO];	
	NSSortDescriptor *uploadSpeed = [[NSSortDescriptor alloc] 
									  initWithKey:@"user.averageSpeed.intValue" 
									  ascending:NO];	
	NSSortDescriptor *queueLength = [[NSSortDescriptor alloc] 
									  initWithKey:@"user.queueLength.intValue" 
									  ascending:YES];	
	NSSortDescriptor *filename = [[NSSortDescriptor alloc] 
								   initWithKey:@"fullPath" 
								   ascending:YES];
	NSSortDescriptor *name = [[NSSortDescriptor alloc] 
								   initWithKey:@"name" 
								   ascending:YES];
	
	listSortDescriptors = [[NSArray alloc] initWithObjects:freeSlots,uploadSpeed,queueLength,filename,nil];
	treeSortDescriptors = [[NSArray alloc] initWithObjects:freeSlots,uploadSpeed,queueLength,name,nil];
	[freeSlots release];
	[uploadSpeed release];
	[queueLength release];
	[filename release];
	[name release];
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[sortTimer invalidate];
	[sortTimer release];
	[listSortDescriptors release];
	[treeSortDescriptors release];
	[queue release];
	[folderContents release];
	[smallIcons release];
	[treeRoot release];
	[userRoot release];
	[currentTickets release];
	[museek release];
	[managedObjectContext release];
	[super dealloc];
}

- (void)awakeFromNib {
	// set the double click target to download files
	[listTable setTarget:self];
	[listTable setDoubleAction:@selector(downloadFile:)];
	
	// watch for file tree split operations finishing
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(splitFinished:) 
												 name:@"SplitTreeFinished" 
											   object:nil];
	
	// need to set the initial search predicate
	// as we have only just started looking for notifications
	isAwake = YES;
	[self setFetchPredicate];
	[self setViewState:viewState];
}

#pragma mark properties

- (NSArray *)selectedUsers {
	NSArray *results = [resultsController selectedObjects];
	
	if ([results count] > 0) {
		NSMutableArray *selected = [[NSMutableArray alloc] init];
		
		for (Result *r in results) {
			if (![selected containsObject:[r user]])
				[selected addObject:[r user]];
		}
		return [selected autorelease];
	} else {
		return nil;
	}
}

// filters the search results for this ticket only
- (void)setCurrentTickets:(NSSet *)newTickets {
	if ([newTickets isEqual:currentTickets]) return;
	
	// stop observing changes in the old ticket
	for (Ticket *t in currentTickets)
		[t removeObserver:self forKeyPath:@"files"];
	[queue cancelAllOperations];
	
	// clear the current file trees
	[treeRoot clearChildren];
	[userRoot clearChildren];
	[self setFolderContents:nil];
	[userBrowser loadColumnZero];
	[treeController rearrangeObjects];
	
	[currentTickets release];
	currentTickets = [newTickets retain];
	[self setFetchPredicate];	// once the nib is awake, the results will be split here
}

- (void)setViewState:(ViewState)newState {
	//if (viewState == newState) return;
	
	viewState = newState;
	switch (viewState) {
		case vwList:
			[self setView:listView];
			[resultsController rearrangeObjects];
			break;
		case vwFolder:
			[self setView:folderView];
			NSLog(@"folder tree has %lu children", [[treeRoot children] count]);
			[treeController rearrangeObjects];
			NSLog(@"folder tree has %lu children", [[treeRoot children] count]);
			[outlineView reloadData];
			break;
		case vwBrowse:
			[self setView:browserView];
			[userBrowser loadColumnZero];
			break;
	}
}


#pragma mark notification responses

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context {
	
	if ([currentTickets containsObject:object]) {
		NSSet *newItems = [change objectForKey:NSKeyValueChangeNewKey];
		if ([newItems count] > 0)	// split the new items and add to the tree
			[self addSetToFileTree:newItems sortImmediately:NO];	
	}
}

#pragma mark public methods

- (IBAction)downloadFile:(id)sender {
	NSArray *selected = nil;
	NSArray *selectedNodes = nil;
	
	switch (viewState) {
		case vwList:
			selected = [resultsController selectedObjects];
			break;
		case vwFolder:
			selectedNodes = [treeController selectedObjects];
			
			// download folders and files separately
			// don't worry about duplicates, museekd takes care of it
			NSMutableArray *files = [[NSMutableArray alloc] init];
			for (PathNode *node in selectedNodes) {
				if ([node isFolder]) {
					[museek downloadFolder:[node path] fromUser:[[node representedObject] name]];
				} else {
					[files addObject:[node representedObject]];
				}
			}
			selected = [NSArray arrayWithArray:files];
			[files release];
			break;
		case vwBrowse:
			selected = [browseController selectedObjects];
			break;
	}	
	
	debug_NSLog(@"downloading %lu results", [selected count]);
	for (id result in selected)
		[museek downloadFile:result];
}

- (IBAction)downloadFolder:(id)sender {
	NSArray *selected = nil;
	NSArray *selectedNodes = nil;
	
	switch (viewState) {
		case vwList:
			selected = [resultsController selectedObjects];
			break;
		case vwFolder:
			selectedNodes = [treeController selectedObjects];
			
			// download folders and files separately
			// don't worry about duplicates, museekd takes care of it
			NSMutableArray *files = [[NSMutableArray alloc] init];
			for (PathNode *node in selectedNodes) {
				if ([node isFolder]) {
					if ([[node parent] isEqual:treeRoot]) {
						// this is a root node, so just download this folder
						[museek downloadFolder:[node path] fromUser:[[node user] name]];
					} else {
						[museek downloadFolder:[[node parent] path] 
									  fromUser:[[[node parent] representedObject] name]];
					}
				} else {
					[files addObject:[node representedObject]];
				}
			}
			selected = [NSArray arrayWithArray:files];
			[files release];
			break;
		case vwBrowse:
			selected = [browseController selectedObjects];
			break;
	}	
		
	// get the folder path from the full file path
	for (Result *result in selected) {
		NSRange r = [[result fullPath] rangeOfString:@"\\" options:NSBackwardsSearch];
		if (r.location == NSNotFound) {
			NSLog(@"error getting folder from path %@", [result fullPath]);
			continue;
		}		
		NSString *path = [[result fullPath] substringToIndex:r.location];
		debug_NSLog(@"downloading folder %@ from user %@", path, [[result user] name]);
		[museek downloadFolder:path fromUser:[[result user] name]]; 
	}
}

- (IBAction)browserSelected:(id)sender {
	// get the currently selected node
	PathNode *node = [[userBrowser selectedCell] representedObject];
	
	// get the files of the node and set them as the content
	// for the table view below
	NSMutableArray *files = [[NSMutableArray alloc] init];
	for (PathNode *child in [node children]) {
		if (![child isFolder]) [files addObject:[child representedObject]];
	}
	
	// now update the property that the controller is bound to
	[self setFolderContents:[NSArray arrayWithArray:files]];
	[files release];
}

#pragma mark private methods

- (void)setFetchPredicate {
	NSPredicate *predicate;
	
	if (currentTickets && isAwake) {
		NSUInteger i;
		NSArray *tickets = [currentTickets allObjects];
		NSMutableString *predString = [[[NSMutableString alloc] initWithFormat:
										@"ticket.number == %@", [[tickets objectAtIndex:0] number]]
									   autorelease];
		for (i = 1; i < [tickets count]; i++) {
			Ticket *t = [tickets objectAtIndex:i];
			[predString appendFormat:@" || ticket.number == %@", [t number]];			
		}		
		predicate = [NSPredicate predicateWithFormat:predString];
		
		// split the search ticket files into a tree
		// and start observing changes in each ticket
		for (i = 0; i < tickets.count; i++) {
			Ticket *t = [tickets objectAtIndex:i];
			[self addSetToFileTree:[t files] sortImmediately:(i == [tickets count])];
			[t addObserver:self 
				forKeyPath:@"files" 
				   options:NSKeyValueObservingOptionNew 
				   context:NULL];
		}		
	} else
		predicate = [NSPredicate predicateWithValue:NO];
	
	[resultsController setFetchPredicate:predicate];
	debug_NSLog(@"the search fetch predicate is now set to: %@", [resultsController fetchPredicate]);
}

- (void)addSetToFileTree:(NSSet *)fileSet sortImmediately:(BOOL)shouldSort {
	// bit tricky, each entry needs to have 
	// its parent folder added to the tree
	// but different users with the same parent
	// folder name need to be given a different folder
	// so first, sort the set by user
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] 
									initWithKey:@"user.name" 
									ascending:YES];
	NSArray *files = [[fileSet allObjects] sortedArrayUsingDescriptors:
					  [NSArray arrayWithObject:descriptor]];
	[descriptor release];
	
	// now iterate through the files, creating a list
	// of which files belong to which user
	User *lastUser = nil;
	NSMutableArray *usersFiles = [[NSMutableArray alloc] init];
	for (Result *r in files) {
		
		if ([[r user] isEqual:lastUser]) {
			// combine all the files for each user
			[usersFiles addObject:r];
		} else {
			if ([usersFiles count] > 0) {
				// new user detected, add the last batch to the tree
				[self addFolderToTree:usersFiles shouldSort:NO];				
				[usersFiles removeAllObjects];
			}
			lastUser = [r user];
			[usersFiles addObject:r];
		}
	}
	
	// add the final batch of files
	[self addFolderToTree:usersFiles shouldSort:shouldSort];
	[usersFiles release];
}

- (void)addFolderToTree:(NSMutableArray *)list shouldSort:(BOOL)yesOrNo {
	if ([list count] == 0) return;
	
	// create a new operation and put it on the q
	SplitOperation *so = [[SplitOperation alloc] 
						  initWithFiles:[NSArray arrayWithArray:list]
						  shouldSort:yesOrNo];
	[queue addOperation:so];
	[so release];
}

// this method is called when an operation queue
// item has completed, which can be from any thread
- (void)splitFinished:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(addTreesToRoots:) 
						   withObject:notification waitUntilDone:NO];
}

- (void)addTreesToRoots:(NSNotification *)notification {
	NSDictionary *d = [notification userInfo];
	[treeRoot addChild:[d objectForKey:@"foldertree"]];
	[userRoot addChild:[d objectForKey:@"usertree"]];
	
	// only refresh the controller if necessary
	BOOL sortNow = [[d objectForKey:@"shouldSort"] boolValue];
	
	if (sortNow)
		[self resortTables:nil];
	else
		sortPending = YES;	// sort with the next timer tick
}

- (void)resortTables:(NSTimer *)timer {
	if (sortPending) {
		switch (viewState) {
			case vwList:
				[resultsController rearrangeObjects];
				break;
			case vwFolder:
				[treeController rearrangeObjects];
				break;
			case vwBrowse:
				[userBrowser reloadColumn:0];
				break;
		}
		sortPending = NO;
	}	
}

#pragma mark tableview delegate methods

- (void)tableView:(NSTableView *)aTableView 
  willDisplayCell:(id)aCell 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(NSInteger)rowIndex {
	
	// only set images for the filename column
	if ([[aTableColumn identifier] isEqualToString:@"filename"]) {
		NSString *filename = [aCell stringValue];
		
		// get the extension and set according image
		NSString *extension = [[filename pathExtension] lowercaseString];
		
		// first check the cache of resized images
		NSImage *myImage = [smallIcons valueForKey:extension];
		if (!myImage) {
			// not cached, so fetch the image and resize it
			myImage = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
			[myImage setScalesWhenResized:YES];
			[myImage setSize:NSMakeSize(16.0, 16.0)];
			[smallIcons setValue:myImage forKey:extension];
		}
		
		[(ImageAndTextCell *)aCell setImage:myImage];
	}
	
	// get the corresponding Result
	// if the queue time is > 0, grey the line
	if ([aCell isHighlighted])
		[aCell setTextColor:[NSColor whiteColor]];
	else {
		NSArrayController *ac;
		if (viewState == vwList)
			ac = resultsController;
		else
			ac = browseController;
		
		if ([ac.arrangedObjects count] > 0) {
			Result *r = [ac.arrangedObjects objectAtIndex:(NSUInteger) rowIndex];
			if (r.user.queueTime > 0)
				[aCell setTextColor:NSColor.darkGrayColor];
			else
				[aCell setTextColor:NSColor.blackColor];
		}			
	}
}

#pragma mark outline view delegate methods

- (void)outlineView:(NSOutlineView *)outlineView 
	willDisplayCell:(id)cell 
	 forTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item {
	
	PathNode *node = (PathNode *)[item representedObject];
	if ([[tableColumn identifier] isEqualToString:@"filename"]) {
		// display an icon in the filename column
		NSImage *myImage = nil;
		if ([node isFolder]) {
			if ([node isExpanded])
				myImage = [[NSWorkspace sharedWorkspace] 
						   iconForFileType:NSFileTypeForHFSTypeCode(kOpenFolderIcon)];
			else
				myImage = [[NSWorkspace sharedWorkspace] 
						   iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
			
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
	} else {
		// hide the cells that make no sense for folder items
		if ([node isFolder] && 
			([[tableColumn identifier] isEqualToString:@"bitrate"] ||
			 [[tableColumn identifier] isEqualToString:@"queue"])) {
				[cell setObjectValue:nil];
		}
	}
	
	// display in a grey colour if there is a q
	if ([cell isHighlighted])
		[cell setTextColor:[NSColor whiteColor]];
	else if ([[[node user] hasFreeSlots] boolValue])
		[cell setTextColor:[NSColor blackColor]];
	else
		[cell setTextColor:[NSColor darkGrayColor]];
}

// store the expanded state of the node
// so that the tree can be restored when changing between users
- (void)outlineViewItemDidExpand:(NSNotification *)notification {
	PathNode *node = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];
	[node setIsExpanded:YES];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
	PathNode *node = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];
	[node setIsExpanded:NO];
}

// expand a folder when it is selected in the outline view
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	NSIndexSet *selected = outlineView.selectedRowIndexes;
	if (selected.count != 1) return;
	
	NSUInteger i = selected.firstIndex;
	PathNode *node = [[outlineView itemAtRow: (NSInteger) i] representedObject];
	if (node.isFolder && !node.isExpanded)
		[outlineView expandItem:[outlineView itemAtRow: (NSInteger) i]];
}

#pragma mark browser delegate methods

// this is not strictly a delegate method, but is called
// to walk to the root node for each column
- (PathNode *)parentNodeForColumn:(NSInteger)column {
	PathNode *node = userRoot;
	
	// walk to the specified column depth
	// picking the correct row at each step
	for (NSInteger i = 0; i < column; i++) {
		NSInteger row = [userBrowser selectedRowInColumn:i];
		node = [node folderAtIndex:row];
	}
	return node;
}

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column {
	PathNode *node = [self parentNodeForColumn:column];
	
	// only display folders in the browser view
	return (NSInteger) node.numFolders;
}

- (void)browser:(NSBrowser *)sender 
willDisplayCell:(id)cell 
		  atRow:(NSInteger)row 
		 column:(NSInteger)column {
	
	PathNode *parent = [self parentNodeForColumn:column];
	
	// now cycle until we find the correct child folder
	PathNode *node = [parent folderAtIndex:row];
	[cell setTitle:[node name]];
	[cell setRepresentedObject:node];
	[cell setLeaf:([node numFolders] == 0)];
	
	// set the image for each cell
	// display an icon in the filename column
	NSImage *myImage = nil;
	if (column == 0)
		myImage = [NSImage imageNamed:@"User"];
	else {
		if ([node isExpanded])
			myImage = [[NSWorkspace sharedWorkspace] 
					   iconForFileType:NSFileTypeForHFSTypeCode(kOpenFolderIcon)];
		else
			myImage = [[NSWorkspace sharedWorkspace] 
					   iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		
		[myImage setScalesWhenResized:YES];
		[myImage setSize:NSMakeSize(16.0, 16.0)];
	}
	[cell setImage:myImage];
}


#pragma mark menu delegate methods

// set the correct text for the friends menu item
- (void)menuNeedsUpdate:(NSMenu *)menu {
	// the user to send the message to
	NSArray *results = [resultsController selectedObjects];
	Result *result = [results lastObject];
	BOOL isFriend = [[[result user] isFriend] boolValue];
	
	if (isFriend)
		[friendMenuItem setTitle:@"Remove From Friends"];
	else
		[friendMenuItem setTitle:@"Add To Friends"];
	
	if ([results count] == 1)
		[downloadMenuItem setTitle:@"Download File"];
	else
		[downloadMenuItem setTitle:@"Download Files"];
}

@end
