//
//  NSStringHash.m
//  Museeki
//
//  Created by Richard on 10/26/09.
//  Copyright 2009 BDP. All rights reserved.
//

#import "NSStringHash.h"


@implementation NSString (md5)

+ (NSString *)md5StringWithString:(NSString *)string
{
	const char *cStr = [string UTF8String];
	unsigned char result[16];
	CC_MD5( cStr, strlen(cStr), result );
	return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];	
}

- (NSData *)AESEncryptWithKey:(NSString *)key
{	
	// get the SHA256 hash of the key
	unsigned char passwordDigest[32];
	CC_SHA256([key UTF8String], strlen([key UTF8String]), passwordDigest);
	AES_KEY aesKey;
	AES_set_encrypt_key(passwordDigest, 256, &aesKey);
	
	// get the input byte buffer
	// must be a multiple of 16 bytes in length
	const char *utf8string = [self UTF8String];
	uint32_t stringLength = strlen(utf8string);
	uint32_t bufferLength = stringLength;
	if ((bufferLength % 16) != 0) {
		bufferLength = 16 * ((bufferLength / 16) + 1);
	} 
	unsigned char *inData = malloc(bufferLength);
	
	// copy the string to the encode buffer
	NSUInteger i;
	for (i = 0; i < stringLength; i++) {
		inData[i] = utf8string[i];
	}
	
	// fill the remaining buffer with 0s
	for (; i < bufferLength; i++) {
		inData[i] = 0;
	}
	
	// create the output byte buffer
	unsigned char *outData = malloc(bufferLength);
	
	// encode the data in chunks
	for (i = 0; i < bufferLength / 16; i++) {
		AES_encrypt(inData + (i*16), outData + (i*16), &aesKey);
	}
	
	// create the data buffer
	NSData *data = [NSData dataWithBytes:outData length:bufferLength];
	
	// clear the string buffers
	free(inData);
	free(outData);
	return data;	
}

@end
