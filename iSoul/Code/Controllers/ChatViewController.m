//
//  ChatViewController.m
//  iSoul
//
//  Created by Richard on 11/1/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "ChatViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"
#import "User.h"
#import "SidebarItem.h"
#import "MuseekdConnectionController.h"
#import "ChatMessage.h"
#import "MainWindowController.h"
#import "DataStore.h"
#import "BubbleTextView.h"
#import "iSoul_AppDelegate.h"

#define kUsersPaneMinimum	240
#define kChatPaneMinimum	140

@interface ChatViewController (Private)

- (void)windowIsMain:(NSNotification *)notification;

@end

@implementation ChatViewController

@synthesize managedObjectContext;
@synthesize museek;
@synthesize store;
@synthesize tableSortDescriptors;
@synthesize delegate;
@synthesize observedRooms;
@synthesize unreadMessages;

- (id)init
{
	self = [super initWithNibName:@"ChatView" bundle:nil];
	if (!self)
		return nil;
	
	[self setTitle:@"Chat"];
	
	// stores usernames that have been seen so far
	// if a user is new, then the user info is requested
	usersSoFar = [[NSMutableArray alloc] init];
    
    NSMutableSet * roomsToObserv = [[NSMutableSet alloc] init];
    self.observedRooms = roomsToObserv;
    [roomsToObserv release];
	
    unreadMessages = 0;

	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	//[currentRoom removeObserver:self forKeyPath:@"messages"];
    for (Room * room in observedRooms)
    {
        [room removeObserver:self forKeyPath:@"messages"];
    }
    [observedRooms release];
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
    
    [nc addObserver:self 
		   selector:@selector(windowIsMain:) 
			   name:@"NSWindowDidBecomeMainNotification" 
             object:nil];
	
	// horrid hack, forces the first resize of the 
	// split view to set the left pane to the default 
	// value, so the first chatroom is the same size
	// as all the others. please make this go away
	firstResize = YES;
	
    lastDividerPosition = (float) (splitView.frame.size.width - splitView.frame.size.width / 4);
	// selects the correct users from the data model
	[self setFetchPredicate];
    
}

#pragma mark properties

- (NSArray *)selectedUsers
{
	return [usersController selectedObjects];
}

- (void)windowIsMain:(NSNotification *)notification{
    
    if ([[notification object] isEqual:[[NSApp delegate] window]])
    {
        if ([[[NSApp delegate] currentViewController] isEqual:self])
        {
            unsigned int readMessages = [store resetSidebarCount:[currentRoom name]];
            self.unreadMessages -= readMessages;
        }
    }
}

- (void)leaveRoom:(NSString *)roomName private:(BOOL)private
{
    
    NSPredicate * pred = [NSPredicate predicateWithFormat:
                         @"name == %@ && isPrivate == %u", roomName, private];
    Room * leavingRoom = (Room *)[store find:@"Room" withPredicate:pred];
    if (!leavingRoom)
    {
        DNSLog(@"Dolores %@", roomName);
    }
    [leavingRoom removeObserver:self forKeyPath:@"messages"];
    
    [observedRooms removeObject:leavingRoom];
}

- (void)setRoomName:(NSString *)newName isPrivate:(BOOL)isPrivate
{
    
    /* Reset sidebar counter */
    unsigned int readMessages = [store resetSidebarCount:newName];
    self.unreadMessages -= readMessages;
    
    if ([newName isEqualToString:[currentRoom name]]) return;
    
    BOOL alreadyObserved = NO;
    
    for (Room * room in observedRooms)
    {
        if ([[room name] isEqual:newName])
        {
            alreadyObserved = YES;
            break;
        }
    }
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:
                         @"name == %@ && isPrivate == %u", newName, isPrivate];
    currentRoom = (Room *)[store find:@"Room" withPredicate:pred];
    [currentRoom retain];
    
    if (!alreadyObserved) 
    {
        // get the new room from the store, and load new messages
        // if the room isn't found, the currentRoom will be nil

        [currentRoom addObserver:self 
                      forKeyPath:@"messages" 
                         options:NSKeyValueObservingOptionNew 
                         context:NULL];
        
        /* Adding it to the observed rooms */
        [observedRooms addObject:currentRoom];
        DNSLog(@"Adding room to observed ones %@", [currentRoom name]);
    }
    
    // clear the chat view contents
    NSAttributedString *blankString = [[NSAttributedString alloc] initWithString:@""];
    [[messageView textStorage] setAttributedString:blankString];
    [blankString release];
    
    [self addRoomMessages:[currentRoom messages]];
    [self setFetchPredicate];

