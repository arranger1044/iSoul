//
//  MuseekReader.h
//  Museeki
//
//  Created by Richard on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MuseekReader : NSObject<NSStreamDelegate> {
	id delegate;
	NSInputStream *stream;
	NSMutableData *data;
	NSUInteger messageSize;
}

@property (assign) id delegate;

- (void)setInputStream:(NSInputStream *)i;
- (void)open;
- (void)close;
- (void)readMessage;

@end
