//
//  NSData+CocoaDevUsersAdditions.h
//  GZipper
//
//  Created by valerio on 03/11/10.
//  Copyright 2010 rano. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (NSDataExtension)

// GZIP
- (NSData *) gzipInflate;
- (NSData *) gzipDeflate;

@end
