//
//  ChatViewController.h
//  iSoul
//
//  Created by Richard on 11/1/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BottomBar;
@class BubbleTextView;
@class ChatMessage;
@class DataStore;
@class MuseekdConnectionController;
@class Room;

@interface ChatViewController : NSViewController {
	IBOutlet NSArrayController *usersController;
	IBOutlet BubbleTextView *messageView;
	IBOutlet NSTextField *textField;
	IBOutlet NSTableView *userList;
	IBOutlet NSSplitView *splitView;
	IBOutlet NSView *leftPane;
	IBOutlet NSButton *button;
	IBOutlet NSMenuItem *friendMenuItem;
	
	id delegate;
	BOOL firstResize;
	float lastDividerPosition;
	NSManagedObjectContext *managedObjectContext; 
	MuseekdConnectionController *museek;
	DataStore *store;
	Room *currentRoom;
	NSMutableArray *usersSoFar;
	NSArray *tableSortDescriptors;
}

@property (retain) NSManagedObjectContext *managedObjectContext;
@property (retain) MuseekdConnectionController *museek;
@property (retain) DataStore *store;
@property (retain) NSArray *tableSortDescriptors;
@property (assign) id delegate;
@property (readonly) NSArray *selectedUsers;

- (IBAction)sendMessage:(id)sender;
- (IBAction)toggleSidePanel:(id)sender;

// public methods
- (void)setDividerPosition:(float)width;
- (void)setRoomName:(NSString *)newName isPrivate:(BOOL)yesOrNo;

// private methods
- (void)userInfoUpdated:(NSNotification *)notification;
- (void)setFetchPredicate;
- (void)addRoomMessages:(NSSet *)messages;
- (void)addMessageToView:(ChatMessage *)msg;

@end
