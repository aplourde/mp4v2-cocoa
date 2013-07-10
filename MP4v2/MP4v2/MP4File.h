//
//  APMP4File.h
//  FilmTag
//
//  Created by Anthony Plourde on 2013-07-03.
//  Copyright (c) 2013 Anthony Plourde. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mp4v2/mp4v2.h>
#import "MP4Metadata.h"

@class MP4File;

@protocol MP4FileDelegate <NSObject>

@optional

- (void)progressChanged:(double)newProgress;

@end

@interface MP4File : NSObject {

@private

    MP4FileHandle fileHandle;
    NSString *filePath;

@protected

    MP4Metadata *metadata;
}

@property(readonly) MP4Metadata *metadata;
@property(nonatomic, unsafe_unretained) id <MP4FileDelegate> delegate;


- (id)initWithFilePath:(NSString *)path outError:(NSError **)outError;

- (BOOL)save:(NSError **)outError;

- (CGSize)videoSize;

@end
