//
//  APMP4Metadata.m
//  FilmTag
//
//  Created by Anthony Plourde on 2013-07-03.
//  Copyright (c) 2013 Anthony Plourde. All rights reserved.
//

#import "MP4Metadata.h"

@implementation MP4Metadata

@synthesize sourcePath;
@synthesize name;
@synthesize comments;
@synthesize genre;
@synthesize releaseDate;
@synthesize shortDescription;
@synthesize longDescription;
@synthesize hd;
@synthesize type;
@synthesize artwork;
@synthesize studio;
@synthesize screenFormat;
@synthesize cast;
@synthesize directors;
@synthesize screenwriters;
@synthesize producers;

- (id)initWithFilePath:(NSString *)source fileHandle:(MP4FileHandle)fileHandle {

    if ((self = [super init])) {
        sourcePath = source;
        [self readMetaDataFromFileHandle:fileHandle];
    }

    return self;
}

- (void)readMetaDataFromFileHandle:(MP4FileHandle)sourceHandle {

    const MP4Tags *tags = MP4TagsAlloc();
    MP4TagsFetch(tags, sourceHandle);

    self.name = nil;
    self.comments = nil;
    self.genre = nil;
    self.releaseDate = nil;
    self.shortDescription = nil;
    self.longDescription = nil;
    self.hd = NO;
    self.type = MP4MediaTypeMovie;
    self.artwork = nil;
    self.cast = nil;
    self.directors = nil;
    self.screenwriters = nil;
    self.producers = nil;
    self.studio = nil;

    if (tags->name) {
        self.name = [NSString stringWithCString:tags->name encoding:NSUTF8StringEncoding];
    }
    if (tags->comments) {
        self.comments = [NSString stringWithCString:tags->comments encoding:NSUTF8StringEncoding];
    }
    if (tags->genre) {
        self.genre = [NSString stringWithCString:tags->genre encoding:NSUTF8StringEncoding];
    }
    if (tags->releaseDate) {
        self.releaseDate = [NSString stringWithCString:tags->releaseDate encoding:NSUTF8StringEncoding];
    }
    if (tags->description) {
        self.shortDescription = [NSString stringWithCString:tags->description encoding:NSUTF8StringEncoding];
    }
    if (tags->longDescription) {
        self.longDescription = [NSString stringWithCString:tags->longDescription encoding:NSUTF8StringEncoding];
    }
    if (tags->hdVideo) {
        self.hd = *tags->hdVideo;
    }
    if (tags->mediaType) {
        self.type = (MP4MediaType) *tags->mediaType;
    }

    if (tags->artwork) {

        NSData *imageData = [NSData dataWithBytes:tags->artwork->data length:tags->artwork->size];
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
        if (imageRep != nil) {
            self.artwork = [[NSImage alloc] initWithSize:[imageRep size]];
            [self.artwork addRepresentation:imageRep];
        }
    }

    MP4TagsFree(tags);

    /* read the remaining iTMF items */
    MP4ItmfItemList *list = MP4ItmfGetItemsByMeaning(sourceHandle, "com.apple.iTunes", "iTunMOVI");
    if (list) {
        uint32_t i;
        for (i = 0; i < list->size; i++) {
            MP4ItmfItem *item = &list->elements[i];
            uint32_t j;
            for (j = 0; j < item->dataList.size; j++) {
                MP4ItmfData *data = &item->dataList.elements[j];
                NSData *xmlData = [NSData dataWithBytes:data->value length:data->valueSize];
                NSDictionary *dma = (NSDictionary *) [NSPropertyListSerialization
                        propertyListFromData:xmlData
                            mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                      format:nil
                            errorDescription:nil];

                if ([dma valueForKey:@"cast"] != nil)
                    self.cast = [NSArray arrayWithArray:[dma valueForKey:@"cast"]];
                if ([dma valueForKey:@"directors"] != nil)
                    self.directors = [NSArray arrayWithArray:[dma valueForKey:@"directors"]];
                if ([dma valueForKey:@"producers"] != nil)
                    self.producers = [NSArray arrayWithArray:[dma valueForKey:@"producers"]];
                if ([dma valueForKey:@"screenwriters"] != nil)
                    self.screenwriters = [NSArray arrayWithArray:[dma valueForKey:@"screenwriters"]];
                if ([dma valueForKey:@"studio"] != nil)
                    self.studio = [dma valueForKey:@"studio"];
                if ([dma valueForKey:@"asset-info"] != nil && [[dma valueForKey:@"asset-info"] valueForKey:@"screen-format"] != nil) {
                    self.screenFormat = [[dma valueForKey:@"asset-info"] valueForKey:@"screen-format"];
                }
            }
        }
        MP4ItmfItemListFree(list);
    }
}

