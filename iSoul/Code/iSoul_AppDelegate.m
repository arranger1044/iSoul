//
//  iSoul_AppDelegate.m
//  iSoul
//
//  Created by Richard on 10/26/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "iSoul_AppDelegate.h"
#import "SearchViewController.h"
#import "DownloadViewController.h"
#import "ChatViewController.h"
#import "BrowseViewController.h"
#import "FriendViewController.h"
#import "Constants.h"
#import "DockBadge.h"
#import "MuseekdController.h"
#import "MuseekdConnectionController.h"
#import "DataStore.h"
#import "PrefsWindowController.h"
#import "SharesScanner.h"
#import "ShareNode.h"
#import "MainWindowController.h"
#import "TCMPortMapper.h"
#import "LoggingController.h"

@implementation iSoul_AppDelegate

@synthesize window;
@synthesize searchViewController;
@synthesize downloadViewController;
@synthesize chatViewController;
@synthesize browseViewController;
@synthesize friendViewController;
@synthesize store;
@synthesize museekdController;
@synthesize museekdConnectionController;
@synthesize mainWindowController;


#pragma mark initialization & deallocation

+ (void)initialize
{
    if (self == [iSoul_AppDelegate class])
    {        
        // register the default settings
        debug_NSLog(@"BOMBA INIT");
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        NSString *savePath = [pathDownloads stringByExpandingTildeInPath];
        NSString *incompletePath = [pathIncomplete stringByExpandingTildeInPath];	
        
        [d setValue:[NSNumber numberWithBool:YES] forKey:@"AutoLogin"];
        [d setValue:[NSNumber numberWithBool:YES] forKey:@"BandwidthIcon"];
        [d setValue:[NSNumber numberWithBool:YES] forKey:@"BandwidthSidebar"];
        [d setValue:[NSNumber numberWithBool:YES] forKey:@"BounceIcon"];
        [d setValue:@"" forKey:@"Description"];	
        [d setValue:savePath forKey:@"DownloadPath"];
        [d setValue:[NSNumber numberWithInt:0] forKey:@"DownloadRate"];
        [d setValue:[NSNumber numberWithInt:0] forKey:@"DownloadSlots"];
        [d setValue:[NSNumber numberWithInt:0] forKey:@"ImportAction"];
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"ImportAudio"];
        [d setValue:@"iSoul" forKey:@"ImportPlaylist"];
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"ImportToPlaylist"];
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"ImportVideo"];
        [d setValue:incompletePath forKey:@"IncompletePath"];
        [d setValue:[NSNumber numberWithBool:YES] forKey:@"LocalMuseekd"];
        [d setValue:[NSNumber numberWithInt:1000] forKey:@"MaxSearchResults"];
        [d setValue:@"127.0.0.1" forKey:@"MuseekdAddress"];
        [d setValue:@"" forKey:@"MuseekdPassword"];
        [d setValue:[NSNumber numberWithInt:2242] forKey:@"MuseekdPort"];
        [d setValue:@"" forKey:@"Password"];
        [d setValue:[NSNumber numberWithInt:2240] forKey:@"PortHigh"];
        [d setValue:[NSNumber numberWithInt:2234] forKey:@"PortLow"];
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"PromptNewVersion"];
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"PromptPartialFile"];
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"PromptQuitWithActiveTransfers"];
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"RemoveCompleteDownload"];
        [d setValue:[NSNumber numberWithBool:YES] forKey:@"SearchMainDatabase"];
        [d setValue:[NSNumber numberWithBool:YES] forKey:@"SearchFriendsList"];
        [d setValue:[NSNumber numberWithBool:YES] forKey:@"SearchChatRooms"];
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"SelectNewDownload"];
        [d setValue:[NSNumber numberWithInt:2242] forKey:@"ServerPort"];
        [d setValue:@"server.slsknet.org" forKey:@"ServerUrl"];
        [d setValue:[NSNumber numberWithInt:0] forKey:@"UploadRate"];
        [d setValue:[NSNumber numberWithInt:3] forKey:@"UploadSlots"];
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"UPNP"];
        [d setValue:@"" forKey:@"Username"];
        
        [d setValue:[NSNumber numberWithBool:NO] forKey:@"ShowConsoleStartUp"];
        NSString * logPath = [NSHomeDirectory() stringByAppendingPathComponent:LOG_PATH];
        [d setValue:logPath forKey:@"LogPath"];
        NSString * dirPath = [NSHomeDirectory() stringByAppendingPathComponent:DIR_PATH];
        [d setValue:dirPath forKey:@"LogDirPath"];
        
        [d setValue:[NSNumber numberWithInt:0] forKey:@"SelectedSegmentView"];
        
        NSImage * defaultImage = [NSImage imageNamed:@"PrefAccount"];
        [d setValue:[defaultImage TIFFRepresentation] forKey:@"UserImage"];
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:d];  
        [[LoggingController sharedInstance] startLogging];
    }
}

