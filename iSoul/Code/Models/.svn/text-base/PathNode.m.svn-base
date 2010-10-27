//
//  PathNode.m
//  iSoul
//
//  Created by Richard on 11/11/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "PathNode.h"
#import "Result.h"
#import "User.h"

@implementation PathNode

@dynamic isLeaf;
@synthesize isFolder;
@synthesize isExpanded;
@synthesize parent;
@synthesize children;
@synthesize name;
@synthesize path;
@synthesize representedObject;
@synthesize size;
@synthesize bitrate;

#pragma mark init & dealloc

+ (PathNode *)walkedTreeFromArray:(NSArray *)fileList
{
	PathNode *node = [PathNode fileTreeFromArray:fileList];
	
	// walk the tree to find the highest folder
	while (([[node children] count] == 1) &&
		   ([[[node children] lastObject] isFolder]))
	{
		node = [[node children] lastObject];
	}
	
	return node;
}

+ (PathNode *)walkedTreeFromSet:(NSSet *)fileSet
{
	// need to sort the tree before splitting it
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] 
									initWithKey:@"fullPath" 
									ascending:YES
									selector:@selector(caseInsensitiveCompare:)];
	NSArray *files = [[fileSet allObjects] sortedArrayUsingDescriptors:
					  [NSArray arrayWithObject:descriptor]];
	[descriptor release];
	return [PathNode walkedTreeFromArray:files];
}

+ (PathNode *)fileTreeFromArray:(NSArray *)files
{
	// start a new path tree
	PathNode *tree = [[[PathNode alloc] init] autorelease];
	[tree setIsFolder:YES];
	[tree setName:@"/"];
	[tree setRepresentedObject:[(Result *)[files objectAtIndex:0] user]];
	
	// if there are no files, do nothing
	if ([files count] > 0) {
		
		PathNode *current, *child;
		NSMutableString *path = [[NSMutableString alloc] init];
		for (Result *result in files) {
			// point to the start of the tree
			current = tree;
			NSArray *folders = [[result fullPath] componentsSeparatedByString:@"\\"];
			
			// first add the folders with children
			[path setString:@""];
			for (NSUInteger i = 0; i < [folders count] - 1; i++) {
				NSString *folder = [folders objectAtIndex:i];
				if ([folder length] == 0) continue;
				
				// append the path tree to form the folder paths
				// unix paths start with \, windows do not
				if ((i == 0) && ([[result fullPath] characterAtIndex:0] != '\\')) {
					[path appendString:folder];
				} else {
					[path appendFormat:@"\\%@",folder];
				}
				
				// check if the current folder is in the tree already
				child = [current findChild:folder];
				if (!child) {
					// if not, add it as a child
					child = [[PathNode alloc] init];
					[child setIsFolder:YES];
					[child setName:folder];
					[child setPath:path];
					[child setRepresentedObject:[result user]];
					[current addChild:child];
					[child release];
				}
				
				// now point to the child element
				current = child;
			}
			
			// finally add the file item
			NSString *file = [folders lastObject];
			PathNode *node = [[PathNode alloc] init];
			[node setName:file];
			[node setPath:[result fullPath]];
			[node setBitrate:[[result bitrate] unsignedIntValue]];
			[node setSize:[[result size] unsignedLongLongValue]];
			[node setRepresentedObject:result];
			[node setIsFolder:NO];
			[current addChild:node];
			[node release];
		}
		[path release];
		
		// now the tree is complete, walk it and add up the sizes
		[tree countSizeOfFolder];
		
	} 
	return tree;	
}

- (id)init
{
	self = [super init];
	if (self) {
		children = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self retain];
}

- (void)dealloc
{
	[parent release];
	[children release];
	[name release];
	[representedObject release];
	[super dealloc];
}

#pragma mark properties

- (BOOL)isLeaf
{
	return !isFolder;
}

- (NSUInteger)numFolders
{
	NSUInteger n = 0;
	for (PathNode *child in children) {
		if ([child isFolder]) n++;
	}
	return n;
}

- (Result *)result
{
	if (isFolder) return nil;
	else return representedObject;
}

- (User *)user
{
	if (isFolder) return representedObject;
	else return [(Result *)representedObject user];
}

#pragma mark public methods

- (void)addChild:(PathNode *)node
{
	[children addObject:node];
	[node setParent:self];
}

- (void)addSortedChild:(PathNode *)node
{
	NSUInteger i = 0;
	for (PathNode *child in children) {
		if ([[child name] caseInsensitiveCompare:[node name]] != NSOrderedAscending) {
			break;
		}
		i++;
	}
	[children insertObject:node atIndex:i];
	[node setParent:self];
}

- (void)clearChildren
{
	[children removeAllObjects];
}

- (PathNode *)findChild:(NSString *)folder
{
	for (id node in children) {
		if ([[node name] isEqualToString:folder]) {
			return node;
		}
	}
	return nil;
}


// finds the ith folder in the children
// array, used in the user browser view
// in the search array to separate files from folders
- (PathNode *)folderAtIndex:(NSInteger)i
{
	NSInteger count = 0;
	
	for (PathNode *child in children) {
		if ([child isFolder]) {
			if (i == count) {
				return child;
			}
			count++;
		}
	}
	return nil;
}

// counts the cumulative folder sizes
// and sets the corresponding entry in the node
- (uint64_t)countSizeOfFolder
{
	if (![self isFolder]) return 0;
	
	uint64_t folderSize = 0;
	for (PathNode *child in children) {
		if ([child isFolder]) {
			folderSize += [child countSizeOfFolder];
		} else {
			folderSize += [child size];
		}
	}
	[self setSize:folderSize];
	return folderSize;
}

@end
