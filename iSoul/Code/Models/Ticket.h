//
//  Ticket.h
//  iSoul
//
//  Created by Richard on 2/9/10.
//  Copyright 2010 BigDotProductions. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Result;
@class SidebarItem;

@interface Ticket :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSString * searchTerm;
@property (nonatomic, retain) NSNumber * stopped;
@property (nonatomic, retain) NSSet* files;
@property (nonatomic, retain) SidebarItem * sidebarItem;

@end


@interface Ticket (CoreDataGeneratedAccessors)
- (void)addFilesObject:(Result *)value;
- (void)removeFilesObject:(Result *)value;
- (void)addFiles:(NSSet *)value;
- (void)removeFiles:(NSSet *)value;

@end