//	// stop observing the old room
//	[currentRoom removeObserver:self forKeyPath:@"messages"];
//	[currentRoom release];
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
    NSSet *newMessages = [change objectForKey:NSKeyValueChangeNewKey];
    NSUInteger newMessagesCount = newMessages.count;
    //DNSLog(@"%u", newMessagesCount);
    
	if ([object isEqual:currentRoom]) 
    {
		//DNSLog(@"%@", [object name]);
		[self addRoomMessages:newMessages];
        
        /* If the window is not visible we need to update the current room sidebar
           count as well */
        if (![[[NSApp delegate] window] isMainWindow])
        {
            NSNumber * newCount = [NSNumber numberWithUnsignedInt: (unsigned) newMessagesCount];
            [store updateSidebar:[object name] withCount:newCount];
            self.unreadMessages += newMessagesCount;
        }

	}
    else 
    {
        /* We update the other room side bar count */
        NSNumber * newCount = [NSNumber numberWithUnsignedInt: (unsigned) newMessagesCount];
        [store updateSidebar:[object name] withCount:newCount];
        self.unreadMessages += newMessagesCount;
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
    DNSLog(@"NOW");
    rect2Log(usersPane.frame);
	BOOL collapsed = [splitView isSubviewCollapsed:usersPane];
	
	if (collapsed) 
    {
		//[splitView setPosition:lastDividerPosition ofDividerAtIndex:0];
        //DNSLog(@"decollapsing");
        //[usersPane setHidden:NO];
        [self setDividerPosition:lastDividerPosition];
        //[button setState:YES];
	} 
    else 
    {
		//NSRect r = [usersPane frame];
		//lastDividerPosition = r.size.width;
        //DNSLog(@"collapsing");
        NSRect cR = [chatView frame];
        lastDividerPosition = (float) cR.size.width;
        float maxWidth = (float) splitView.frame.size.width;
		//[splitView setPosition:maxWidth ofDividerAtIndex:0];
        [self setDividerPosition:maxWidth];
        //[button setState:NO];
	}
}

#pragma mark public methods

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
//    if (flag)
//    {
//        DNSLog(@"DID STOP");
//        float width = chatView.frame.size.width;
//        [splitView setPosition:(width - splitView.dividerThickness) ofDividerAtIndex:0];
//        BOOL collapsed = [splitView isSubviewCollapsed:usersPane];
//        
//        BOOL collapsed1 = (width >= self.view.frame.size.width);
//        DNSLog(@"B %d BB %d %f", collapsed1, collapsed, width);
//        [button setState:!collapsed];   
//    }
    // need to update the hidden status if we have moved the frame manually
    float width = (float) chatView.frame.size.width;
    //[splitView adjustSubviews];
    [splitView setPosition:(width) ofDividerAtIndex:0];
    //    
    //	BOOL collapsed = [splitView isSubviewCollapsed:usersPane];
    

}

- (void)animationDidEnd:(NSAnimation *)animation{
//    DNSLog(@"ENDING");
//    rect2Log(chatView.frame);
//    rect2Log(usersPane.frame);
    float width = (float) chatView.frame.size.width;
//    //[splitView adjustSubviews];
//    //[splitView setPosition:(width) ofDividerAtIndex:0];
//    if (width >= splitView.frame.size.width - splitView.dividerThickness)
//    {
//        [usersPane setHidden:YES];
////        CGRect previousFrame = CGRectMake(lastDividerPosition, usersPane.frame.origin.y,
////                                          splitView.frame.size.width - lastDividerPosition, usersPane.frame.size.height);
////        [usersPane setFrame:previousFrame];
//    }
//    else
//    {
//        
//        DNSLog(@"decoll %f %f", width, splitView.frame.size.width);
//        [button setState:YES];
//    }
    [splitView setPosition:(width) ofDividerAtIndex:0];
}

