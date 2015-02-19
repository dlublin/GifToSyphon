//
//  VVGIFPlayerItem.m
//  GifToSyphon
//
//  Created by David Lublin on 2/10/15.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import "VVGIFPlayerItem.h"

@implementation VVGIFPlayerItem

+ (VVGIFPlayerItem *)playerItemWithURL:(NSURL *)URL	{
	VVGIFPlayerItem *returnMe = [[VVGIFPlayerItem alloc] initWithURL:URL];
	if (returnMe != nil)
		[returnMe autorelease];
	return returnMe;
}

- (id)initWithURL:(NSURL *)URL	{
	//NSLog(@"%s",__func__);
	if (URL == nil)	{
		[self release];
		return nil;
	}
	if (self = [super init])	{
		fileURL = [URL retain];
		_gifRep = nil;
		_downloadPath = nil;
		cacheAllFrames = NO;
		_deleted = NO;
		[self _preloadFramesFromURL:URL];
		return self;
	}
	[self release];
	return nil;
}

+ (VVGIFPlayerItem *)playerItemWithURL:(NSURL *)URL copyToDownloadFolderPath:(NSString *)fp	{
	VVGIFPlayerItem *returnMe = [[VVGIFPlayerItem alloc] initWithURL:URL copyToDownloadFolderPath:fp];
	if (returnMe != nil)
		[returnMe autorelease];
	return returnMe;
}

- (id)initWithURL:(NSURL *)URL copyToDownloadFolderPath:(NSString *)fp	{
	//NSLog(@"%s",__func__);
	if (URL == nil)	{
		[self release];
		return nil;
	}
	if (self = [super init])	{
		fileURL = [URL retain];
		_gifRep = nil;
		_downloadPath = nil;
		cacheAllFrames = NO;
		_deleted = NO;
		if (fp != nil)	{
			_downloadPath = [fp copy];
		}
		else	{
			[self _preloadFramesFromURL:URL];
		}
		
		return self;
	}
	[self release];
	return nil;
}

- (void)dealloc	{
	//NSLog(@"%s",__func__);
	_deleted = YES;
	if (_framesArray != nil)	{
		[_framesArray lockRemoveAllObjects];
	}
	VVRELEASE(fileURL);
	VVRELEASE(_framesArray);
	VVRELEASE(_gifRep);
	VVRELEASE(_downloadPath);
	[super dealloc];
}

- (void)doPreload	{
	if (_deleted)
		return;
	if (fileURL == nil)
		return;
	[self _preloadFramesFromURL: fileURL];
}

//	this is where most of the action happens as far as extracting GIF frames
- (void)_preloadFramesFromURL:(NSURL *)URL	{
	if (_deleted)
		return;
	//NSLog(@"%s",__func__);
	// if the URL is nil return
	if (URL == nil)
		return;
	//	load the gif data, return if needed
	NSData *gData = [NSData dataWithContentsOfURL:URL];
	if (gData == nil)
		return;
	//	call the method to preload the frames from this gif data
	//[self _preloadFramesFromData: gData];
	[self performSelectorOnMainThread:@selector(_preloadFramesFromData:) withObject:gData waitUntilDone:YES];
}

