//
//  ShareNode.m
//  iSoul
//
//  Created by Richard on 12/6/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "ShareNode.h"
#import "Constants.h"

@implementation ShareNode

@synthesize lastModified;
@synthesize duration;
@synthesize vbr;
@synthesize isBuddyShare;



- (BOOL)folderIsSubfolder:(NSString *)folder
{
	return ([folder rangeOfString:path].location != NSNotFound);
}

- (ShareNode *)findTreePosition:(NSString *)folder
{
	for (ShareNode *child in children) {
		if ([child isFolder]) {
			if ([child folderIsSubfolder:folder]) {
				return [child findTreePosition:folder];
			}
		}
	}
	
	return self;
}

- (ShareNode *)findChild:(NSString *)folder
{
	return (ShareNode *)[super findChild:folder];
}



- (void)countFolders:(uint32_t *)folders andFiles:(uint32_t *)files recursiveSearch:(BOOL)yesOrNo
{
	for (ShareNode *child in children) {
		if ([child isFolder]) {
			(*folders)++;
			if (yesOrNo) [child countFolders:folders andFiles:files recursiveSearch:YES];
		} else {
			(*files)++;
		}
	}
}

- (void)removeChild:(ShareNode *)child
{
	[children removeObjectIdenticalTo:child];
}

@end
