//
//  FriendViewController.h
//  iSoul
//
//  Created by Richard on 11/23/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MuseekdConnectionController;

@interface FriendViewController : NSViewController {
	IBOutlet NSTableView *tableView;
	IBOutlet NSArrayController *arrayController;
	IBOutlet NSMenuItem *friendMenuItem;
	
	NSManagedObjectContext *managedObjectContext; 
	MuseekdConnectionController *museek;
	NSImage *personIcon;
	NSArray *tableSortDescriptors;
}

@property (retain) NSManagedObjectContext *managedObjectContext;
@property (retain) MuseekdConnectionController *museek;
@property (retain) NSArray *tableSortDescriptors;
@property (readonly) NSArray *selectedUsers;

- (IBAction)removeFriends:(id)sender;
- (void)updateUserStatus:(NSNotification *)notification;
- (void)userInfoUpdated:(NSNotification *)notification;

@end
