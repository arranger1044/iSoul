//
//  NSDataAESDecrypt.m
//  iSoul
//
//  Created by Richard on 11/2/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "NSDataAESDecrypt.h"

@implementation NSData (AESDecrypt) 

- (NSString *)decodeBytesWithRange:(NSRange)range 
						  password:(NSString *)password
				 unencryptedLength:(NSUInteger)len
{
	// get the SHA256 hash of the password
	unsigned char passwordDigest[32];
	CC_SHA256([password UTF8String], strlen([password UTF8String]), passwordDigest);
	AES_KEY aesKey;
	AES_set_decrypt_key(passwordDigest, 256, &aesKey);
	
	// get the input byte buffer
	unsigned char *inData = malloc(range.length);
	[self getBytes:inData range:range];
		
	// create the output byte buffer
	unsigned char *outData = malloc(range.length);
	
	// decode the data in chunks
	for (NSUInteger i = 0; i < range.length / 16; i++) {
		AES_decrypt(inData + (i*16), outData + (i*16), &aesKey);
	}
	
	// create the string
	NSString *str = [[NSString alloc] initWithBytes:outData 
											 length:len 
										   encoding:NSUTF8StringEncoding];
	
	// clear the buffers
	free(inData);
	free(outData);
	return [str autorelease];
}

@end
