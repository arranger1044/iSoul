//
//  DockBadge.h
//  iSoul
//
//  Created by Richard on 12/11/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DockBadge : NSView {
	float downloadRate, uploadRate;
	NSImage *downloadBadge, *uploadBadge;
	NSDictionary *attributes;
}

- (BOOL)setDownloadRate:(float)downloadRate uploadRate:(float)uploadRate;
- (void)drawBadge:(NSImage *)badge string:(NSString *)string atHeight:(float)height;

@end
