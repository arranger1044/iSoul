//
//  ShareNode.h
//  iSoul
//
//  Created by Richard on 12/6/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PathNode.h"

@interface ShareNode : PathNode {
	// mtime needs to be stored as uint
	uint32_t lastModified;
	uint32_t duration;
	BOOL vbr;
	BOOL isBuddyShare;
}

@property (readwrite) uint32_t lastModified;
@property (readwrite) uint32_t duration;
@property (readwrite) BOOL vbr;
@property (readwrite) BOOL isBuddyShare;


- (BOOL)folderIsSubfolder:(NSString *)folder;
- (void)countFolders:(uint32_t *)nFolders andFiles:(uint32_t *)nFiles recursiveSearch:(BOOL)yesOrNo;
- (ShareNode *)findTreePosition:(NSString *)folder;
- (ShareNode *)findChild:(NSString *)newPath;
- (void)removeChild:(ShareNode *)child;

@end