- (id)init
{
	self = [super init];
	if (self) {
        
		debug_NSLog(@"initialising app delegate");
		
		/* Launch museekd */
		NSNumber *useInternalMuseekd = [[NSUserDefaults standardUserDefaults] 
										valueForKey:@"LocalMuseekd"];
		if ([useInternalMuseekd boolValue]) 
        {
			museekdController = [[MuseekdController alloc] init];
			BOOL success = [museekdController startMuseekd];
			if (!success) NSLog(@"failed to start museekd task");
		} 
        else 
        {
			debug_NSLog(@"not starting internal museekd daemon");
		}
		
		/* now create the data store object, which
		   provides an interface for the core data model */
		NSManagedObjectContext *moc = [self managedObjectContext];
		store = [[DataStore alloc] init];
		[store setManagedObjectContext:moc];
		[store addDefaultSidebarItems];		
		
		// Prepare the connection to gary
		museekdConnectionController = [[MuseekdConnectionController alloc] init];
		[museekdConnectionController setStore:store];

		// set the dock icon view so badges can be adjusted
		DockBadge *view = [[DockBadge alloc] initWithFrame:
						   [[[NSApp dockTile] contentView] frame]];
		[[NSApp dockTile] setContentView:view];
		[view release];
        
		// finally, create the individual window controllers
		searchViewController = [[SearchViewController alloc] init];
		[searchViewController setManagedObjectContext:moc];
		[searchViewController setMuseek:museekdConnectionController];
		
		downloadViewController = [[DownloadViewController alloc] init];
		[downloadViewController setManagedObjectContext:moc];
		[downloadViewController setMuseek:museekdConnectionController];
		[downloadViewController setStore:store];
		
		chatViewController = [[ChatViewController alloc] init];
		[chatViewController setManagedObjectContext:moc];
		[chatViewController setMuseek:museekdConnectionController];
		[chatViewController setDelegate:mainWindowController];
		[chatViewController setStore:store];
		
		browseViewController = [[BrowseViewController alloc] init];
		[browseViewController setManagedObjectContext:moc];
		[browseViewController setMuseek:museekdConnectionController];
		[browseViewController setStore:store];
		
		friendViewController = [[FriendViewController alloc] init];
		[friendViewController setManagedObjectContext:moc];
		[friendViewController setMuseek:museekdConnectionController];
		
		PrefsWindowController *pwc = [PrefsWindowController sharedPrefsWindowController];
		[pwc setMuseek:museekdConnectionController];
        
	}
	return self;
}

- (void)dealloc 
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	
	// clean up the views
	[searchViewController release];
	[downloadViewController release];
	[chatViewController release];
	[browseViewController release];
	[friendViewController release];
	
    [window release];
    [managedObjectContext release];
	[persistentStoreCoordinator release];
    [managedObjectModel release];
	
    [super dealloc];
}

- (void)awakeFromNib
{
	// Be notified when app is exiting
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(applicationWillTerminate:)
			   name:NSApplicationWillTerminateNotification
			 object:nil];
	
	// scan the shared folders in a separate thread
	// once done, load them in the preferences controller
	[NSThread detachNewThreadSelector:@selector(scanSharesFile:) 
							 toTarget:self withObject:nil];
    
    /* Add an observer for the unread messages number to be displayed in the 
     dock tile */
    [chatViewController addObserver:self 
                         forKeyPath:@"unreadMessages" 
                            options:0 
                            context:NULL];
}

#pragma mark properties

