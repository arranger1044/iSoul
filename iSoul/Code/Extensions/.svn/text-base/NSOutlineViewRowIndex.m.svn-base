//
//  NSOutlineViewRowIndex.m
//  iSoul
//
//  Created by Richard on 10/28/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "NSOutlineViewRowIndex.h"


@implementation NSOutlineView (actualNode)

- (NSInteger)rowForActualItem:(id)item
{
	NSInteger rows = [self numberOfRows];
	
	for (NSInteger i = 0; i < rows; i++) {
		id nodeItem = [self itemAtRow:i];
		if ([nodeItem representedObject] == item) {
			return i;
		}
	}
	return -1;
}

@end