- (void)setDividerPosition:(float)width
{
    //if (chatView.frame.size.width < splitView.frame.size.width)
    //DNSLog(@"dims %f %f", chatView.frame.size.width, width);
    if (chatView.frame.size.width != width)
    {
        [usersPane setHidden:NO];
        float space = fabsf((float) chatView.frame.size.width - width);
        float timeT = space * 0.2f / 200;
        /* Let's try to animate the sliding */
//        float minWidth = MAX(1, NSMaxX(usersPane.frame) - width - splitView.dividerThickness);
        //DNSLog(@"t %f r %f q %f", width, width + splitView.dividerThickness, NSMaxX(usersPane.frame) - width - splitView.dividerThickness);
        NSRect view0TargetFrame = NSMakeRect(chatView.frame.origin.x, chatView.frame.origin.y, width, chatView.frame.size.height);
        NSRect view1TargetFrame = NSMakeRect(width /* + splitView.dividerThickness + 1 */, usersPane.frame.origin.y, 
                                             /* minWidth */
                                             splitView.frame.size.width - width, 
                                             usersPane.frame.size.height);
        //rect2Log(view0TargetFrame);
        //rect2Log(view1TargetFrame);
        //    CAAnimation * animation = [usersPane animationForKey:@"frameOrigin"];
        //    [animation setDelegate:self];
        //    CAAnimation * animation2 = [chatView animationForKey:@"frameOrigin"];
        //    [animation2 setDelegate:self];
        //	[NSAnimationContext beginGrouping];
        //	[[NSAnimationContext currentContext] setDuration:timeT];
        //    //[[NSAnimationContext currentContext] setDelegate:self];
        //	[[chatView animator] setFrame: view0TargetFrame];
        //	[[usersPane animator] setFrame: view1TargetFrame];
        //    
        //	[NSAnimationContext endGrouping];
        //    [splitView adjustSubviews];
        
        NSDictionary * chatResize;
        chatResize = [NSDictionary dictionaryWithObjectsAndKeys:
                      chatView, NSViewAnimationTargetKey, 
                      [NSValue valueWithRect: view0TargetFrame],
                      NSViewAnimationEndFrameKey,
                      nil];
        
        NSDictionary * userPaneResize;
        userPaneResize = [NSDictionary dictionaryWithObjectsAndKeys:
                          usersPane, NSViewAnimationTargetKey, 
                          [NSValue valueWithRect: view1TargetFrame],
                          NSViewAnimationEndFrameKey,
                          nil];
        NSViewAnimation * animation= [[NSViewAnimation alloc] initWithViewAnimations:
                                      [NSArray arrayWithObjects: chatResize, userPaneResize, nil]];
        [animation setAnimationBlockingMode:NSAnimationBlocking];
        [animation setDuration:timeT];
        [animation setDelegate:self];
        [animation startAnimation];
        [splitView adjustSubviews];
        
        //    [splitView setPosition:(width) ofDividerAtIndex:0];
        //    DNSLog(@"SPLITTING");
        //    rect2Log(chatView.frame);
        //    rect2Log(usersPane.frame);
    }

}

- (NSNumber *)getDividerPosition
{
    return [NSNumber numberWithDouble:chatView.frame.size.width];
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
    return (subview == usersPane);
}

- (CGFloat)splitView:(NSSplitView *)aSplitView 
constrainMinCoordinate:(CGFloat)proposedMin 
		 ofSubviewAt:(NSInteger)dividerIndex
{
	return proposedMin + kUsersPaneMinimum;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView 
constrainMaxCoordinate:(CGFloat)proposedMax 
		 ofSubviewAt:(NSInteger)dividerIndex
{
	return proposedMax - kChatPaneMinimum;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
	if ([subview isEqual:usersPane]) return NO;
	return YES;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
//	if (firstResize) {
//		firstResize = NO;
//		if ([[currentRoom isPrivate] boolValue]) {
//			[splitView setPosition:0 ofDividerAtIndex:0];
//		} else {
//			[splitView setPosition:kDefaultDividerPosition ofDividerAtIndex:0];
//		}
//		lastDividerPosition = kDefaultDividerPosition;
//		return;
//	}
	
//	// need to update the hidden status if we have moved the frame manually
//    float width = chatView.frame.size.width;
////    [splitView setPosition:(width - splitView.dividerThickness) ofDividerAtIndex:0];
////    
////	BOOL collapsed = [splitView isSubviewCollapsed:usersPane];
//    if (width >= self.view.frame.size.width)
//    {
//        DNSLog(@"coll");
//        [button setState:YES];
//    }
//    else
//    {
//        DNSLog(@"decoll");
//        [button setState:NO];
//    }
	float width = (float) chatView.frame.size.width;
    if (width >= splitView.frame.size.width - splitView.dividerThickness)
    {
        //DNSLog(@"coll %f", width);
        button.state = NO;
    }
    else
    {
        
        //DNSLog(@"decoll %f %f", width, splitView.frame.size.width);
        button.state = YES;
    }
    
	// store the current divider position in the sidebar tag
	if ([delegate respondsToSelector:@selector(chatViewDidResize:)]) {
		
//		float width = 0;
//		if (!collapsed) {
////			NSRect userR = [usersPane frame];
////            NSRect chatR = [splitView frame];
//            NSRect chatR = [chatView frame];
//			//width = r.size.width;
//            //DNSLog(@"AFRICA %f %f %f", chatR.size.width, userR.size.width, cR.size.width);
//            //width = chatR.size.width - userR.size.width;
//            width = chatR.size.width;
//            //width = [splitView]
//		}

        
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