// returns the currently displayed view
// in the central scroll view
- (NSView *)currentView
{
	return [mainView documentView];
}

// returns the view controller for the 
// currently visible view
- (id)currentViewController
{
	return currentViewController;
}

- (NSArray *)selectedTransfers
{
	if ([currentViewController respondsToSelector:@selector(selectedTransfers)]) {
		return [currentViewController performSelector:@selector(selectedTransfers)];
	}
	return nil;
}

- (NSArray *)selectedUsers
{
	if ([currentViewController respondsToSelector:@selector(selectedUsers)]) {
		return [currentViewController performSelector:@selector(selectedUsers)];
	}
	return nil;
}

#pragma mark Museek Helper Methods

- (void)applicationWillTerminate:(NSNotification *)notification
{
	[museekdController stopMuseekd];
	[[TCMPortMapper sharedInstance] stopBlocking];
    /* Compress and archive logging */
    //NSString * logPath = [NSHomeDirectory() stringByAppendingPathComponent:LOG_PATH];
    NSString * logPath = [[[NSUserDefaults standardUserDefaults] valueForKey:@"LogPath"] 
                          stringByAppendingPathComponent:logFileName];
    NSString * dirPath = [NSHomeDirectory() stringByAppendingPathComponent:DIR_PATH];
    [[LoggingController sharedInstance] gzipAndArchiveLog:logPath toDirectory:dirPath];
}

- (void)scanSharesFile:(id)object
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *path = [NSString stringWithFormat:@"%@/%@",
					  [pathBaseFolder stringByExpandingTildeInPath],pathShareState];
	SharesScanner *scanner = [[SharesScanner alloc] init];
	ShareNode *root = [scanner scanFile:path];
	if (!root) {
		NSLog(@"failed to scan shares file %@", path);
	} else {
		BOOL treeUpdated = NO;
		
		// check all the root node folders
		// cannot check the root itself, as it has no path
		NSArray *childList = [NSArray arrayWithArray:[root children]];
		for (ShareNode *child in childList) {
			treeUpdated |= [scanner populateNode:child];
		}	
		
		if (treeUpdated) {
			// save the new tree to disk, and get museek to reload the shares
			debug_NSLog(@"the shared folders are out of sync, recreating shares files");
			NSString *savePath = path;
			if (![scanner saveTree:root toPath:savePath]) {
				NSLog(@"error saving share file %@", savePath);
			}
			savePath = [NSString stringWithFormat:@"%@/%@",
						[pathBaseFolder stringByExpandingTildeInPath],
						pathShares];
			if (![scanner saveUnnestedTree:root toPath:savePath]) {
				NSLog(@"error saving share file %@", savePath);
			}
			
			// reload the shares file in museekd
			// make sure we are connected first
			while (![museekdConnectionController connectedToMuseekd]) {
				debug_NSLog(@"Not connected to museekd, sleeping before shares reload");
				[NSThread sleepForTimeInterval:2.0];
			} 
			[museekdConnectionController reloadShares];
		}
		
		// set the updated tree in the prefs controller
		PrefsWindowController *pwc = [PrefsWindowController sharedPrefsWindowController];
		[pwc setTreeRoot:root];
		[pwc setAddEnabled:YES];
	}	
	[scanner release];
	[pool release];
}

- (void)connectToMuseekd:(NSNumber *)useInternalDaemon
{
	NSString *address;
	NSString *password;
	NSUInteger port;	
	if ([useInternalDaemon boolValue]) {
		debug_NSLog(@"connecting to internal museekd daemon");
		address = @"127.0.0.1";
		port = [museekdController port];
		password = [museekdController password];
		
		// if uPnP is requested, try to open the ports now
		NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
		if ([[def valueForKey:@"UPNP"] boolValue]) {
			NSUInteger portHigh = [[def valueForKey:@"PortHigh"] unsignedIntValue];
			NSUInteger portLow = [[def valueForKey:@"PortLow"] unsignedIntValue];
			
			TCMPortMapper *pm = [TCMPortMapper sharedInstance];
			
			// first remove any mappings in place
			NSSet *currentMappings = [pm portMappings];
			for (TCMPortMapping *p in currentMappings) {
				[pm removePortMapping:p];
			}		
			
			// now create a mapping for each incoming port
			for (NSUInteger i = portLow; i <= portHigh; i++) {
				[pm addPortMapping:
				 [TCMPortMapping portMappingWithLocalPort:i 
									  desiredExternalPort:i 
										transportProtocol:TCMPortMappingTransportProtocolTCP 
												 userInfo:nil]];			 
			}
			[pm start];
		}
		
	} else {
		debug_NSLog(@"connecting to external museekd daemon");
		NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
		address = [d valueForKey:@"MuseekdAddress"];
		port = [[d valueForKey:@"MuseekdPort"] unsignedIntValue];
		password = [d valueForKey:@"MuseekdPassword"];
	}
	
	[museekdConnectionController connectToHost:[NSHost hostWithAddress:address]
										  port:port 
									  password:password];
}	


