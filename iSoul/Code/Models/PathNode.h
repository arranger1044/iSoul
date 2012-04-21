//
//  PathNode.h
//  iSoul
//
//  Created by Richard on 11/11/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PathNode;
@class Result;
@class User;

@interface PathNode : NSObject {
	uint32_t bitrate;
	uint64_t size;	
	BOOL isFolder;
	BOOL isExpanded;
	NSString *name;
	NSString *path;
	id representedObject;
	PathNode *parent;
	NSMutableArray *children;
}

@property (readwrite) uint32_t bitrate;
@property (readwrite) uint64_t size;
@property (copy) NSString *name;
@property (copy) NSString *path;
@property (readwrite) BOOL isExpanded;
@property (readwrite) BOOL isFolder;
@property (readonly) BOOL isLeaf;
@property (retain) PathNode *parent;
@property (retain) id representedObject;
@property (retain) NSMutableArray *children;
@property (readonly) NSUInteger numFolders;
@property (readonly) Result *result;
@property (readonly) User *user;

+ (PathNode *)walkedTreeFromSet:(NSSet *)fileSet;
+ (PathNode *)walkedTreeFromArray:(NSArray *)fileList;
+ (PathNode *)fileTreeFromArray:(NSArray *)fileList;
- (void)addChild:(PathNode *)node;
- (void)addSortedChild:(PathNode *)node;
- (PathNode *)findChild:(NSString *)folder;
- (PathNode *)folderAtIndex:(NSInteger)i;
- (void)clearChildren;
- (uint64_t)countSizeOfFolder;

@end
