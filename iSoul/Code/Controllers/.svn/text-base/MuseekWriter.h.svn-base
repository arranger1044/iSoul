//
//  MuseekWriter.h
//  Museeki
//
//  Created by Richard on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MuseekMessage;

@interface MuseekWriter : NSObject {
	id delegate;
	BOOL inProgress;
	NSOutputStream *stream;
	NSMutableArray *queue;
}

@property (assign) id delegate;

// public methods
- (void)setOutputStream:(NSOutputStream *)o;
- (void)open;
- (void)close;
- (void)send:(MuseekMessage *)msg;

// private methods
- (void)writeMessages;

@end
