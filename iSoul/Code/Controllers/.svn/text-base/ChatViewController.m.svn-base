//
//  ChatViewController.m
//  iSoul
//
//  Created by Richard on 11/1/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "ChatViewController.h"
#import "Constants.h"
#import "User.h"
#import "MuseekdConnectionController.h"
#import "ChatMessage.h"
#import "MainWindowController.h"
#import "DataStore.h"
#import "BubbleTextView.h"
#import "iSoul_AppDelegate.h"

#define kLeftPaneMinimum	140
#define kRightPaneMinimum	140
#define kDefaultDividerPosition	240

@implementation ChatViewController

@synthesize managedObjectContext;
@synthesize museek;
@synthesize store;
@synthesize tableSortDescriptors;
@synthesize delegate;

- (id)init
{
	if (![super initWithNibName:@"ChatView" bundle:nil]) {
		return nil;
	}
	[self setTitle:@"Chat"];
	
	// stores usernames that have been seen so far
	// if a user is new, then the user info is requested
	usersSoFar = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[currentRoom removeObserver:self forKeyPath:@"messages"];
	[currentRoom release];
	[usersSoFar release];
	[museek release];
	[store release];
	[managedObjectContext release];
	[super dealloc];
}

- (void)awakeFromNib
{
	// set the double click action to initiate private chat
	[userList setTarget:[[NSApp delegate] mainWindowController]];
	[userList setDoubleAction:@selector(privateChat:)];
	
	// initial user list sorting criteria
	NSSortDescriptor *status = [[NSSortDescriptor alloc] 
								 initWithKey:@"status" 
								 ascending:NO];
	NSSortDescriptor *name = [[NSSortDescriptor alloc] 
							   initWithKey:@"name" 
							   ascending:YES
							   selector:@selector(localizedCaseInsensitiveCompare:)];	
	[self setTableSortDescriptors:[NSArray arrayWithObjects:status,name,nil]];
	[status release];
	[name release];
	
	// if user info is reloaded for any users currently chatting
	// we need to reload the tableview to display the icons
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		   selector:@selector(userInfoUpdated:) 
			   name:@"UserInfoUpdated" object:nil];
	
	// horrid hack, forces the first resize of the 
	// split view to set the left pane to the default 
	// value, so the first chatroom is the same size
	// as all the others. please make this go away
	firstResize = YES;
	
	// selects the correct users from the data model
	[self setFetchPredicate];
}

#pragma mark properties

- (NSArray *)selectedUsers
{
	return [usersController selectedObjects];
}

- (void)setRoomName:(NSString *)newName isPrivate:(BOOL)isPrivate
{
	if ([newName isEqualToString:[currentRoom name]]) return;
	
	// stop observing the old room
	[currentRoom removeObserver:self forKeyPath:@"messages"];
	[currentRoom release];
	
	// clear the chat view contents
	NSAttributedString *blankString = [[NSAttributedString alloc] initWithString:@""];
	[[messageView textStorage] setAttributedString:blankString];
	[blankString release];
	
	// get the new room from the store, and load new messages
	// if the room isn't found, the currentRoom will be nil
	NSPredicate *pred = [NSPredicate predicateWithFormat:
						 @"name == %@ && isPrivate == %u", newName, isPrivate];
	currentRoom = (Room *)[store find:@"Room" withPredicate:pred];
	[currentRoom retain];
	[currentRoom addObserver:self 
				  forKeyPath:@"messages" 
					 options:NSKeyValueObservingOptionNew 
					 context:NULL];
	[self addRoomMessages:[currentRoom messages]];
	[self setFetchPredicate];
}

- (NSArray *)chatSortDescriptors
{
	NSSortDescriptor *msgTime = [[[NSSortDescriptor alloc]
							   initWithKey:@"timestamp"
							   ascending:YES]
							  autorelease];
	return [NSArray arrayWithObject:msgTime];
}

#pragma mark notification responses

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
	if ([object isEqual:currentRoom]) {
		NSSet *newMessages = [change objectForKey:NSKeyValueChangeNewKey];
		[self addRoomMessages:newMessages];
		
		// bounce the dock icon if necessary
		NSNumber *bounceDock = [[NSUserDefaults standardUserDefaults] 
								valueForKey:@"BounceIcon"];
		if ([bounceDock boolValue]) {
			[NSApplication sharedApplication];
			[NSApp requestUserAttention:NSInformationalRequest];
		}
	}
}

