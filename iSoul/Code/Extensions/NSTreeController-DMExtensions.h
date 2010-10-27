//  NSTreeController-DMExtensions.h
//  Library
//
//  Created by William Shipley on 3/10/06.
//  Copyright 2006 Delicious Monster Software, LLC. Some rights reserved,
//    see Creative Commons license on wilshipley.com

#import <Cocoa/Cocoa.h>

@interface NSTreeController (DMExtensions)
- (void)setSelectedObjects:(NSArray *)newSelectedObjects;
- (NSIndexPath *)indexPathToObject:(id)object;
@end
