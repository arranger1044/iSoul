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

@interface ChatViewController : NSViewController<NSAnimationDelegate> {
	IBOutlet NSArrayController *usersController;
	IBOutlet BubbleTextView *messageView;
	IBOutlet NSTextField *textField;
	IBOutlet NSTableView *userList;
	IBOutlet NSSplitView *splitView;
	IBOutlet NSView *usersPane;
    IBOutlet NSView * chatView;
	IBOutlet NSButton *button;
	IBOutlet NSMenuItem *friendMenuItem;
	
	id delegate;
	BOOL firstResize;
	float lastDividerPosition;
    unsigned int unreadMessages;
	NSManagedObjectContext *managedObjectContext; 
	MuseekdConnectionController *museek;
	DataStore *store;
	Room *currentRoom;
	NSMutableArray *usersSoFar;
	NSArray *tableSortDescriptors;
    NSMutableSet * observedRooms;
}

@property (retain) NSManagedObjectContext *managedObjectContext;
@property (retain) MuseekdConnectionController *museek;
@property (retain) DataStore *store;
@property (retain) NSArray *tableSortDescriptors;
@property (retain) NSMutableSet * observedRooms;
@property (assign) unsigned int unreadMessages;
@property (assign) id delegate;
@property (readonly) NSArray *selectedUsers;

- (IBAction)sendMessage:(id)sender;
- (IBAction)toggleSidePanel:(id)sender;

// public methods
- (void)setDividerPosition:(float)width;
- (void)setRoomName:(NSString *)newName isPrivate:(BOOL)yesOrNo;
- (NSNumber *)getDividerPosition;
// private methods
- (void)userInfoUpdated:(NSNotification *)notification;
- (void)setFetchPredicate;
- (void)addRoomMessages:(NSSet *)messages;
- (void)addMessageToView:(ChatMessage *)msg;

@end