- (BOOL)writeMetadataWithFileHandle:(MP4FileHandle *)fileHandle {

    if (!fileHandle)
        return NO;

    const MP4Tags *tags = MP4TagsAlloc();

    BOOL success = MP4TagsFetch(tags, fileHandle);
    if (!success) {
        return NO;
    }

    if (self.name) {
        MP4TagsSetName(tags, [self.name UTF8String]);
    }
    if (self.comments) {
        MP4TagsSetComments(tags, [self.comments UTF8String]);
    }
    if (self.genre) {
        MP4TagsSetGenre(tags, [self.genre UTF8String]);
    }
    if (self.releaseDate) {
        MP4TagsSetReleaseDate(tags, [self.releaseDate UTF8String]);
    }
    if (self.shortDescription) {
        MP4TagsSetDescription(tags, [self.shortDescription UTF8String]);
    }
    if (self.longDescription) {
        MP4TagsSetLongDescription(tags, [self.longDescription UTF8String]);
    }
    uint8_t mediaType = self.type ? (uint8_t) self.type : 9;
    MP4TagsSetMediaType(tags, &mediaType);

    uint8_t isHd = self.hd == YES ? 1 : 0;
    MP4TagsSetHDVideo(tags, &isHd);


    if (self.artwork) {
        MP4TagArtwork newArtwork;
        NSArray *representations;
        NSData *bitmapData;
        representations = [self.artwork representations];
        bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations
                                                              usingType:NSPNGFileType properties:nil];
        newArtwork.data = (void *) [bitmapData bytes];
        newArtwork.size = (uint32_t) [bitmapData length];
        newArtwork.type = MP4_ART_PNG;
        MP4TagsSetArtwork(tags, 0, &newArtwork);
    }

    success = MP4TagsStore(tags, fileHandle);
    MP4TagsFree(tags);
    if (!success) {
        return NO;
    }

    /* Rewrite extended metadata using the generic iTMF api */
    if (self.cast || self.directors || self.producers || self.screenwriters || self.studio) {

        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        if (self.cast) {
            NSMutableArray *castArray = [NSMutableArray arrayWithCapacity:self.cast.count];
            for (NSString *actor in self.cast) {
                [castArray addObject:[NSDictionary dictionaryWithObject:actor forKey:@"name"]];
            }
            [dict setObject:castArray forKey:@"cast"];
        }
        if (self.directors) {
            NSMutableArray *directorsArray = [NSMutableArray arrayWithCapacity:self.directors.count];
            for (NSString *director in self.directors) {
                [directorsArray addObject:[NSDictionary dictionaryWithObject:director forKey:@"name"]];
            }
            [dict setObject:directorsArray forKey:@"directors"];
        }
        if (self.screenwriters) {
            NSMutableArray *writerArray = [NSMutableArray arrayWithCapacity:self.cast.count];
            for (NSString *writer in self.screenwriters) {
                [writerArray addObject:[NSDictionary dictionaryWithObject:writer forKey:@"name"]];
            }
            [dict setObject:writerArray forKey:@"screenwriters"];
        }
        if (self.producers) {
            NSMutableArray *producerArray = [NSMutableArray arrayWithCapacity:self.producers.count];
            for (NSString *producer in self.producers) {
                [producerArray addObject:[NSDictionary dictionaryWithObject:producer forKey:@"name"]];
            }
            [dict setObject:producerArray forKey:@"producers"];
        }
        if (self.studio) {
            [dict setObject:self.studio forKey:@"studio"];
        }
        if (self.screenFormat) {
            [dict setObject:[NSDictionary dictionaryWithObjectsAndKeys:self.screenFormat, @"screen-format", nil] forKey:@"asset-info"];
        }

        NSData *serializedPlist = [NSPropertyListSerialization
                dataFromPropertyList:dict
                              format:NSPropertyListXMLFormat_v1_0
                    errorDescription:nil];

        MP4ItmfItemList *list = MP4ItmfGetItemsByMeaning(fileHandle, "com.apple.iTunes", "iTunMOVI");
        if (list) {
            uint32_t i;
            for (i = 0; i < list->size; i++) {
                MP4ItmfItem *item = &list->elements[i];
                MP4ItmfRemoveItem(fileHandle, item);
            }
        }
        MP4ItmfItemListFree(list);

        MP4ItmfItem *newItem = MP4ItmfItemAlloc("----", 1);
        newItem->mean = strdup("com.apple.iTunes");
        newItem->name = strdup("iTunMOVI");

        MP4ItmfData *data = &newItem->dataList.elements[0];
        data->typeCode = MP4_ITMF_BT_UTF8;
        data->valueSize = (uint32_t) [serializedPlist length];
        data->value = (uint8_t *) malloc(data->valueSize);
        memcpy( data->value, [serializedPlist bytes], data->valueSize );

        success = MP4ItmfAddItem(fileHandle, newItem);
        if (!success) {
            return NO;
        }
    }

    return YES;
}

- (void)printCurrentTags {

    NSLog(@"name : %@", self.name);
    NSLog(@"comments : %@", self.comments);
    NSLog(@"genre : %@", self.genre);
    NSLog(@"releaseDate : %@", self.releaseDate);
    NSLog(@"shortDescription : %@", self.shortDescription);
    NSLog(@"longDescription : %@", self.longDescription);
    NSLog(@"hd : %c", self.hd);
    NSLog(@"screenFormat : %@", self.screenFormat);
    NSLog(@"type : %u", self.type);
    NSLog(@"artwork : %@", self.artwork);
    NSLog(@"cast : %@", self.cast);
    NSLog(@"directors : %@", self.directors);
    NSLog(@"screenwriters : %@", self.screenwriters);
    NSLog(@"producers : %@", self.producers);
    NSLog(@"studio : %@", self.studio);
}

@end
