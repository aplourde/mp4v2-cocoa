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

- (id)initWithFilePath:(NSString *)path outError:(NSError **)outError {

    if (self = [super init]) {

        fileHandle = MP4Modify([path UTF8String], 0);

        if (MP4_INVALID_FILE_HANDLE == fileHandle) {

            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to open mp4 file" forKey:NSLocalizedDescriptionKey];
            *outError = [NSError errorWithDomain:@"MP42Error" code:100 userInfo:errorDetail];
        }

        filePath = path;
        metadata = [[MP4Metadata alloc] initWithFilePath:path fileHandle:fileHandle];

        if (!fileHandle) {
            return nil;
        }
    }

    return self;
}

- (BOOL)save:(NSError **)outError {

    if (fileHandle == MP4_INVALID_FILE_HANDLE) {

        if (outError != NULL) {

            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Failed to open mp4 file" forKey:NSLocalizedDescriptionKey];
            *outError = [NSError errorWithDomain:@"MP42Error" code:100 userInfo:errorDetail];
        }
        return NO;
    }

    [delegate progressChanged:50.0];

    BOOL writeMetadataSuccess = [self.metadata writeMetadataWithFileHandle:fileHandle];

    if (!writeMetadataSuccess) {

        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to write metadata" forKey:NSLocalizedDescriptionKey];
        *outError = [NSError errorWithDomain:@"MP42Error" code:100 userInfo:errorDetail];
        return NO;
    }

    [delegate progressChanged:75.0];

    MP4Close(fileHandle, 0);

    return YES;
}

- (CGSize)videoSize {

    int numberOfTrack = MP4GetNumberOfTracks(fileHandle, NULL, 0);
    for (MP4TrackId trackId = 1; trackId <= numberOfTrack; trackId++) {
        if ([[NSString stringWithCString:MP4_VIDEO_TRACK_TYPE encoding:NSUTF8StringEncoding]
                isEqualTo:[NSString stringWithCString:MP4GetTrackType(fileHandle, trackId) encoding:NSUTF8StringEncoding]]) {

            uint16_t height = MP4GetTrackVideoHeight(fileHandle, trackId);
            uint16_t width = MP4GetTrackVideoWidth(fileHandle, trackId);
            return CGSizeMake(width, height);
        }
    }
    return CGSizeMake(0, 0);
}

@end