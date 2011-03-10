// 
//  SidebarItem.m
//  iSoul
//
//  Created by Richard on 2/9/10.
//  Copyright 2010 BigDotProductions. All rights reserved.
//

#import "SidebarItem.h"

#import "Ticket.h"

@implementation SidebarItem 

@dynamic type;
@dynamic name;
@dynamic sortIndex;
@dynamic tag;
@dynamic isExpanded;
@dynamic count;
@dynamic children;
@dynamic parent;
@dynamic tickets;

- (void)resetCount
{
    NSNumber * zero = [[NSNumber alloc] initWithUnsignedInt:0];
    [self setCount:zero]; 
    [zero release];
}

@end
