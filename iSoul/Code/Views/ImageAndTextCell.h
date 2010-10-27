//
//  FileCell.h
//  iSoul
//
//  Created by Richard on 10/29/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImageAndTextCell : NSTextFieldCell {
@private
	NSImage *image;
}

@property (retain) NSImage *image;

@end