- (void)userInfoUpdated:(NSNotification *)notification
{
	User *user = [notification object];
	
	// if the user has an icon, and is in the array controller
	// redraw the text view
	if ([user icon] && [[usersController arrangedObjects] containsObject:user]) {
		[messageView setNeedsDisplayInRect:[messageView frame] avoidAdditionalLayout:YES];
	}
}

#pragma mark IBAction methods

- (IBAction)sendMessage:(id)sender
{
	NSString *msg = [textField stringValue];
	if ([msg length] > 0) {
		if ([[currentRoom isPrivate] boolValue]) {
			[museek sendPrivateChat:msg toUser:[currentRoom name]];
		} else {
			[museek sendMessage:msg toRoom:[currentRoom name]];
		}               
		
		[textField setStringValue:@""];
	}       
}

- (IBAction)toggleSidePanel:(id)sender
{
	// check if the side pane has been collapsed
	BOOL collapsed = [splitView isSubviewCollapsed:leftPane];
	
	if (collapsed) {
		[splitView setPosition:lastDividerPosition ofDividerAtIndex:0];
	} else {
		NSRect r = [leftPane frame];
		lastDividerPosition = r.size.width;
		[splitView setPosition:0 ofDividerAtIndex:0];
	}
}

#pragma mark public methods

- (void)setDividerPosition:(float)width
{
	[splitView setPosition:width ofDividerAtIndex:0];
	BOOL collapsed = [splitView isSubviewCollapsed:leftPane];
	[button setState:!collapsed];
}

#pragma mark private methods

- (void)setFetchPredicate
{
	NSPredicate *predicate;
	if ([[currentRoom isPrivate] boolValue]) {
		predicate = [NSPredicate predicateWithFormat:
					 @"name == %@", [currentRoom name]];
	} else {
		predicate = [NSPredicate predicateWithFormat:
					 @"ANY rooms.name == %@", [currentRoom name]];
	}
	[usersController setFetchPredicate:predicate];
}

- (void)addRoomMessages:(NSSet *)messages
{
	// check if the scroll view is at the bottom already
	// if it is, then after adding the new messages
	// scroll the view to the bottom again
	BOOL atEnd = [messageView lastMessageVisible];
	
	// sort the messages by ascending time order
	NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] 
								  initWithKey:@"timestamp" ascending:YES];
	NSArray *sortedMessages = [[messages allObjects] sortedArrayUsingDescriptors:
							   [NSArray arrayWithObject:dateSort]];
	[dateSort release];
	
	// now add each message individually to the text view
	for (ChatMessage *msg in sortedMessages) {
		// check if we have seen this user before
		if (![usersSoFar containsObject:[msg user]]) {
			[usersSoFar insertObject:[msg user] atIndex:0];
			
			// request the info from the museek controller
			[museek getUserInfo:[[msg user] name]];
		}		
		[self addMessageToView:msg];
	}
	
	// now finally scroll the view to the bottom
	if (atEnd) {
		NSRange endOfText = NSMakeRange([[[messageView textStorage] string] length] - 1, 0);
		[messageView scrollRangeToVisible:endOfText];
	} 
}

