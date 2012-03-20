//
//  PrefsWindowController.m
//  SolarSeek
//
//  Created by Iwan Negro on 03.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "PrefsWindowController.h"
#import "MuseekdConnectionController.h"
#import "Constants.h"
#import "SharesScanner.h"
#import "ShareNode.h"
#import "NSStringSpeed.h"

NSString * const ctxAddFolder = @"AddFolder";
NSString * const ctxAddMenuItem = @"AddMenuItem";

@implementation PrefsWindowController
@synthesize museek;
@synthesize treeRoot;
@synthesize numSharedString;
@synthesize privelegeString;
@synthesize daysToShare;
@dynamic treeSortDescriptors;

#pragma mark init and dealloc

+ (PrefsWindowController *)sharedPrefsWindowController
{
	return (PrefsWindowController *)[super sharedPrefsWindowController];
}

- (void)dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	[numSharedString release];
	[museek release];
	[treeRoot release];
	[super dealloc];
}

- (void)awakeFromNib
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		   selector:@selector(descriptionChanged:) 
			   name:@"NSTextDidChangeNotification" 
			 object:description];
	
	[nc addObserver:self 
		   selector:@selector(privelegesUpdated:) 
			   name:@"PrivelegesUpdated" 
			 object:nil];
	
	// set a 0 string for the file count
	[self updateSharedString];
	[self setPrivelegeString:@"0 seconds"];
	[self setDaysToShare:0];
	
	// create the pop up menus for download locations
	[self setupDownloadMenu];
	[self setupIncompleteMenu];
	[self setupLogPathMenu:YES];
    [self setupLogPathMenu:NO];
	// request the current level of priveleges
	[museek checkPriveleges];
}

- (void)setupToolbar 
{
	[self addView:generalPrefsView label:@"General" image:[NSImage imageNamed:@"PrefGeneral"]];
	[self addView:accountPrefsView label:@"Account" image:[NSImage imageNamed:@"PrefAccount"]];
	[self addView:downloadsPrefsView label:@"Downloads" image:[NSImage imageNamed:@"PrefDownloads"]];
	[self addView:sharingPrefsView label:@"Sharing" image:[NSImage imageNamed:@"PrefSharing"]];
	[self addView:talksPrefsView label:@"Talks" image:[NSImage imageNamed:@"PrefTalks"]];
	[self addView:networkPrefsView label:@"Network" image:[NSImage imageNamed:@"PrefNetwork"]];
    [self addView:loggingPrefsView label:@"Logging" image:[NSImage imageNamed:@"PrefLogging"]];
	[self addView:itunesPrefsView label:@"iTunes" image:[NSImage imageNamed:@"PrefItunes"]];
	[self addView:donationsPrefsView label:@"Donations" image:[NSImage imageNamed:@"PrefDonations"]];
}

// restores the previously viewed preference pane when the view is reloaded
- (IBAction)showWindow:(id)sender
{
	NSString *selectedIdentifier = nil;
	NSToolbar *toolbar = [[self window] toolbar];
	if (toolbar) {
		selectedIdentifier = [toolbar selectedItemIdentifier];
	}
	[super showWindow:sender];
	if (selectedIdentifier) {
		[[[self window] toolbar] setSelectedItemIdentifier:selectedIdentifier];
		[self displayViewForIdentifier:selectedIdentifier animate:NO];
	}
}

