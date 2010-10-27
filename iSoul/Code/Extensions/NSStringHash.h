//
//  NSStringHash.h
//  Museeki
//
//  Created by Richard on 10/26/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <openssl/aes.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSString (md5)

+ (NSString *)md5StringWithString:(NSString *)string;
- (NSData *)AESEncryptWithKey:(NSString *)key;

@end
