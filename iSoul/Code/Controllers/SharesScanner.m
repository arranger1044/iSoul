//
//  SharesScanner.m
//  iSoul
//
//  Created by Richard on 12/4/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "SharesScanner.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ShareNode.h"
#import "Constants.h"

@implementation SharesScanner

@synthesize fileCount;
@synthesize folderCount;

#pragma mark scanning methods

- (ShareNode *)scanFile:(NSString *)path
{
	debug_NSLog(@"started scanning shares file %@", path);	
	fileCount = folderCount = 0;
	
	// first check the shares path exists, which it
	// will not on first launch or reset
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDirectory;
	if(![fm fileExistsAtPath:path isDirectory:&isDirectory]) {
		// if not, create a blank file 
		if (![fm createFileAtPath:path contents:nil attributes:nil]) {
			NSLog(@"failed to create new shares file at %@", path);
			return nil;
		}
	}
	if (isDirectory) {
		return nil;
	}	
	
	// now read the shares file to memory
	NSError *error;
	NSData *data = [NSData dataWithContentsOfFile:path 
										  options:0 
											error:&error];
	if (!data) {
		NSLog(@"error opening shares file %@, error %@", path, error);
		return nil;
	}
	pos = 0;	// point to the start of the file
	
	// create a new file tree
	ShareNode *root = nil;
	@try {
		root = [self readDirectory:data];
		
		// set the name for root folders as the full path
		NSMutableArray *children = [root children];
		for (ShareNode *child in children) {
			[child setName:[child path]];
		}
	}
	@catch (NSException * e) {
		NSLog(@"error scanning shares file, exception %@", e);
		root = nil;
	}
	return root;
}

// returns YES if the node contents have changed
- (BOOL)populateNode:(ShareNode *)node
{
	BOOL updated = NO;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSError *error;
	
	// first check the folder has not been removed
	if (![fm fileExistsAtPath:[node path]]) {
		[(ShareNode *)[node parent] removeChild:node];
		return YES;
	}
	
	NSArray *list = [fm contentsOfDirectoryAtPath:[node path] error:&error];
	if (!list) {
		NSLog(@"failed to list directory %@, error %@", [node path], error);
		return NO;
	}
	
	// sort the directory contents
	list = [list sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	// first check if any of the nodes children are missing
	// from the file system, if so remove them from the tree
	NSMutableIndexSet *indeces = [[NSMutableIndexSet alloc] init];
	for (NSUInteger i = 0; i < [[node children] count]; i++) {
		ShareNode *oldChild = [[node children] objectAtIndex:i];
		if (![list containsObject:[oldChild name]]) {
			[indeces addIndex:i];
		}
	}
	if ([indeces count] > 0) {
		[[node children] removeObjectsAtIndexes:indeces];
		updated = YES;
	}
	[indeces release];
	
	for (NSString *name in list) {
		// ignore hidden files
		unichar firstChar = [name characterAtIndex:0];
		if (firstChar == '.') continue;
		
		// need to know if it is a dir or the file size
		NSString *fullPath = [NSString stringWithFormat:@"%@/%@", [node path], name];
		NSDictionary *d = [fm attributesOfItemAtPath:fullPath error:&error];
		if (!d) {
			NSLog(@"failed to get attributes for %@, error %@", fullPath, error);
			continue;
		}
		
		// check if the child node already exists
		ShareNode *search = [node findChild:name];
		uint32_t mtime = (uint32_t)[[d fileModificationDate] timeIntervalSince1970];
		
		if (!search) {
			updated = YES;
			ShareNode *child = [[ShareNode alloc] init];
			[child setName:name];
			[child setPath:fullPath];			
			
			// for subdirs must create another node and populate it
			if ([[d fileType] isEqual:NSFileTypeDirectory]) {
				[child setIsFolder:YES];
				[child setLastModified:mtime];				
				[self populateNode:child];				
			}
			else {
				[child setIsFolder:NO];
				[child setSize:(uint64_t)[d fileSize]];
				
				// if the file is a music file, scan for bitrate
				// length in seconds and whether it is VBR
				NSString *extension = [[name pathExtension] lowercaseString];
				if ([ws filenameExtension:extension isValidForType:@"public.audio"]) {
					AudioFileID audioFile;
					CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, 
																 (CFStringRef)fullPath, 
																 kCFURLPOSIXPathStyle, FALSE);
					if (AudioFileOpenURL(url, 0x01, 0, &audioFile) == noErr) {
						uint32_t bitrate;
						UInt32 len = sizeof(uint32_t);
						if (AudioFileGetProperty(audioFile, kAudioFilePropertyBitRate, &len, &bitrate) == noErr) {
							[child setBitrate:(bitrate / 1000)];
						} 
						
						len = sizeof(NSTimeInterval);
						NSTimeInterval duration;
						if (AudioFileGetProperty(audioFile, kAudioFilePropertyEstimatedDuration, &len, &duration) == noErr) {
							[child setDuration:(uint32_t)duration];
						} 
						AudioFileClose(audioFile);
					}
					CFRelease(url);
				}
				
			}
			
			[node addChild:child];
			[child release];			
		}
		else {
			// node aleady exists, if it is a directory
			// check to see if it has any updated contents
			if ([search isFolder] && (mtime != [search lastModified])) {
				// the folder on disk has been modified 
				// update the contents
				updated = YES;
				[search setLastModified:mtime];
				[self populateNode:search];					
			} 
		}
	}	
	return updated;
}