- (void)setupDownloadMenu
{
	NSMenu *downloadMenu = [[[NSMenu alloc] initWithTitle:@"Download Locations"] autorelease];
	NSString *savePath = [[NSUserDefaults standardUserDefaults] valueForKey:@"DownloadPath"];
	NSArray *locations = [NSArray arrayWithObjects:@"Desktop",@"Music",@"Downloads",nil];
	NSMenuItem *chosen = nil;
	for (NSString *location in locations) {
		NSString *path = [[NSString stringWithFormat:@"~/%@",location] 
						  stringByExpandingTildeInPath];
		
		// check for which menu item should be selected
		NSMenuItem *item = [self addMenuItemForPath:path toMenu:downloadMenu];
		[item setTag:1];	// tag is 1 for default items
		if ([path isEqualToString:savePath]) chosen = item;				
	}
	// if the save path is none of the default values
	// then add the save path as a menu item
	if (!chosen) {
		chosen = [self addMenuItemForPath:savePath toMenu:downloadMenu];
		[chosen setTag:2];	// tag is 2 for non-default item
		
		// if the path was not valid, the return value will be nil
		if (!chosen) {
			chosen = [downloadMenu itemAtIndex:0];
		}
	}
	
	[downloadMenu addItem:[NSMenuItem separatorItem]];
	[downloadMenu addItemWithTitle:@"Other..." 
							action:@selector(newMenuItem:) 
					 keyEquivalent:@""];
	[downloadPopup setMenu:downloadMenu];
	[downloadPopup selectItem:chosen];
	[self downloadLocationChanged:downloadPopup];
}

- (void)setupIncompleteMenu
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Incomplete Save Locations"] autorelease];
	NSString *incompletePath = [[NSUserDefaults standardUserDefaults] valueForKey:@"IncompletePath"];
	
	NSMenuItem *chosen = [self addMenuItemForPath:incompletePath toMenu:menu];
	if (!chosen) {
		// incomplete dir does not exist, create a new one 
		NSString *defaultPath = [pathIncomplete stringByExpandingTildeInPath];
		NSFileManager *fm = [NSFileManager defaultManager];
		NSError *error;
		BOOL success = [fm createDirectoryAtPath:defaultPath 
					 withIntermediateDirectories:YES 
									  attributes:nil 
										   error:&error];
		if (!success) {
			NSLog(@"error creating default save folder %@, error %@", defaultPath, [error description]);
		} else {
			chosen = [self addMenuItemForPath:defaultPath toMenu:menu];
		}
	}
	
	// if we have no directory selected, do not bother making the menu
	if (chosen) {
		[chosen setTag:2];
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItemWithTitle:@"Other..." 
						action:@selector(newMenuItem:) 
						 keyEquivalent:@""];
		[incompletePopup setMenu:menu];
		[incompletePopup selectItem:chosen];
		[self incompleteLocationChanged:incompletePopup];
	}
	
}

- (void)setupLogPathMenu:(BOOL)archived{
    NSMenu * menu;
    NSString * path;
    if (archived)
    {
        /* archived log directory */
        menu = [[[NSMenu alloc] initWithTitle:@"Dir Log Path"] autorelease];
        path = [[NSUserDefaults standardUserDefaults] valueForKey:@"LogDirPath"];
    }
    else
    {
        /* current log path */
        menu = [[[NSMenu alloc] initWithTitle:@"Log File Path"] autorelease];
        path = [[NSUserDefaults standardUserDefaults] valueForKey:@"LogPath"];
    }

	
    //DNSLog(@"%@", [path stringByDeletingLastPathComponent]);
    NSMenuItem * chosenItem = [self addMenuItemForPath:path toMenu:menu];
    if (!chosenItem) 
    {
		// log path does not exist, create a new one 
		NSString * defaultLogPath = [path stringByExpandingTildeInPath];
		NSFileManager * FM = [NSFileManager defaultManager];
		NSError * error;
		BOOL success = [FM createDirectoryAtPath:defaultLogPath 
					 withIntermediateDirectories:YES 
									  attributes:nil 
										   error:&error];
		if (!success) 
        {
			DNSLog(@"error creating default save folder %@, error %@", defaultLogPath, [error description]);
		} 
        else 
        {
			chosenItem = [self addMenuItemForPath:defaultLogPath toMenu:menu];
		}
	}
    // if we have no directory selected, do not bother making the menu
    if (chosenItem) {
        [chosenItem setTag:2];
        [menu addItem:[NSMenuItem separatorItem]];
        [menu addItemWithTitle:@"Other..." 
                        action:@selector(newMenuItem:) 
                 keyEquivalent:@""];
        if (archived)
        {
            [dirPathPopup setMenu:menu];
            [dirPathPopup selectItem:chosenItem];
            [self logPathChanged:dirPathPopup];
        }
        else
        {
            [logPathPopup setMenu:menu];
            [logPathPopup selectItem:chosenItem];
            [self logPathChanged:logPathPopup];
        }
    }
}

