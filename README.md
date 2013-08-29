# MP4v2 Cocoa Framework

This cocoa framework allows you to manipulate MP4 files. It's basically a wrapper arround the MP4v2 C/C++ library available at https://code.google.com/p/mp4v2/

Right now it only allows you to perform metadata manipulation but subtitle and audio track management is on the roadmap.

## MP4 File Initialization

    
	NSError *error;
	MP4File *file = [[MP4File alloc] initWithFilePath:@"/path/to/your/file.mp4" outError:&error];
	

## Metadata Modification

    
	file.metadata.name = @"Iron Man";
	file.metadata.genre = @"Action & Adventure";
	file.metadata.releaseDate = @"2008";
	file.metadata.comments = @"When wealthy industrialist Tony Stark is forced to build an armored suit after a life-threatening incident, he ultimately decides to use its technology to fight against evil.";
	file.metadata.shortDescription = @"When wealthy industrialist Tony Stark is forced to build an armored suit after a life-threatening incident, he ultimately decides to use its technology to fight against evil.";
	file.metadata.longDescription = @"Tony Stark is the complete playboy who also happens to be an engineering genius. While in Afghanistan demonstrating a new missile, he's captured and wounded. His captors want him to assemble a missile for them but instead he creates an armored suit and a means to prevent his death from the shrapnel left in his chest by the attack. He uses the armored suit to escape. Back in the U.S. he announces his company will cease making weapons and he begins work on an updated armored suit only to find that Obadiah Stane, his second in command at Stark industries has been selling Stark weapons to the insurgents. He uses his new suit to return to Afghanistan to destroy the arms and then to stop Stane from misusing his research.";
	file.metadata.hd = YES;
	file.metadata.type = MP4MediaTypeMovie; // MP4MediaTypeTvShow also available
	file.metadata.contentRating = @"mpaa|NC-17|500|" // Could also be one of these : @"mpaa|NR|000|", @"mpaa|G|100|", @"mpaa|PG|200|", @"mpaa|PG-13|300|", @"mpaa|R|400|", @"mpaa|Unrated|???|""
	file.metadata.artwork = @"http://ia.media-imdb.com/images/M/MV5BMTczNTI2ODUwOF5BMl5BanBnXkFtZTcwMTU0NTIzMw@@._V1_SX214_.jpg";
	file.metadata.studio = @"Marvel";
	file.metadata.screenFormat = @"widescreen";
	file.metadata.cast = [NSArray arrayWithObjects:@"Robert Downey Jr.", @"Gwyneth Paltrow", @"Jeff Bridges", @"Terrence Howard", nil];
	file.metadata.directors = [NSArray arrayWithObjects:@"Jon Favreau", nil];
	file.metadata.screenwriters = [NSArray arrayWithObjects:@"Art Marcum", @"Matt Holloway", nil];
	file.metadata.producers = [NSArray arrayWithObjects:@"Avi Arad", @"Kevin Feige", nil];
	

## Save Modification

Basically :

    
	NSError *error;
	[file save:&error];
		

Persisting your modifications can take a while. Thus, I suggest you do it in a background thread. Using Grand Central Dispatch, it could look like this : 

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		NSError *error;
		[file save:&error];
		
        dispatch_async(dispatch_get_main_queue(), ^{
			
			if (error != nil) {
            	[_textField setStringValue:@"An Error Occured"];
		    } else {
		        [_textField setStringValue:@"Success!"];
		    }
		});
	});

The MP4File object has a "delegate" attribute of type MP4FileDelegate. Implementing that protocol will allow you to track the progress of the saving process. Supposing "self" implements the MP4FileDelegate protocol.

    
    file.delegate = self;
		

Then, for example, we can update an NSProgressIndicator element on the main thread.

    
	
	- (void)progressChanged:(double)newProgress {
	
		dispatch_async(dispatch_get_main_queue(), ^{
	        [_progressIndicator setDoubleValue:newProgress];
	    });
	}
	