- (ShareNode *)readDirectory:(NSData *)data
{
	ShareNode *dir = [[[ShareNode alloc] init] autorelease];
	[dir setIsFolder:YES];
	folderCount++;
	
	// if the file is empty, we are done
	if ([data length] == 0) return dir;
	
	NSString *dirPath = [self readString:data];
	[dir setPath:dirPath];
	[dir setName:[dirPath lastPathComponent]];
	[dir setLastModified:[self readInt:data]];	// this is the mtime
	
	// first read the subdirectories
	uint32_t numFolders = [self readInt:data];
	uint32_t i;
	for (i = 0; i < numFolders; i++) {
		// create a new child item for each subdirectory
		ShareNode *child = [self readDirectory:data];
		[dir addChild:child];		
	}
	
	// now add the files
	uint32_t numFiles = [self readInt:data];
	fileCount += numFiles;
	for (i = 0; i < numFiles; i++) {
		ShareNode *file = [[ShareNode alloc] init];
		[file setIsFolder:NO];
		NSString *fileName = [self readString:data];
		[file setPath:[NSString stringWithFormat:@"%@/%@",dirPath,fileName]];
		[file setName:fileName];
		[file setSize:[self readLong:data]];
		[dir addChild:file];
		[file release];
		
		// file attributes are set only for mp3 / m4a
		// should do ogg as well, but not recognised by AudioToolbox
		[self readString:data];		// file extension
		uint32_t numAttributes = [self readInt:data];
		if (numAttributes > 0) [file setBitrate:[self readInt:data]];
		if (numAttributes > 1) [file setDuration:[self readInt:data]];
		if (numAttributes > 2) [file setVbr:([self readInt:data] > 0)];
		
		// ignore remaining attributes
		for (uint32_t j = 3; j < numAttributes; j++) {
			[self readInt:data]; 
		}
	}
	return dir;
}

- (NSString *)readString:(NSData *)data
{
	uint32_t length = [self readInt:data];
	NSRange r = NSMakeRange(pos, length);
	char *c = malloc(length + 1);
	c[length] = 0;
	[data getBytes:c range:r];
	NSString *result = [[NSString alloc] initWithBytes:c 
												length:length 
											  encoding:NSUTF8StringEncoding];	
	pos += r.length;
	free(c);
	
	return [result autorelease];
}

- (uint32_t)readInt:(NSData *)data
{
	NSRange r = NSMakeRange(pos, sizeof(uint32_t));
	uint32_t value = 0;
	[data getBytes:&value range:r];
	pos += r.length;
	
	return CFSwapInt32LittleToHost(value);
}

- (uint64_t)readLong:(NSData *)data
{
	NSRange r = NSMakeRange(pos, sizeof(uint64_t));
	uint64_t value = 0;
	[data getBytes:&value range:r];
	pos += r.length;
	
	return CFSwapInt64LittleToHost(value);
}

#pragma mark saving methods

- (BOOL)saveTree:(ShareNode *)root toPath:(NSString *)path
{
	// first write the tree to memory
	NSMutableData *data = [[NSMutableData alloc] init];
	[self packFolder:root toData:data];
	
	// now write the new config file to disk
	NSError *error;
	BOOL success = [data writeToFile:path options:NSAtomicWrite error:&error];
	[data release];
	if (!success) {
		NSLog(@"error saving share file %@, error %@", path, error);
	} else {
		debug_NSLog(@"saved share file %@ successfully", path);
	}
	return success;
}