- (NSMenuItem *)addMenuItemForPath:(NSString *)path toMenu:(NSMenu *)menu
{
	// first check that the path exists
	// if not, do not bother adding to the menu
	NSFileManager * fm = [NSFileManager defaultManager];
	BOOL isDirectory;
	BOOL fileExists = [fm fileExistsAtPath:path isDirectory:&isDirectory];
	if (!(fileExists && isDirectory)) 
    {
		DNSLog(@"Menu folder %@ does not exist", path);
		return nil;
	}
	else
    {
        DNSLog(@"Menu folder %@ exists", path);
    }
    
	NSMenuItem * item = [[NSMenuItem alloc] initWithTitle:[path lastPathComponent] 
												  action:NULL keyEquivalent:@""];
	NSImage * icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	[icon setScalesWhenResized:YES];
	[icon setSize:NSMakeSize(16.0, 16.0)];
	[item setImage:icon];
	[item setRepresentedObject:path];
	[menu insertItem:item atIndex:0];
	[item release];
	return item;
}

#pragma mark properties

- (NSArray *)treeSortDescriptors
{
	NSSortDescriptor *name = [[[NSSortDescriptor alloc] 
							   initWithKey:@"name" 
							   ascending:YES
							   selector:@selector(localizedCaseInsensitiveCompare:)] 
							  autorelease];
	return [NSArray arrayWithObject:name];	
}

- (void)updateSharedString
{
	uint32_t numFiles = 0;
	uint32_t numFolders = 0;
	[treeRoot countFolders:&numFolders andFiles:&numFiles recursiveSearch:YES];
	
	[self setNumSharedString:
	 [NSString stringWithFormat:@"Sharing %u Files in %u Folders", 
	  numFiles, numFolders]];
}

- (void)setAddEnabled:(BOOL)canAdd
{
	[addFolderButton setEnabled:canAdd]; 
}

#pragma mark notification responses

- (void)descriptionChanged:(NSNotification *)notification
{
	descriptionChanged = YES;
}

- (void)privelegesUpdated:(NSNotification *)notification
{
	NSNumber *secondsRemaining = [notification object];
	[self setPrivelegeString:[NSString stringForTime:[secondsRemaining floatValue]]];
}

- (BOOL)windowShouldClose:(id)sender
{
	// make sure editing is finished before closing
	NSWindow *w = (NSWindow *)sender;
	if (![w makeFirstResponder:w]) {
		NSBeep();
		return NO;
	}
	
	// ask whether we should restart now or later?
	if (restartRequired) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert setMessageText:@"Museek Restart Required"];
		[alert setInformativeText:@"The configuration changes require that the Museek daemon be restarted"];
		[alert addButtonWithTitle:@"Restart Now"];
		[alert addButtonWithTitle:@"Restart Later"];
		
		if ([alert runModal] == NSAlertSecondButtonReturn) {
			restartRequired = NO;
		}	
	}
	
	return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
	// update the user description
	if (descriptionChanged) {
		[museek setConfigDomain:@"userinfo" forKey:@"text" toValue:[description string]];
		descriptionChanged = NO;
	}	
	
	// save the changed settings
	if ([prefsController hasUnappliedChanges]) {
		[prefsController save:self];
	}
	
	if (sharesUpdated) {
		// save the shares files in a different thread
		// this will also take care of restarting museek
		// if it is necessary
		[NSThread detachNewThreadSelector:@selector(saveSharesFiles:) 
								 toTarget:self 
							   withObject:nil];		
	} 
	else if (restartRequired) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:@"MuseekRestartRequired" object:nil];
		restartRequired = NO;
	}
}

