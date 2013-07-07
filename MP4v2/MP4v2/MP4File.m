//
//  APMP4File.m
//  FilmTag
//
//  Created by Anthony Plourde on 2013-07-03.
//  Copyright (c) 2013 Anthony Plourde. All rights reserved.
//

#import "MP4File.h"

@implementation MP4File

@synthesize metadata;
@synthesize delegate;

- (id) initWithFilePath:(NSString *)path
{
    if (self = [super init])
	{
		fileHandle = MP4Modify([path UTF8String], 0);
        filePath = path;
        metadata = [[MP4Metadata alloc] initWithFilePath:path fileHandle:fileHandle];
		if (!fileHandle) {
			return nil;
        }
	}
    
	return self;
}

- (BOOL) save:(NSError **)outError {
    
    if (fileHandle == MP4_INVALID_FILE_HANDLE) {
        if ( outError != NULL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to open mp4 file" forKey:NSLocalizedDescriptionKey];
            *outError = [NSError errorWithDomain:@"MP42Error"
                                            code:100
                                        userInfo:errorDetail];
        }
        return NO;
    }
    [self.metadata writeMetadataWithFileHandle:fileHandle];
    MP4Close(fileHandle, 0);
    
    NSString *tempOutputFileName = [[filePath lastPathComponent] stringByAppendingString:@".tmp"];
    NSString *tempOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempOutputFileName];
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:tempOutputPath error:nil];
    unsigned long long originalFileSize = [[[fileManager attributesOfItemAtPath:filePath error:nil] valueForKey:NSFileSize] unsignedLongLongValue];
    __block BOOL done = NO;
    __block BOOL success = NO;
    
    dispatch_async(
       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
           success = MP4Optimize([filePath UTF8String], [tempOutputPath UTF8String]);
           done = YES;
           if (!success) {
               NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
               [errorDetail setValue:@"Failed to optimize mp4 file" forKey:NSLocalizedDescriptionKey];
               *outError = [NSError errorWithDomain:@"MP42Error"
                                               code:100
                                           userInfo:errorDetail];
           }
    });
    
    while (!done) {
        unsigned long long fileSize = [[[fileManager attributesOfItemAtPath:tempOutputPath error:nil] valueForKey:NSFileSize] unsignedLongLongValue];
		if (delegate)
			[delegate progressChanged:((double)fileSize / originalFileSize) * 100];
        usleep(450000);
    }
    
    if (success) {
		[fileManager removeItemAtPath:filePath error:outError];
		[fileManager moveItemAtPath:tempOutputPath toPath:filePath error:outError];
    }
    return YES;
}

- (CGSize) videoSize {
    
    int numberOfTrack = MP4GetNumberOfTracks(fileHandle, NULL, 0);
    for(int i=1;i<=numberOfTrack;i++) {
        if ([[NSString stringWithCString:MP4_VIDEO_TRACK_TYPE encoding:NSUTF8StringEncoding]
             isEqualTo:[NSString stringWithCString:MP4GetTrackType(fileHandle, i) encoding:NSUTF8StringEncoding]]) {

            uint16_t height = MP4GetTrackVideoHeight(fileHandle, i);
            uint16_t width = MP4GetTrackVideoWidth(fileHandle, i);
            return CGSizeMake(width, height);
        }
    }
    return CGSizeMake(0, 0);
}

@end