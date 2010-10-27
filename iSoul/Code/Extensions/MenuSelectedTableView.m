//
//  MenuSelectedTableView.m
//  iSoul
//
//  Created by Richard on 12/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MenuSelectedTableView.h"


@implementation MenuSelectedTableView

-(NSMenu *)menuForEvent:(NSEvent *)event
{
	// Find which row is under the cursor
	[[self window] makeFirstResponder:self];
	NSPoint menuPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	int row = [self rowAtPoint:menuPoint];
	
	/* Update the table selection before showing menu
	 Preserves the selection if the row under the mouse is selected (to allow for
	 multiple items to be selected), otherwise selects the row under the mouse */
	BOOL currentRowIsSelected = [[self selectedRowIndexes] containsIndex:row];
	if (!currentRowIsSelected)
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] 
		  byExtendingSelection:YES];
	
	if ([self numberOfSelectedRows] <=0)
	{
        // No rows are selected, so the table should be displayed with all items disabled
		NSMenu* tableViewMenu = [[self menu] copy];
		int i;
		for (i=0;i<[tableViewMenu numberOfItems];i++)
			[[tableViewMenu itemAtIndex:i] setEnabled:NO];
		return [tableViewMenu autorelease];
	}
	else
		return [self menu];
}

@end
