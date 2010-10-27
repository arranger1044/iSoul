//
//  FriendViewController.m
//  iSoul
//
//  Created by Richard on 11/23/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "FriendViewController.h"
#import "MuseekdConnectionController.h"
#import "User.h"
#import "Constants.h"
#import "MainWindowController.h"

@implementation FriendViewController
@synthesize managedObjectContext;
@synthesize museek;
@synthesize tableSortDescriptors;

- (id)init
{
	if (![super initWithNibName:@"FriendsView" bundle:nil]) {
		return nil;
	}
	[self setTitle:@"Friends"];
	
	// used when the friend does not have an image set
	personIcon = [[NSImage imageNamed:@"PrefAccount"] retain];
	
	return self;
}

- (void)awakeFromNib
{
	// register for user status change notifications
	// so that the online status and file count
	// can be updated as and when it is received
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		   selector:@selector(updateUserStatus:) 
			   name:@"BuddiesUpdated" 
			 object:nil];
	
	// observe notifications for user info updates
	// so we can update the icon in the table view
	[nc addObserver:self 
		   selector:@selector(userInfoUpdated:) 
			   name:@"UserInfoUpdated" 
			 object:nil];
	
	NSSortDescriptor *name = [[NSSortDescriptor alloc] 
							   initWithKey:@"name" 
							   ascending:YES
							   selector:@selector(localizedCaseInsensitiveCompare:)];
	[self setTableSortDescriptors:[NSArray arrayWithObject:name]];
	[name release];
}

- (void)dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	
	[personIcon release];
	[museek release];
	[managedObjectContext release];
	[super dealloc];
}

#pragma mark properties

- (NSArray *)selectedUsers
{
	NSArray *selected = [arrayController selectedObjects];
	if ([selected count] > 0) return selected;
	else return nil;
}

#pragma mark notification responses

- (void)updateUserStatus:(NSNotification *)notification
{
	User *user = (User *)[notification object];
	
	// if the user a friend, find in the table and reload
	if ([[user isFriend] boolValue]) {
		NSInteger row = [[arrayController arrangedObjects] indexOfObject:user];
		if (row >= 0) {
			[tableView setNeedsDisplayInRect:[tableView rectOfRow:row]];
		}
	}
}

- (void)userInfoUpdated:(NSNotification *)notification
{
	User *user = (User *)[notification object];
	
	// if user has a picture, reload the row
	if ([user picture]) {
		NSInteger row = [[arrayController arrangedObjects] indexOfObject:user];
		if (row >= 0) {
			[tableView setNeedsDisplayInRect:[tableView rectOfRow:row]];
		}
	}
}

#pragma mark tableview delegate methods

- (void)tableView:(NSTableView *)aTableView 
  willDisplayCell:(id)aCell 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(NSInteger)rowIndex
{
	// we need to set the correct image for the user
	if ([[aTableColumn identifier] isEqualToString:@"username"]) {
		
		// get the user's image if it has been set
		User *user = [[arrayController arrangedObjects] objectAtIndex:rowIndex];
		NSImage *icon;
		if ([user icon]) {
			icon = [[NSImage alloc] initWithData:[user icon]];
			[icon autorelease];
		} else {
			icon = personIcon;
		}
		
		[aCell setImage:icon];
	}
}

#pragma mark IBAction methods

- (IBAction)removeFriends:(id)sender
{
	NSArray *users = [arrayController selectedObjects];
	
	for (User *user in users) {
		[museek addOrRemoveFriend:user];
	}
	[tableView reloadData];
}

@end
