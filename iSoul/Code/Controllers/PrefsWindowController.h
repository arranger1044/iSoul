//
//  PrefsWindowController.h
//  SolarSeek
//
//  Created by Iwan Negro on 03.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"

@class MuseekdConnectionController;
@class ShareNode;

@interface PrefsWindowController : DBPrefsWindowController {
	
	IBOutlet NSUserDefaultsController *prefsController;
	IBOutlet NSTreeController *treeController;
	
	IBOutlet NSView *generalPrefsView;
	IBOutlet NSView *accountPrefsView;
	IBOutlet NSView *downloadsPrefsView;
	IBOutlet NSView *sharingPrefsView;
	IBOutlet NSView *talksPrefsView;
	IBOutlet NSView *itunesPrefsView;
	IBOutlet NSView *networkPrefsView;
	IBOutlet NSView *donationsPrefsView;
    IBOutlet NSView *loggingPrefsView;
	
	IBOutlet NSTextView *description;
	IBOutlet NSProgressIndicator *progress;
	IBOutlet NSPopUpButton *downloadPopup; 
	IBOutlet NSPopUpButton *incompletePopup;
    IBOutlet NSPopUpButton * logPathPopup;
    IBOutlet NSPopUpButton * dirPathPopup;
	IBOutlet NSTextField *userToShareWith;
	IBOutlet NSButton *addFolderButton;

	MuseekdConnectionController *museek;
	ShareNode *treeRoot;		// holds the shared folder tree
	NSString *numSharedString;	// describes the number of files and folders shared
	NSString *privelegeString;	// the remaining server privelege time
	NSUInteger daysToShare;		// the amount of priveleges to share with someone
	BOOL restartRequired;		// set to true when museek settings require a restart
	BOOL descriptionChanged;	// set to true when the user description is updated
	BOOL sharesUpdated;			// if true, the shares file needs to be rewritten

}

@property (readonly) NSArray *treeSortDescriptors;
@property (retain) MuseekdConnectionController *museek;
@property (retain) ShareNode *treeRoot;
@property (copy) NSString *numSharedString;
@property (copy) NSString *privelegeString;
@property (readwrite) NSUInteger daysToShare; 

+ (PrefsWindowController *)sharedPrefsWindowController;

- (void)updateSharedString;
- (void)setAddEnabled:(BOOL)canAdd;
- (void)scanFolders:(NSArray *)folders;
- (void)stopScanning:(id)object;
- (void)setupDownloadMenu;
- (void)setupIncompleteMenu;
- (void)setupLogPathMenu:(BOOL)archived;
- (NSMenuItem *)addMenuItemForPath:(NSString *)path toMenu:(NSMenu *)menu;
- (void)saveSharesFiles:(id)object;
- (void)descriptionChanged:(NSNotification *)notification;
- (void)privelegesUpdated:(NSNotification *)notification;

- (IBAction)addSharedFolder:(id)sender;
- (IBAction)removeSharedFolder:(id)sender;
- (IBAction)usernameChanged:(id)sender;
- (IBAction)passwordChanged:(id)sender;
- (IBAction)serverChanged:(id)sender;
- (IBAction)serverPortChanged:(id)sender;
- (IBAction)lowPortChanged:(id)sender;
- (IBAction)highPortChanged:(id)sender;
- (IBAction)uploadRateChanged:(id)sender;
- (IBAction)uploadSlotsChanged:(id)sender;
- (IBAction)downloadLocationChanged:(id)sender;
- (IBAction)incompleteLocationChanged:(id)sender;
- (IBAction)logPathChanged:(id)sender;
- (IBAction)userImageChanged:(id)sender;
- (IBAction)newMenuItem:(id)sender;
- (IBAction)downloadRateChanged:(id)sender;
- (IBAction)museekdAddressChanged:(id)sender;
- (IBAction)donateToSoulseek:(id)sender;
- (IBAction)sharePriveleges:(id)sender;


@end
