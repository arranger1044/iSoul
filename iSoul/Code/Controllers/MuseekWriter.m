//
//  MuseekWriter.m
//  Museeki
//
//  Created by Richard on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MuseekWriter.h"
#import "Constants.h"
#import "MuseekdConnectionController.h"

@implementation MuseekWriter

@synthesize delegate;

#pragma mark initialization and deallocation

- (id)init
{
	self = [super init];
	if (self) {
		stream = nil;
		delegate = nil;
		inProgress = NO;
		queue = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[self close];
	[queue release];
	[super dealloc];
}

#pragma mark properties

- (void)setOutputStream:(NSOutputStream *)i
{
	// close the current stream if set
	if (stream) {
		[stream close];
		[stream setDelegate:nil];
		[stream removeFromRunLoop:[NSRunLoop currentRunLoop] 
						  forMode:NSDefaultRunLoopMode];
		[stream release];		
	}
	
	// now set and retain the stream
	stream = i;
	[stream retain];
}

#pragma mark methods

- (void)open
{
	if (stream) {
		[stream setDelegate:self];
		[stream scheduleInRunLoop:[NSRunLoop currentRunLoop] 
						  forMode:NSDefaultRunLoopMode];
		[stream open];	
	}
}

- (void)close
{
	[self setOutputStream:nil];
	if ([delegate respondsToSelector:@selector(setState:)]) {
		[delegate performSelector:@selector(setState:) withObject:usOffline];
	}
}

- (void)send:(MuseekMessage *)msg
{
	//debug_NSLog(@"queuing message");
	[queue addObject:msg];
	[self writeMessages];
}

- (void)writeMessages
{
	// check for active stream or present messages
	if (!inProgress && stream && [stream hasSpaceAvailable] && ([queue count] > 0)) {
		inProgress = YES;
		//debug_NSLog(@"writing new message to stream %d", [queue count]);
		
		MuseekMessage *msg = [queue objectAtIndex:0];
		
		// first write to the stream
		[stream write:[msg bytes] maxLength:[msg length]];
		
		// now remove the message from the queue
		[queue removeObjectAtIndex:0];
		
		inProgress = NO;
	}
}

#pragma mark NSOutputStream delegate method

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
	switch (streamEvent) 
	{
		case NSStreamEventEndEncountered:
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"error in output stream, disconnecting. (%@)", [theStream streamError]);
			[self close];
			break;
		}
		case NSStreamEventHasSpaceAvailable:
		{
			[self writeMessages];
			break;
		}
	}
}

@end