- (void)addMessageToView:(ChatMessage *)msg
{
	// change the new line characters to the unicode newline
	// this ensures that all lines of a message are contained
	// in a single paragraph, and so a single bubble
	NSMutableString *newMsg = [[NSMutableString alloc] initWithString:
							   [[msg message] stringByReplacingOccurrencesOfString:@"\n" 
																		withString:
								[NSString stringWithFormat:@"%C",NSLineSeparatorCharacter]]];
	[newMsg appendFormat:@"%C",NSParagraphSeparatorCharacter];
	
	// check if it is a status message instead of a chat message
	NSRange r;
	NSMutableParagraphStyle *pStyle;
	BOOL isOutgoing = [[museek username] isEqual:[[msg user] name]];
	BOOL statusMessage = ([newMsg length] > 3) && [[newMsg substringToIndex:3] isEqualToString:@"/me"];
	if (statusMessage) {
		pStyle = [messageView statusParagraphStyle];
		
		// show which user left the message, and convert common phrases
		r.location = 0; r.length = 3;
		[newMsg replaceCharactersInRange:r 
							  withString:[NSString stringWithFormat:
										  @"%@", [[msg user] name]]];
	} else {
		pStyle = [[messageView defaultParagraphStyle] mutableCopy];
		[pStyle autorelease];
		if (isOutgoing) {
			[pStyle setAlignment:NSRightTextAlignment];
		}
	}
		
	NSMutableAttributedString *attMsg = [[NSMutableAttributedString alloc] initWithString:newMsg];
	r.location = 0;
	r.length = [newMsg length];
	[attMsg addAttribute:NSParagraphStyleAttributeName
				   value:pStyle
				   range:r];
	[attMsg addAttribute:@"StatusMessage" value:[NSNumber numberWithBool:statusMessage] range:r];
	[attMsg addAttribute:@"User" value:[msg user] range:r];
	[attMsg addAttribute:@"Outgoing" value:[NSNumber numberWithBool:isOutgoing] range:r];
	if (statusMessage) {
		// change the text colour for status messages
		[attMsg addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:r];
	}
	
	// search the string for links and automatically attribute them
	// this is pretty poor at the moment, currently only detects
	// urls that start with html://  , should be improved to 
	// detect urls based on the number of . in a word
	NSRange searchRange = NSMakeRange(0, [newMsg length]);
	NSRange urlStartRange, urlEndRange;
	do 
	{
		urlStartRange = [newMsg rangeOfString:@"http://" options:0 range:searchRange];
		if (urlStartRange.length > 0) {
			// update the search range so we do not find the same url
			searchRange.location = urlStartRange.location + urlStartRange.length;
			searchRange.length = [newMsg length] - searchRange.location;
			
			// search for end of url at whitespace
			urlEndRange = [newMsg rangeOfCharacterFromSet:
						   [NSCharacterSet whitespaceAndNewlineCharacterSet]
												  options:0
													range:searchRange];
			
			// if the url ends at the end of the text, the length will be 0
			if (urlEndRange.length == 0) urlEndRange.location = [newMsg length] - 1;
			
			// update the start range to cover the entire url
			urlStartRange.length = urlEndRange.location - urlStartRange.location;
			NSURL *theURL = [NSURL URLWithString:[newMsg substringWithRange:urlStartRange]];
			NSDictionary *linkAttributes = 
				[NSDictionary dictionaryWithObjectsAndKeys:
				 theURL, NSLinkAttributeName,
				 [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
				 [NSColor blueColor], NSForegroundColorAttributeName, nil];
			
			// add the attributes to the new message
			[attMsg addAttributes:linkAttributes range:urlStartRange];
		}
	} while (urlStartRange.length != 0);
	
	// add the new string to the text view
	[[messageView textStorage] appendAttributedString:attMsg];
	[attMsg release];
	[newMsg release];	
}

#pragma mark nstextview delegate methods

- (BOOL)textView:(NSTextView*)textView clickedOnLink:(id)theLink atIndex:(NSUInteger)charIndex 
{
	return [[NSWorkspace sharedWorkspace] openURL:theLink];
}

#pragma mark split view delegate methods

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
    return (subview == leftPane);
}

- (CGFloat)splitView:(NSSplitView *)aSplitView 
constrainMinCoordinate:(CGFloat)proposedMin 
		 ofSubviewAt:(NSInteger)dividerIndex
{
	return proposedMin + kLeftPaneMinimum;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView 
constrainMaxCoordinate:(CGFloat)proposedMax 
		 ofSubviewAt:(NSInteger)dividerIndex
{
	return proposedMax - kRightPaneMinimum;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
	if ([subview isEqual:leftPane]) return NO;
	return YES;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	if (firstResize) {
		firstResize = NO;
		if ([[currentRoom isPrivate] boolValue]) {
			[splitView setPosition:0 ofDividerAtIndex:0];
		} else {
			[splitView setPosition:kDefaultDividerPosition ofDividerAtIndex:0];
		}
		lastDividerPosition = kDefaultDividerPosition;
		return;
	}
	
	// need to update the hidden status if we have moved the frame manually
	BOOL collapsed = [splitView isSubviewCollapsed:leftPane];
	[button setState:!collapsed];
	
	// store the current divider position in the sidebar tag
	if ([delegate respondsToSelector:@selector(chatViewDidResize:)]) {
		
		float width = 0;
		if (!collapsed) {
			NSRect r = [leftPane frame];
			width = r.size.width;
		}

		[delegate performSelector:@selector(chatViewDidResize:)
					   withObject:[NSNumber numberWithFloat:width]];
	}
}

#pragma mark menu delegate methods

// set the correct text for the friends menu item
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	// the user to send the message to
	NSArray *results = [usersController selectedObjects];
	User *user = [results lastObject];
	BOOL isFriend = [[user isFriend] boolValue];
	
	if (isFriend) {
		[friendMenuItem setTitle:@"Remove From Friends"];
	} else {
		[friendMenuItem setTitle:@"Add To Friends"];
	}
}

@end
