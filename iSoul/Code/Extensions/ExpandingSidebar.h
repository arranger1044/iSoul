//
//  ExpandingSidebar.h
//  iSoul
//
//  Created by Richard on 1/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"

@interface ExpandingSidebar : NSOutlineView {
	ConnectionState connectionState;
}

@property (nonatomic) ConnectionState connectionState;

- (NSRect)getIconRect;

@end
