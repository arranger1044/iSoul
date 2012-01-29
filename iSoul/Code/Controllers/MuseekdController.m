	//
//  MuseekdController.m
//  SolarSimple
//
//  Created by Marcelo Alves on 13/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MuseekdController.h"
#import "Constants.h"
#include <signal.h>
#include <sys/types.h>
#include <unistd.h>

#define kPasswordLength	10

@implementation MuseekdController

@synthesize port, password;

- (id)init
{
	self = [super init];
	if (self != nil) {
		// create random password
		srandom((unsigned) [NSDate.date timeIntervalSince1970]);
		
		char randoms[kPasswordLength + 1];
		char aRandom;
		for (int i = 0; i < kPasswordLength; i++) {
			while (YES) {
				aRandom = (char)random() + 128;
				if (((aRandom >= '0') && (aRandom <= '9')) || 
					((aRandom >= 'a') && (aRandom <= 'z')) ||
					((aRandom >= 'A') && (aRandom <= 'Z'))) {
					randoms[i] = aRandom;
					break; // we found an alphanumeric character, move on
				}
			}
		}
		randoms[kPasswordLength] = 0;
		password = [NSString stringWithCString:(const char*)randoms 
									  encoding:NSUTF8StringEncoding];
		[password retain];
	}
	return self;
}


- (BOOL)startMuseekd 
{
	if (museekd) [self stopMuseekd];
	
	// the path to the process pid file
	NSString *pidPath = [[NSString stringWithFormat:
						  @"%@/%@", pathBaseFolder, pathPidFile] 
						 stringByExpandingTildeInPath];
	
	// check if a museekd process is running
	// this happens when the application is force quit
	NSError *error;
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:pidPath]) {
		// first check if the process is still running		
		NSString *pidString = [NSString stringWithContentsOfFile:pidPath
														encoding:NSUTF8StringEncoding
														   error:NULL];
		pid_t oldPid = [pidString intValue];
		debug_NSLog(@"The Museekd daemon is still running, killing now");
		kill(oldPid, SIGTERM);
		if (![fm removeItemAtPath:pidPath error:&error]) {
			NSLog(@"Failed to remove pid file %@, error %@", pidPath, error);
		}
	}
	
	// this function will put the randomized password
	// into the config file and return the path
	// if no config file exists, a new one will be created
	// from the template held in the application bundle
	NSString *configPath = [self updateConfigFile];
	if (!configPath) {
		NSLog(@"error updating the config file, museekd launch aborted");
		return NO;
	}
	
	// create the task to run museekd
	museekd = [[NSTask alloc] init];	
	NSString *basePath = [[NSBundle mainBundle] bundlePath];
	NSString *museekdPath = [NSString stringWithFormat:@"%@/Contents/Resources/museek", basePath];
	[museekd setLaunchPath:museekdPath];
	
    /* TODO this ifdef shall be deleted somehow */
#ifdef _DEBUG
	[museekd setStandardOutput:[NSFileHandle fileHandleWithStandardOutput]];
	[museekd setStandardError:[NSFileHandle fileHandleWithStandardError]];
#else
	[museekd setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
	[museekd setStandardError:[NSFileHandle fileHandleWithNullDevice]];
#endif
	
	NSArray *museekdParameters = [NSArray arrayWithObjects:@"-c", configPath, nil];	
	[museekd setArguments:museekdParameters];
	
	// launch the task, throws an exception if the path or parameters are bad
	@try {
		[museekd launch];
	}
	@catch (NSException * e) {
		DNSLog(@"Error launching museekd daemon, exception %@", e);
		return NO;
	}	
	
	// store the pid for later termination
	NSString *pidString = [NSString stringWithFormat:@"%d", [museekd processIdentifier]];
	BOOL success = [pidString writeToFile:pidPath 
							   atomically:YES 
								 encoding:NSUTF8StringEncoding 
									error:&error];
	if (!success) {
		DNSLog(@"Error writing pid file %@, error %@", pidPath, error);
		[self stopMuseekd];
		return NO;
	}
	 
	return YES;
}

-(void) stopMuseekd 
{
	[museekd interrupt];
	[museekd waitUntilExit];
	[museekd release];
	museekd = nil;
	
	// clean up the pid file
	NSString *pidPath = [[NSString stringWithFormat:
						  @"%@/%@", pathBaseFolder, pathPidFile] 
						 stringByExpandingTildeInPath];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:pidPath]) {
		NSError *error;
		if (![fm removeItemAtPath:pidPath error:&error]) {
			NSLog(@"Unable to remove pid file %@, error %@", pidPath, error);
		}
	}
}

- (void)restartMuseekd 
{
	[self stopMuseekd];
	[self startMuseekd];
}


