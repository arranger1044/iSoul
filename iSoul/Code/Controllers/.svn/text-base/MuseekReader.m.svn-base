//
//  MuseekReader.m
//  Museeki
//
//  Created by Richard on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MuseekReader.h"
#import "MuseekMessage.h"
#import "Constants.h"
#import "MuseekdConnectionController.h"

#define MAX_BYTES (NSUInteger)1024

@implementation MuseekReader

@synthesize delegate;

#pragma mark initialization and deallocation

- (id)init
{
	self = [super init];
	if (self) {
		stream = nil;
		delegate = nil;
		data = [[NSMutableData alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[self close];
	[data release];
	[super dealloc];
}

#pragma mark properties

- (void)setInputStream:(NSInputStream *)i
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
	[self setInputStream:nil];
	if ([delegate respondsToSelector:@selector(setState:)]) {
		[delegate performSelector:@selector(setState:) withObject:usOffline];
	}
}

- (void)readMessage
{
	if (![stream hasBytesAvailable]) return;
	
	NSInteger bytesRead;
	if ([data length] == 0) {
		// first read the size of the message
		uint32_t size;
		bytesRead = [stream read:(void *)&size maxLength:sizeof(uint32_t)];
		messageSize = CFSwapInt32LittleToHost(size);
		
		if (bytesRead != sizeof(uint32_t)) {
			NSLog(@"failed to read stream message");
			return;
		}
	}
	
	// now add the data to the buffer
	NSUInteger offset = [data length];
	NSUInteger remainingBytes = MIN(messageSize - offset, MAX_BYTES);
	
	// first expand the buffer by the required amount
	[data setLength:(offset + remainingBytes)];
	bytesRead = [stream read:(uint8_t *)([data bytes] + offset) maxLength:remainingBytes];
		
	// now check the correct amount of data was read
	// if not, shrink the buffer to fit
	if ((NSUInteger)bytesRead != remainingBytes) {
		//debug_NSLog(@"shrinking buffer, read %d of %u bytes",bytesRead,remainingBytes);
		[data setLength:(offset + bytesRead)];
	}
	
	// check whether the message is complete
	if ([data length] >= messageSize) {
		MuseekMessage *msg = [[[MuseekMessage alloc] init] autorelease];
		[msg appendData:data];
		
		// clear the message buffer
		[data setLength:0];
		
		// report the message back to the delegate
		if ([delegate respondsToSelector:@selector(processMessage:)]) {
			[delegate performSelector:@selector(processMessage:) withObject:msg];
		}
	}
	
}

#pragma mark NSInputStream delegate method

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
	switch (streamEvent) 
	{
		case NSStreamEventEndEncountered:
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"error in input stream, disconnecting. (%@)", [theStream streamError]);
			[self close];
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			[self readMessage];
			break;
		}
	}
}

@end
