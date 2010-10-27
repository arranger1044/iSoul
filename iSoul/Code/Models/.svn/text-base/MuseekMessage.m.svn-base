#import "MuseekMessage.h"
#import "NSDataAESDecrypt.h"
#import "NSStringHash.h"
#import "Constants.h"

@implementation MuseekMessage

@synthesize data;

- (id)init 
{
	self = [super init];
	if (self) {
		pos = 0;
		data = [[NSMutableData alloc] initWithCapacity:32];
		[self appendUInt32:0]; // size
	}
	return self;
}

- (void)dealloc
{
	[data release];
	[super dealloc];
}

- (MuseekMessage *)appendByte:(uint8_t)value 
{
	[data appendBytes:&value length:sizeof(uint8_t)];
	return self;
}

- (MuseekMessage *)appendBool:(BOOL)value
{
	uint8_t byte = (value ? 1 : 0);
	return [self appendByte:byte];
}

- (MuseekMessage *)appendUInt32:(uint32_t)value 
{
	// need to switch endianness
	uint32_t flippedValue = CFSwapInt32HostToLittle(value);
	[data appendBytes:&flippedValue length:sizeof(uint32_t)];
	return self;
}

- (MuseekMessage *)appendUInt64:(uint64_t)value 
{
	uint64_t flippedValue = CFSwapInt64HostToLittle(value);
	[data appendBytes:&flippedValue length:sizeof(uint64_t)];
	return self;
}

- (MuseekMessage *)appendData:(NSData *)value 
{
	[data appendData:value];
	return self;
}

- (BOOL)appendString:(NSString *)value 
{
	const uint8_t *charArray = (const uint8_t*)[value cStringUsingEncoding:NSUTF8StringEncoding];

	if (charArray == NULL) {
		// string conversion failed, which is odd
		// as all museekd strings should be UTF-8
		NSLog(@"failed to convert %@ to C string", value);
		return NO;
	}
	
	uint32_t stringLength = strlen((const char*)charArray);
	[self appendUInt32:stringLength];	
	[data appendBytes:charArray length:stringLength];
	
	return YES;
}

- (MuseekMessage *)appendCipher:(NSString *)value withKey:(NSString *)key
{
	// first append the unencoded string length
	uint32_t flippedLength = 
		CFSwapInt32HostToLittle([value lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	[data appendBytes:&flippedLength length:sizeof(uint32_t)];
	
	// now encode the string using the key and append
	NSData *encodedConfig = [value AESEncryptWithKey:key];
	[data appendData:encodedConfig];
	
	return self;
}


- (void *)bytes 
{
	NSAssert(data, @"data is NULL, has init been called?");
	
	// updating the first 4 bytes - Message size
	NSRange r = NSMakeRange(0, sizeof(uint32_t));
	
	// remember, the message length DOES NOT count in total length
	uint32_t structSize = CFSwapInt32HostToLittle([data length] - sizeof(uint32_t));
	
	[data replaceBytesInRange:r withBytes:&structSize];
	
	return (void *)[data bytes];
}

- (long)length 
{
	if (!data) return 0;
	return [data length];
}

- (uint64_t)readUInt64 
{
	if (pos >= [data length]) return 0;
	
	NSRange r = NSMakeRange(pos, sizeof(uint64_t));
	uint64_t value = 0;
	[data getBytes:&value range:r];
	pos += sizeof(uint64_t);	
	
	return CFSwapInt64LittleToHost(value);
}

- (uint32_t)readUInt32 
{
	if (pos >= [data length]) return 0;
  
	NSRange r = NSMakeRange(pos, sizeof(uint32_t));
	uint32_t value = 0;
	[data getBytes:&value range:r];
	pos += sizeof(uint32_t);
	
	return CFSwapInt32LittleToHost(value);
}

- (uint8_t)readByte 
{
	if (pos >= [data length]) return 0;
	
	NSRange r = NSMakeRange(pos, sizeof(uint8_t));
	uint8_t value = 0;
	[data getBytes:&value range:r];
	pos += sizeof(uint8_t);
	
	return value;
}

- (BOOL)readBool
{
	return ([self readByte] != 0);
}

- (NSString *)readString
{
	uint32_t size = [self readUInt32];
	
	if (pos >= [data length]) {	
		return @"";
	}
	
	if (size + pos > [data length]) {
		size = [data length] - pos;
	}
	
	NSRange r = NSMakeRange(pos, size);
	
	char *c = malloc(size + 1); // just for sure ;)
	c[size] = 0;
	[data getBytes:c range:r];
	NSString *result = [[NSString alloc] initWithBytes:c length:size encoding:NSUTF8StringEncoding];	
	pos += size;
	
	free(c);
	return [result autorelease];
}

- (NSString *)readCipherWithKey:(NSString *)key
{
	// cipher strings have encrypted length
	// as multiples of 16 bytes, the size
	// parameter is the unencrypted length
	uint32_t stringLength = [self readUInt32];
	uint32_t encryptedLength = stringLength;
	if ((encryptedLength % 16) != 0) {
		encryptedLength = 16 * ((encryptedLength / 16) + 1);
	} 
	
	// here we read the bytes into a buffer
	if (pos >= [data length]) return @"";
	
	if (encryptedLength + pos > [data length]) {
		NSLog(@"cipher length is greater than the message length, aborting");
		return nil;
	}
	
	NSRange r = NSMakeRange(pos, encryptedLength);
	NSString *decoded = [data decodeBytesWithRange:r 
										  password:key 
								 unencryptedLength:stringLength];
	pos += encryptedLength;
		
	return decoded;
}

- (NSImage *)readImage
{
	uint32_t size = [self readUInt32];
	
	if (pos >= [data length]) return nil;
	
	if (size + pos > [data length]) {
		NSLog(@"image size is greater than the message length, truncating");
		size = [data length] - pos;
	}
	
	NSRange r = NSMakeRange(pos, size);
	
	char *c = malloc(size); 
	[data getBytes:c range:r];
	NSData *imageData = [NSData dataWithBytesNoCopy:c length:r.length];
	NSImage *image = [[NSImage alloc] initWithData:imageData];
	
	pos += size;
	return [image autorelease];
}

- (void)setPos:(long)newPos 
{
	pos = newPos + 4;
	NSAssert (pos <= [data length], @"trying to set the cursor beyond the data");
}

- (long)pos 
{
	return pos - 4;
}

- (uint32_t)code 
{
	NSUInteger requiredLen = sizeof(uint32_t) * 2;
	
	if ([data length] < requiredLen) return 0;
	
	// store old position
	long oldPos = pos;
	
	// skip to after the message code
	pos = 4;
	uint32_t result = [self readUInt32];
	
	// restore the buffer position
	pos = oldPos;
	return result;
}

@end