- (BOOL)saveUnnestedTree:(ShareNode *)root toPath:(NSString *)path
{
	// create a new file tree with all folders as children of the root node
	ShareNode *newRoot = [[ShareNode alloc] init];
	[newRoot setIsFolder:YES];
	[newRoot setPath:@""];
	[newRoot setLastModified:0];
	
	// first add every subfolder as a child of the new root
	[self addFoldersOfNode:root toNode:newRoot];
	
	// finally save the unnested tree
	BOOL success = [self saveTree:newRoot toPath:path];
	[newRoot release];
	return success;
}

- (void)addFoldersOfNode:(ShareNode *)tree toNode:(ShareNode *)flatNode
{
	for (ShareNode *child in [tree children]) {
					
		if ([child isFolder]) {
			ShareNode *node = [[ShareNode alloc] init];
			[node setIsFolder:YES];
			[node setIsBuddyShare:NO];	// TODO: read the different share dbs
			[node setLastModified:[child lastModified]];
			[node setPath:[child path]];
			[flatNode addChild:node];
			
			// add all the file children as children of the new node
			for (ShareNode *file in [child children]) {
				if (![file isFolder]) {
					ShareNode *newFile = [[ShareNode alloc] init];
					[newFile setIsFolder:NO];
					[newFile setIsBuddyShare:NO];
					[newFile setName:[file name]];
					[newFile setSize:[file size]];
					[newFile setBitrate:[file bitrate]];
					[newFile setDuration:[file duration]];
					[newFile setVbr:[file vbr]];
					[node addChild:newFile];
					[newFile release];
				}
			}
			[node release];
			
			// now recursively add all the subfolders
			[self addFoldersOfNode:child toNode:flatNode];
		}
	}
}

- (void)packFolder:(ShareNode *)folder toData:(NSMutableData *)data
{
	if (![folder isFolder]) {
		NSLog(@"attempting to pack file node %@ as a folder, aborting", [folder name]);
		return;
	}
	// count the number of each child type
	uint32_t numFolders = 0;
	uint32_t numFiles = 0;
	[folder countFolders:&numFolders andFiles:&numFiles recursiveSearch:NO];
	
	[self writeString:[folder path] toData:data];		// full folder path
	[self writeInt:[folder lastModified] toData:data];	// last modified time
	[self writeInt:numFolders toData:data];				// number of child folders
	
	// iterate through the children, and for each folder
	// pack the contents to the data object in turn
	for (ShareNode *child in [folder children]) {
		if ([child isFolder]) {
			[self packFolder:child toData:data];
		}
	}
	
	// now pack each of the file objects
	[self writeInt:numFiles toData:data];
	for (ShareNode *file in [folder children]) {
		if (![file isFolder]) {
			[self writeString:[file name] toData:data];	// relative file name path
			[self writeLong:[file size] toData:data];	// file length in bytes
			
			// now write the extension
			NSString *extension = [[file name] pathExtension];
			if ([extension isEqualToString:@"mp3"] ||
				[extension isEqualToString:@"m4a"]) {
								
				// for recognised music files, store
				// the extended attributes
				[self writeString:@"mp3" toData:data];		// file extension
				[self writeInt:3 toData:data];				// 3 file attributes
				[self writeInt:[file bitrate] toData:data];	// bitrate in bps
				[self writeInt:[file duration] toData:data];	// duration in seconds
				[self writeInt:0 toData:data];				// is file VBR, no way of testing this at the mo
			}
			else {
				// only allowed extensions are mp3 and ogg for some reason
				// so just write a blank string here
				[self writeString:@"" toData:data];
				[self writeInt:0 toData:data];	// no attributes
			}			
		}
	}	
}

- (void)writeString:(NSString *)s toData:(NSMutableData *)data
{
	// length does not include null termination
	uint32_t len = [s lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	const char *utfString = [s UTF8String];
	
	// first append string length
	[self writeInt:len toData:data];
	
	// now write the string bytes
	[data appendBytes:utfString length:len];
}

- (void)writeInt:(uint32_t)value toData:(NSMutableData *)data
{
	// need to switch endianness, should be stored as LE
	uint32_t flippedValue = CFSwapInt32HostToLittle(value);
	[data appendBytes:&flippedValue length:sizeof(uint32_t)];
}

- (void)writeLong:(uint64_t)value toData:(NSMutableData *)data
{
	// need to switch endianness, should be stored as LE
	uint64_t flippedValue = CFSwapInt64HostToLittle(value);
	[data appendBytes:&flippedValue length:sizeof(uint64_t)];
}

@end
