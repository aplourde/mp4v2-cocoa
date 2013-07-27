//
//  APMP4Metadata.h
//  FilmTag
//
//  Created by Anthony Plourde on 2013-07-03.
//  Copyright (c) 2013 Anthony Plourde. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mp4v2/mp4v2.h>

typedef enum {
    MP4MediaTypeMovie = 9,
    MP4MediaTypeTvShow = 10
} MP4MediaType;

@interface MP4Metadata : NSObject {

    NSString *sourcePath;
    NSString *name;
    NSString *comments;
    NSString *genre;
    NSString *releaseDate;
    NSString *shortDescription;
    NSString *longDescription;
    BOOL hd;
    MP4MediaType type;
    NSString *contentRating;
    NSImage *artwork;
    NSString *studio;
    NSString *screenFormat;
    NSArray *cast;
    NSArray *directors;
    NSArray *screenwriters;
    NSArray *producers;
}

- (id)initWithFilePath:(NSString *)source fileHandle:(MP4FileHandle)fileHandle;

- (void)printCurrentTags;

- (BOOL)writeMetadataWithFileHandle:(MP4FileHandle *)fileHandle;

@property(nonatomic, retain) NSString *sourcePath;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *comments;
@property(nonatomic, retain) NSString *genre;
@property(nonatomic, retain) NSString *releaseDate;
@property(nonatomic, retain) NSString *shortDescription;
@property(nonatomic, retain) NSString *longDescription;
@property(nonatomic) BOOL hd;
@property(nonatomic) MP4MediaType type;
@property(nonatomic) NSString *contentRating;
@property(nonatomic, retain) NSImage *artwork;
@property(nonatomic, retain) NSString *studio;
@property(nonatomic, retain) NSString *screenFormat;
@property(nonatomic, retain) NSArray *cast;
@property(nonatomic, retain) NSArray *directors;
@property(nonatomic, retain) NSArray *screenwriters;
@property(nonatomic, retain) NSArray *producers;


@end
