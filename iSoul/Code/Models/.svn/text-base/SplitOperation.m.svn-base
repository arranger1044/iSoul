//
//  SplitOperation.m
//  iSoul
//
//  Created by Richard on 12/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SplitOperation.h"
#import "PathNode.h"

@implementation SplitOperation

- (id)initWithFiles:(NSArray *)fileList shouldSort:(BOOL)yesOrNo
{
	self = [super init];
	if (self) {
		shouldSort = yesOrNo;
		files = [fileList retain];
	}
	return self;
}

- (void)dealloc
{
	[files release];
	[super dealloc];
}

- (void)main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// get the highest path component
	PathNode *userNode = [PathNode walkedTreeFromArray:files];
	
	// to separate the trees for each user
	// create a new node with name set to the user
	// and add the file tree as its child
	PathNode *userFolder = [[PathNode alloc] init];
	[userFolder setName:[[userNode user] name]];
	[userFolder setIsFolder:YES];
	[userFolder addChild:userNode];
	[userFolder setRepresentedObject:[userNode representedObject]];
	
	// now the operation is complete, send a notification
	if (![self isCancelled]) {
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
							  [[userNode user] name], @"name",
							  userNode, @"foldertree",
							  userFolder, @"usertree",
							  [NSNumber numberWithBool:shouldSort], @"shouldSort",
							  nil];
		[[NSNotificationCenter defaultCenter] 
		 postNotificationName:@"SplitTreeFinished" 
		 object:nil userInfo:info];
	}
	
	// clean up
	[userFolder release];
	[pool release];	
}

@end