#pragma mark private methods

- (void)saveSharesFiles:(id)object
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// need to rewrite both the shares files
	NSString *savePath = [NSString stringWithFormat:@"%@/%@",
						  [pathBaseFolder stringByExpandingTildeInPath],pathShareState];
	SharesScanner *scanner = [[SharesScanner alloc] init];
	if (![scanner saveTree:treeRoot toPath:savePath]) {
		NSLog(@"error saving share file %@", savePath);
	}
	savePath = [NSString stringWithFormat:@"%@/%@",
				[pathBaseFolder stringByExpandingTildeInPath],pathShares];
	if (![scanner saveUnnestedTree:treeRoot toPath:savePath]) {
		NSLog(@"error saving share file %@", savePath);
	}
	[scanner release];
	
	// if we are restarting museekd anyway, 
	// the shares file will be rescanned then
	// otherwise send a message to museekd
	if (restartRequired) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:@"MuseekRestartRequired" object:nil];
		restartRequired = NO;
	} else {
		[museek reloadShares];
	}
	sharesUpdated = NO;
	[pool release];
}
			 
- (void)scanFolders:(NSArray *)folders
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SharesScanner *scanner = [[SharesScanner alloc] init];
	
	for (NSURL *url in folders) {
		// for each folder, add a new child to the root node
		// need to search first to ensure they do not
		// belong as subfolders of other folders
		NSString *folderPath = [url path];
		ShareNode *parent = [treeRoot findTreePosition:folderPath];
		
		// create a new node as a child of the parent node
		ShareNode *node;
		if ([[parent path] isEqualToString:folderPath]) {
			// if the folder is already in the tree
			// no need to create a node
			node = parent;
		} else {

			node = [[ShareNode alloc] init];
			[node setIsFolder:YES];
			[node setPath:folderPath];
			if ([parent isEqual:treeRoot]) {
				[node setName:folderPath];
			} else {
				[node setName:[folderPath substringFromIndex:[[parent path] length] + 1]];
			}	
			[parent addChild:node];
			[node release];
		}
		
		// now populate the node from the directory tree
		[scanner populateNode:node]; 
	}
	[scanner release];
	[pool release];
	
	// finally, update the tree controller and stop the progress bar
	[self performSelectorOnMainThread:@selector(stopScanning:) 
						   withObject:nil waitUntilDone:NO];
}

- (void)stopScanning:(id)object
{
	[treeController rearrangeObjects];
	[self updateSharedString];
	[progress stopAnimation:self];
	[progress setHidden:YES];
	[addFolderButton setEnabled:YES];
}

#pragma mark IBAction methods

- (IBAction)addSharedFolder:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:YES];
	
	[openPanel beginSheetModalForWindow: self.window completionHandler: ^(NSInteger returnCode) {
		if (returnCode != NSOKButton)
			return;
		
		[addFolderButton setEnabled:NO];
		[progress setHidden:NO];
		[progress startAnimation:self];
		sharesUpdated = YES;	// need to rewrite the files 
		// when the preferences are closed
		
		// scan the files in a separate thread
		NSArray *selectedFolders = [openPanel URLs];
		[NSThread detachNewThreadSelector:@selector(scanFolders:) 
								 toTarget:self 
							   withObject:selectedFolders];
	}];
}

- (IBAction)removeSharedFolder:(id)sender
{
	// need to count the number of files and folders being removed
	NSArray *selectedPaths = [treeController selectionIndexPaths];
	for (NSIndexPath *path in selectedPaths) {
		// walk the tree to the correct node
		ShareNode *toRemove = treeRoot;
		for (NSUInteger i = 0; i < [path length]; i++) {
			NSUInteger removeIndex = [path indexAtPosition:i];
			toRemove = [[toRemove children] objectAtIndex:removeIndex];
		}
	}
	[treeController remove:self];
	[self updateSharedString];
	sharesUpdated = YES;
}

