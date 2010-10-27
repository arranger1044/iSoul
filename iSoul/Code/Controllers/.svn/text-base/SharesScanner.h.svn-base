//
//  SharesScanner.h
//  iSoul
//
//  Created by Richard on 12/4/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ShareNode;

@interface SharesScanner : NSObject {
	NSUInteger pos;
	NSUInteger fileCount;
	NSUInteger folderCount;
}

@property (readonly) NSUInteger fileCount;
@property (readonly) NSUInteger folderCount;

// public methods
- (ShareNode *)scanFile:(NSString *)path;

// for reasons unknown, museekd requires two different 
// share database file formats, one of them stores the
// shared files as a tree, with subfolders and files etc
// the other file, the one actually used by museekd i 
// suspect, has all of its folders as subfolders of the
// root node, and a folder can only contain files
// not other folders. the saveTree method saves a tree
// in the first format, the saveUnnestedTree method
// creates a new tree according to the second format
// then saves it
- (BOOL)saveTree:(ShareNode *)root toPath:(NSString *)path;
- (BOOL)saveUnnestedTree:(ShareNode *)root toPath:(NSString *)path;

// private methods
- (BOOL)populateNode:(ShareNode *)node;
- (void)addFoldersOfNode:(ShareNode *)nestedNode toNode:(ShareNode *)flatNode;
- (ShareNode *)readDirectory:(NSData *)data;
- (NSString *)readString:(NSData *)data;
- (uint32_t)readInt:(NSData *)data;
- (uint64_t)readLong:(NSData *)data;
- (void)packFolder:(ShareNode *)folder toData:(NSMutableData *)data;
- (void)writeString:(NSString *)s toData:(NSMutableData *)data;
- (void)writeInt:(uint32_t)value toData:(NSMutableData *)data;
- (void)writeLong:(uint64_t)value toData:(NSMutableData *)data;

@end
