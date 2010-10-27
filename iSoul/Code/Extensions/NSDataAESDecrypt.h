//
//  NSDataAESDecrypt.h
//  iSoul
//
//  Created by Richard on 11/2/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <openssl/aes.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSData (AESDecrypt) 

- (NSString *)decodeBytesWithRange:(NSRange)range password:(NSString *)password unencryptedLength:(NSUInteger)len;

@end