- (void)_preloadFramesFromData:(NSData *)gifData	{
	//	bail immediately if no gif data
	if (gifData == nil)
		return;
	
	//NSLog(@"%s",__func__);
	//	create the frames array if needed
	if (_framesArray == nil)	{
		_framesArray = [[MutLockArray arrayWithCapacity:0] retain];
	}
	//	if we've already got the frames, bail!
	if ([_framesArray lockCount] > 0)	{
		return;	
	}
	//	first reset the time and remove all the old frames
	VVRELEASE(_gifRep);
	[_framesArray lockRemoveAllObjects];
	duration = CMTimeMakeWithSeconds(0.0, 600);
	
	//	make the bitmapimagerep, return if needed
	_gifRep = [NSBitmapImageRep imageRepWithData: gifData];
	if (_gifRep == nil)
		return;
	[_gifRep retain];
	
	presentationSize = [_gifRep size];
	
	NSNumber *tmpNum = nil;
	
	//	figure out the frame count
	int	frameCount = 0;
	
	tmpNum = [_gifRep valueForProperty:@"NSImageFrameCount"];
	if (tmpNum != nil)
		frameCount = [tmpNum intValue];
	//	if there are no frames, return
	if (frameCount == 0)
		return;
	//NSLog(@"\t\tabout to load %d frames for GIF", frameCount);
	
	//	now read each frame out as a bitmap image and put it in the array
	for(int i=0; i<frameCount; i++ ){
		//	advance to the specified frame #
		[_gifRep setProperty:NSImageCurrentFrame withValue:[NSNumber numberWithUnsignedInt:i]];
		//	figure out how long long this frame is supposed to play for
		tmpNum = [_gifRep valueForProperty:NSImageCurrentFrameDuration];
		CMTime frameDuration = CMTimeMakeWithSeconds([tmpNum doubleValue], 600);
		CMTimeRange newRange = CMTimeRangeMake(duration, frameDuration);

		NSBitmapImageRep *frameRep = nil;
	
		//	if we're preloading the frames, make a copy that gets stored here
		//	otherwise only preload the first frame and the frames will get pulled on the fly
		if ((cacheAllFrames)||(i==0))	{
			NSData *repData = [_gifRep representationUsingType:NSGIFFileType properties:nil];
			frameRep = [NSBitmapImageRep imageRepWithData:repData];
		}
		VVGIFFrame *tmpFrame = [[VVGIFFrame alloc] initWithImageRep:frameRep forTimeRange:newRange];
		[_framesArray lockAddObject: tmpFrame];
		[tmpFrame release];
	
		//	now update the running duration
		duration = CMTimeAdd(duration, frameDuration);
	}
	
	//	writing remote GIF to disk for future reference
	if (([fileURL filePathURL] == nil) && (_downloadPath != nil))	{
		NSFileManager *fileManager = [NSFileManager defaultManager];

		if ([fileManager fileExistsAtPath: [_downloadPath stringByDeletingLastPathComponent]] == NO)	{
			[fileManager createDirectoryAtPath: [_downloadPath stringByDeletingLastPathComponent] withIntermediateDirectories: YES attributes: nil error: nil];
			NSLog(@"\t\tcreating folder for %@", _downloadPath);
		}
		if ([fileManager fileExistsAtPath: _downloadPath] == NO)	{
			//NSLog(@"\t\twriting GIF to disk %@", _downloadPath);
			[gifData writeToFile: _downloadPath atomically: YES];
			//NSLog(@"\t\twrote GIF to disk %@", _downloadPath);
		}
	}
	//NSLog(@"\t\tgif duration: %f", CMTimeGetSeconds(duration));
}

- (BOOL)cacheAllFrames	{
	return cacheAllFrames;
}

- (void)setCacheAllFrames:(BOOL)c	{
	if (_deleted)
		return;
	//	if the state of this changes clear out any old frames that are loaded
	if (cacheAllFrames != c)	{
		cacheAllFrames = c;
		[_framesArray lockRemoveAllObjects];
		VVRELEASE(_framesArray);
	}
}

- (VVGIFFrame *)frameForTime:(CMTime)t	{
	if (_deleted)
		return nil;

	VVGIFFrame *returnMe = nil;
	
	if (_framesArray == nil)	{
		[self doPreload];
	}
	
    long frameIndex = 0;
    
	[_framesArray rdlock];
	
		//	if we're in the first half of the GIF start reading from the beginning
		if (CMTimeGetSeconds(t) < (CMTimeGetSeconds(duration) / 2.0))	{
			for (VVGIFFrame *gFrame in [_framesArray objectEnumerator])	{
				if (CMTimeRangeContainsTime([gFrame timeRange], t))	{
					returnMe = gFrame;
					break;
				}
				++frameIndex;
			}
		}
		//	otherwise go backwards through it to find the desired frame
		else	{
            frameIndex = [_framesArray count] - 1;
			for (VVGIFFrame *gFrame in [_framesArray reverseObjectEnumerator])	{
				if (CMTimeRangeContainsTime([gFrame timeRange], t))	{
					returnMe = gFrame;
					break;
				}
				--frameIndex;
			}
		}
	
	[_framesArray unlock];
	
	//	if this frame has a nil image rep because we didn't preload we'll actually want to load it up now
	//	attach it to the returned frame and it'll be cached for the next loop
	if ((returnMe != nil)&&([returnMe imageRep] == nil)&&(_gifRep != nil))	{
		[_gifRep setProperty:NSImageCurrentFrame withValue:[NSNumber numberWithLong:frameIndex]];
		NSData *repData = [_gifRep representationUsingType:NSGIFFileType properties:nil];
		NSBitmapImageRep *frameRep = [NSBitmapImageRep imageRepWithData:repData];
		[returnMe setImageRep:frameRep];
	}
	
	return returnMe;
}

- (CMTime)duration	{
	return duration;
}

- (NSSize)presentationSize	{
	return presentationSize;
}

- (NSURL *)fileURL	{
	if (_deleted)
		return nil;
	return fileURL;
}

@end
