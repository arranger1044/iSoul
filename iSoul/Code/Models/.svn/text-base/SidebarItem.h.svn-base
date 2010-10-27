//
//  SidebarItem.h
//  iSoul
//
//  Created by Richard on 2/9/10.
//  Copyright 2010 BigDotProductions. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Ticket;

@interface SidebarItem :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * sortIndex;
@property (nonatomic, retain) NSNumber * tag;
@property (nonatomic, retain) NSNumber * isExpanded;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) NSSet* children;
@property (nonatomic, retain) SidebarItem * parent;
@property (nonatomic, retain) NSSet* tickets;

@end


@interface SidebarItem (CoreDataGeneratedAccessors)
- (void)addChildrenObject:(SidebarItem *)value;
- (void)removeChildrenObject:(SidebarItem *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;

- (void)addTicketsObject:(Ticket *)value;
- (void)removeTicketsObject:(Ticket *)value;
- (void)addTickets:(NSSet *)value;
- (void)removeTickets:(NSSet *)value;

@end

