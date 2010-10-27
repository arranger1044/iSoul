#import <Foundation/Foundation.h>

@interface MuseekMessage : NSObject {
	NSUInteger pos;
	NSMutableData *data;
	uint32_t code;
}

@property (readonly) uint32_t code;
@property (assign)   NSMutableData *data;
@property (readonly) void *bytes;
@property (readonly) long length;
@property long pos;

- (MuseekMessage *)appendByte:(uint8_t)value; 
- (MuseekMessage *)appendBool:(BOOL)value;
- (MuseekMessage *)appendUInt32:(uint32_t)value; 
- (MuseekMessage *)appendUInt64:(uint64_t)value;
- (BOOL)appendString:(NSString *)value; 
- (MuseekMessage *)appendCipher:(NSString *)value withKey:(NSString *)key;
- (MuseekMessage *)appendData:(NSData *)value;

- (uint64_t)readUInt64;
- (uint32_t)readUInt32;
- (uint8_t)readByte;
- (BOOL)readBool;
- (NSString *)readString;
- (NSString *)readCipherWithKey:(NSString *)key;
- (NSImage *)readImage;

@end

