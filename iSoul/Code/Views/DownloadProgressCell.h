//
//  DownloadProgressCell.h
//  iSoul
//
//  Created by Richard on 10/31/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DownloadProgressCell : NSTextFieldCell {
@private
	NSImage *progress;
	NSImage *progressComplete;
	NSImage *progressInactiveDark;
	NSImage *progressInactiveLight;
	NSImage *progressCap;
	NSImage *progressCapComplete;
	NSImage *progressCapInactive;
	NSImage *progressCapInactiveDark;
}

@end