- (IBAction)usernameChanged:(id)sender
{
	[museek setConfigDomain:@"server" forKey:@"username" toValue:[sender stringValue]];
	restartRequired = YES;
}

- (IBAction)passwordChanged:(id)sender
{
	[museek setConfigDomain:@"server" forKey:@"password" toValue:[sender stringValue]];
	restartRequired = YES;
}

- (IBAction)serverChanged:(id)sender
{
	[museek setConfigDomain:@"server" forKey:@"host" toValue:[sender stringValue]];
	restartRequired = YES;
}

- (IBAction)serverPortChanged:(id)sender
{
	[museek setConfigDomain:@"server" forKey:@"port" toValue:[sender stringValue]];
	restartRequired = YES;
}

- (IBAction)lowPortChanged:(id)sender
{
	[museek setConfigDomain:@"clients.bind" forKey:@"first" toValue:[sender stringValue]];
	restartRequired = YES;
}

- (IBAction)highPortChanged:(id)sender
{
	[museek setConfigDomain:@"clients.bind" forKey:@"last" toValue:[sender stringValue]];
	restartRequired = YES;
}

- (IBAction)uploadRateChanged:(id)sender
{
	[museek setConfigDomain:@"transfers" 
					 forKey:@"upload_rate" 
					toValue:[[sender objectValue] stringValue]];
}

- (IBAction)uploadSlotsChanged:(id)sender
{
	[museek setConfigDomain:@"transfers" 
					 forKey:@"upload_slots" 
					toValue:[[sender objectValue] stringValue]];
}

- (IBAction)downloadLocationChanged:(id)sender
{
	NSMenuItem *item = [sender selectedItem];
	if ([item tag] < 1) return;		// default values have tag 1, non-default 2
	
	NSString *folderPath = [item representedObject];
	NSString *oldPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"DownloadPath"];
	if ([oldPath isEqualToString:folderPath]) {
		debug_NSLog(@"no need to change download folder, already set to %@", oldPath);
		return;
	}		
	debug_NSLog(@"changing download folder to %@", folderPath);
	
	// first update the preferences
	[[NSUserDefaults standardUserDefaults] 
	 setObject:folderPath forKey:@"DownloadPath"];
	
	// next update the museek config file
	[museek setConfigDomain:@"transfers" 
					 forKey:@"download-dir" 
					toValue:folderPath];
	restartRequired = YES;
}

- (IBAction)incompleteLocationChanged:(id)sender
{
	NSMenuItem *item = [sender selectedItem];
	if ([item tag] < 1) return;		// default values have tag 1, non-default 2
	
	NSString *folderPath = [item representedObject];
	NSString *oldPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"IncompletePath"];
	if ([oldPath isEqualToString:folderPath]) {
		debug_NSLog(@"no need to change incomplete folder, already set to %@", oldPath);
		return;
	}		
	debug_NSLog(@"changing incomplete folder to %@", folderPath);
	
	// first update the preferences
	[[NSUserDefaults standardUserDefaults] 
	 setObject:folderPath forKey:@"IncompletePath"];
	
	// next update the museek config file
	[museek setConfigDomain:@"transfers" 
					 forKey:@"incomplete-dir" 
					toValue:folderPath];
	restartRequired = YES;	
}

- (IBAction)logPathChanged:(id)sender
{
	NSMenuItem * item = [sender selectedItem];
	if ([item tag] < 1) return;		// default values have tag 1, non-default 2
	
	NSString * logPath = [item representedObject];
	NSString * oldPath = nil;
    
    if ([sender isEqual:logPathPopup])
    {
        oldPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"LogPath"];
        
    }
    else if ([sender isEqual:dirPathPopup])
    {
        oldPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"LogDirPath"];
    }
    
	if ([oldPath isEqualToString:logPath]) 
    {
		DNSLog(@"no need to change incomplete folder, already set to %@", oldPath);
		return;
	}		
    
	DNSLog(@"changing logPath folder to %@", logPath);
	
	// first update the preferences
    if ([sender isEqual:logPathPopup])
    {
        [[NSUserDefaults standardUserDefaults] setObject:logPath forKey:@"LogPath"];
        
    }
    else if ([sender isEqual:dirPathPopup])
    {
        [[NSUserDefaults standardUserDefaults] setObject:logPath forKey:@"LogDirPath"];
    }

}