-(void) dealloc 
{
	[self stopMuseekd];
	[password release];
	[super dealloc];
}

- (NSString *)updateConfigFile
{
	// application support folder
	NSString *baseFolder = [pathBaseFolder stringByExpandingTildeInPath];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// if not present, try and create the base support folder
	BOOL success = YES;
	NSError *error = nil;
	if (![fm fileExistsAtPath:baseFolder]) {
		success = [fm createDirectoryAtPath:baseFolder 
				withIntermediateDirectories:YES 
								 attributes:nil 
									  error:&error];
		if (!success) {
			NSLog(@"failed to create support folder at %@, with error %@", baseFolder, error);
			return nil;
		}
	}	
	
	// now check for the config file
	NSString *configPath = [NSString stringWithFormat:@"%@/config.xml",baseFolder];
	if (![fm fileExistsAtPath:configPath]) {
		// config file is not present
		// first create the default download locations
		NSString *downloadPath = [pathDownloads stringByExpandingTildeInPath];
		NSString *incompletePath = [pathIncomplete stringByExpandingTildeInPath];
		if (![fm fileExistsAtPath:downloadPath]) {
			success = [fm createDirectoryAtPath:downloadPath 
					withIntermediateDirectories:YES 
									 attributes:nil 
										  error:&error];
			
			if (!success) {
				NSLog(@"failed to create save path %@, error %@", downloadPath, error);
				return nil;
			}
		}
		if (![fm fileExistsAtPath:incompletePath]) {
			success = [fm createDirectoryAtPath:incompletePath 
					withIntermediateDirectories:YES 
									 attributes:nil 
										  error:&error];
			if (!success) {
				NSLog(@"failed to create incomplete folder %@, error %@", incompletePath, error);
				return nil;
			}
		}
		
		// now create a new config file from the default template
		NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"config" 
																 ofType:@"xml" 
															inDirectory:nil];
		NSString *xml = [NSString stringWithContentsOfFile:templatePath 
												  encoding:NSUTF8StringEncoding 
													 error:&error];
		if (!xml) {
			NSLog(@"failed to read template config.xml, with error %@", error);
			return nil;
		}
		
		// now the default folder values need to be filled
		xml = [xml stringByReplacingOccurrencesOfString:@"#{BASEFOLDER}" 
											 withString:baseFolder];
		xml = [xml stringByReplacingOccurrencesOfString:@"#{DOWNLOADDIR}" 
											 withString:downloadPath];
		xml = [xml stringByReplacingOccurrencesOfString:@"#{INCOMPLETEDIR}" 
											 withString:incompletePath];
		
		// finally output the config file
		success = [xml writeToFile:configPath 
						atomically:YES 
						  encoding:NSUTF8StringEncoding 
							 error:&error];
		if (!success) {
			NSLog(@"failed to write new config file, error %@", error);
			return nil;
		}		
	}
	
	// load the config file to memory, so the password can be
	// updated and the port read
	NSString *config = [NSString stringWithContentsOfFile:configPath
												 encoding:NSUTF8StringEncoding
													error:&error];
	if (!config) {
		NSLog(@"failed to open config file %@, error %@", configPath, error);
		return nil;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:config];
	
	// first get the connection port
	NSString *portString;
	[scanner scanUpToString:@"<domain id=\"interfaces.bind\">" intoString:NULL];
	[scanner scanUpToString:@"<key id=\"localhost:" intoString:NULL];
	[scanner scanString:@"<key id=\"localhost:" intoString:NULL];
	if ([scanner scanUpToString:@"\"" intoString:&portString]) {
		port = (NSUInteger) portString.intValue;
	} else {
		NSLog(@"error reading the port number");
		return nil;
	}
		
	// now replace the password in the config file
	// with the randomly generated one created at init
	// first find the interfaces domain
	[scanner setScanLocation:0];
	[scanner scanUpToString:@"<domain id=\"interfaces\">" intoString:NULL];
	[scanner scanUpToString:@"<key id=\"password\">" intoString:NULL];
	[scanner scanString:@"<key id=\"password\">" intoString:NULL];
	NSUInteger startIndex = [scanner scanLocation];
	[scanner scanUpToString:@"<" intoString:NULL];
	NSUInteger endIndex = [scanner scanLocation];
	NSRange r = NSMakeRange(startIndex, endIndex - startIndex);
	config = [config stringByReplacingCharactersInRange:r 
											 withString:password];
	
	// finally save the config file
	success = [config writeToFile:configPath 
					   atomically:YES 
						 encoding:NSUTF8StringEncoding 
							error:&error];
	if (!success) {
		NSLog(@"failed to write new config file, error %@", error);
		return nil;
	}		
	
	return configPath;	
}

@end