#pragma mark public methods

- (void)displayViewController:(NSViewController *)vc
{
	// try to end editing
	BOOL ended = [window makeFirstResponder:window];
	if (!ended) {
		NSBeep();
		return;
	}
	
	// put the view in the box
	NSView *v = [vc view];
	[v setFrame:[mainView bounds]];
	[mainView setDocumentView:v];
	currentViewController = vc;
}

#pragma mark CoreData methods

/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "t" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"iSoul"];
}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
	
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"storedata"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType 
												  configuration:nil 
															URL:url 
														options:nil 
														  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    
	
    return persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext) return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	
    return managedObjectContext;
}

/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    //return [[self managedObjectContext] undoManager];
	// do not want undo, so set to nil
	return nil;
}

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
	
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }
	
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender 
{
	// prompt if there are active transfers
	NSNumber *shouldPrompt = [[NSUserDefaults standardUserDefaults] 
							  valueForKey:@"PromptQuitWithActiveTransfers"];
	if ([shouldPrompt boolValue]) {
		// check if there are any active transfers
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"state == %u",tfTransferring];
		NSEntityDescription *entityDescription = [NSEntityDescription 
												  entityForName:@"Transfer"
												  inManagedObjectContext:managedObjectContext];
		NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
		[request setEntity:entityDescription];
		[request setPredicate:pred];
		
		// perform the fetch
		NSError *error;
		NSArray *array = [managedObjectContext executeFetchRequest:request error:&error];
		if (array) {
			if ([array count] >= 1) {
				// there are some active transfers
				NSAlert *alert = [[[NSAlert alloc] init] autorelease];
				[alert setMessageText:@"Transfers In Progress"];
				[alert setInformativeText:@"There are transfers in progress, are you sure you want to quit now?"];
				[alert addButtonWithTitle:@"OK"];
				[alert addButtonWithTitle:@"Cancel"];
				if ([alert runModal] == NSAlertSecondButtonReturn) {
					return NSTerminateCancel;
				}				
			} 
		} else {
			// error searching
			NSLog(@"Transfer search failed with reason %@", [error localizedFailureReason]);
		}
	}

    if (!managedObjectContext) return NSTerminateNow;

    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }

    if (![managedObjectContext hasChanges]) return NSTerminateNow;

    
    
	/* do not want saving
	NSError *error = nil;
	if (![managedObjectContext save:&error]) {
    
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.

        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
                
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;

        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;

    }
	 */
    return NSTerminateNow;
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
    NSNumber * integerValue = [object valueForKey:keyPath];
    unsigned int unreadMessages = [integerValue unsignedIntValue];
    //DNSLog(@"%u %@", unreadMessages, integerValue);
    NSDockTile *aTitle = [[NSApplication sharedApplication] dockTile];
    NSString * countString;
    if (unreadMessages > 0)
    {
      countString  = [NSString stringWithFormat:@"%u", unreadMessages];
    }
    else 
    {
        countString  = [NSString stringWithFormat:@""];
    }
    [aTitle setBadgeLabel:countString];
    
    // bounce the dock icon if necessary
    NSNumber * bounceDock = [[NSUserDefaults standardUserDefaults] 
                             valueForKey:@"BounceIcon"];
    if ([bounceDock boolValue]) 
    {
        [NSApplication sharedApplication];
        [NSApp requestUserAttention:NSInformationalRequest];
    }
}

@end
