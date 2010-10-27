//
//  MuseekdController.h
//  SolarSimple
//
//  Created by Marcelo Alves on 13/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MuseekdController : NSDocument {
	NSTask *museekd;
	NSString *password;
	NSUInteger port;
}

@property (nonatomic, readonly) NSString* password;
@property (nonatomic, readonly) NSUInteger port;

- (BOOL)startMuseekd;
- (void)stopMuseekd;
- (void)restartMuseekd;
- (NSString *)updateConfigFile;

@end