- (IBAction)userImageChanged:(id)sender
{
	// the image data has changed, the image
	// data needs to be written to the config file	
	NSImage *image = [sender image];
	NSString *imagePath = [[NSString stringWithFormat:
							@"%@/%@", pathBaseFolder, pathUserImage] 
						   stringByExpandingTildeInPath];
	NSData *imageData = [image TIFFRepresentation];
	
	debug_NSLog(@"saving image data to %@", imagePath);
	NSError *error;
	if (![imageData writeToFile:imagePath options:NSAtomicWrite error:&error]) {
		[sender setImage:nil];
		NSLog(@"error saving image data to %@, error %@", imagePath, error);
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert beginSheetModalForWindow:[sender window] 
						  modalDelegate:self 
						 didEndSelector:nil 
							contextInfo:NULL];		
	}		
}

- (IBAction)newMenuItem:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel beginSheetModalForWindow: self.window completionHandler: ^(NSInteger returnCode) {
		if (returnCode != NSOKButton)
			return;
		
		NSArray *urls = [openPanel URLs];
		NSString *folderPath = [[urls lastObject] path];
		
		// finally update the menu, first need
		// to check if the chosen path is one of the default paths
		NSMenu *menu = [sender menu];
		NSMenuItem *chosen = nil;
		NSArray *menuItems = [menu itemArray];
		for (NSMenuItem *item in menuItems) {
			if ([[item representedObject] isEqualToString:folderPath]) {
				chosen = item;
				break;
			}
		}
		
		if (!chosen) {
			// not a default item, so remove the previously 
			// selected folder if it was not a default entry
			// and create a new menu item for the path
			chosen = [menu itemWithTag:2];	// tag is 2 for the non-default choice
			if (chosen) [menu removeItem:chosen];
			chosen = [self addMenuItemForPath:folderPath toMenu:menu];
			[chosen setTag:2];			
		}
		
		// finally, choose the new item in the correct popup
		if ([menu isEqual:[downloadPopup menu]]) 
		{
			[downloadPopup selectItem:chosen];
			[self downloadLocationChanged:downloadPopup];
		} 
		else if ([menu isEqual:[incompletePopup menu]])
		{
			[incompletePopup selectItem:chosen];
			[self incompleteLocationChanged:incompletePopup];
		}
		else if ([menu isEqual:[logPathPopup menu]])
		{
			[logPathPopup selectItem:chosen];
			[self logPathChanged:logPathPopup];
		}
		else if ([menu isEqual:[dirPathPopup menu]])
		{
			[dirPathPopup selectItem:chosen];
			[self logPathChanged:dirPathPopup];
		}
	}];
}

- (IBAction)downloadRateChanged:(id)sender
{
	[museek setConfigDomain:@"transfers" 
					 forKey:@"download_rate" 
					toValue:[[sender objectValue] stringValue]];
}

- (IBAction)museekdAddressChanged:(id)sender
{
	restartRequired = YES;
}

- (IBAction)donateToSoulseek:(id)sender
{
	NSURL *url = [NSURL URLWithString:@"http://www.slsknet.org/donate.php"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)sharePriveleges:(id)sender
{
	NSString *username = [userToShareWith stringValue];
	[museek sharePrivelegesWithUser:username days:(uint32_t)daysToShare];
}

- (IBAction)addAutojoinForAllRooms:(id)sender
{
    NSButton * checkbox = (NSButton *)sender;
    DNSLog(@"Setting autojoining last opened chat rooms");
    if([checkbox state] == NSOnState)
    {
        [museek addAutojoinLastOpenedRooms];
    }
}

@end

