//
//  AppDelegate.m
//  GifToSyphon
//
//  Created by David Lublin on 2/10/15.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate




/*===================================================================================*/
#pragma mark --------------------- Launch / Quit
/*------------------------------------*/


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"%s",__func__);
	//	create the shared context and a buffer pool, set them up
	sharedContext = [[NSOpenGLContext alloc] initWithFormat:[GLScene defaultPixelFormat] shareContext:nil];
	VVBufferPool *bp = [[VVBufferPool alloc] initWithSharedContext:sharedContext pixelFormat:[GLScene defaultPixelFormat] sized:NSMakeSize(640,480)];
	[VVBufferPool setGlobalVVBufferPool:bp];
	[VVBufferCopier createGlobalVVBufferCopierWithSharedContext:sharedContext];

	//	setup the output view with our shared context
	[outputView setSharedGLContext:sharedContext];
	
	//	make a black frame to display
	lastSourceBuffer = [_globalVVBufferPool allocBGRTexSized:NSMakeSize(320,240)];
	[VVBufferCopier class];
	[_globalVVBufferCopier copyBlackFrameToThisBuffer:lastSourceBuffer];
	
	//	make the syphon server
	myServer = [[SyphonServer alloc] initWithName:@"GIFS" context:[sharedContext CGLContextObj] options:nil];
	
	//	start the render thread
	renderThread = [[VVThreadLoop alloc] initWithTimeInterval:1.0/60.0 target:self selector:@selector(_renderCallback)];
	[renderThread start];
	
	//	set the CURL to nil
	_randomCURL = nil;
	
	//	disable app nap
	NSActivityOptions options = NSActivityAutomaticTerminationDisabled | NSActivityBackground;
	appNapThing = [[[NSProcessInfo processInfo] beginActivityWithOptions: options reason:@"GIF PLAYBACK"] retain];
	
	//	do some default behavior, eg trigger random or load the default GIF
	//[self randomButtonUsed:nil];
	NSString *defaultGIFPath = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"gif"];
	if (gifPlayer == nil)	{
		[self openGIFAtPath: defaultGIFPath];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	NSLog(@"%s",__func__);
	//	stop the render thread and turn off the app nap thing
	[renderThread stop];
	[[NSProcessInfo processInfo] endActivity: appNapThing];
}

- (void)dealloc	{
	//	release all the stuff
	VVRELEASE(renderThread);
	VVRELEASE(gifPlayer);
	VVRELEASE(myServer);
	VVRELEASE(lastSourceBuffer);
	VVRELEASE(sharedContext);
	VVRELEASE(_randomCURL);
	[super dealloc];
}


/*===================================================================================*/
#pragma mark --------------------- IBActions
/*------------------------------------*/


- (IBAction)openMenuUsed:(id)sender	{
	[self openDocument:sender];
}

- (IBAction)openURLMenuUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	[openURLTextField setStringValue:@""];
	[openURLPanel makeKeyAndOrderFront:sender];
}

- (IBAction)openURLButtonUsed:(id)sender	{
	//	reset the search field since it isn't part of this
	[searchField setStringValue:@""];
	[self textFieldUsed: openURLTextField];
}

- (IBAction)revealGIFFolderMenuUsed:(id)sender	{
	NSString *gifFolderPath = [GIFToSyphonDownloadsPath stringByExpandingTildeInPath];
	if ([[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:gifFolderPath])	{
		NSLog(@"\t\tdisplaying %@ in the Finder", gifFolderPath);
	}
}

- (IBAction)revealCurrentGIFMenuUsed:(id)sender	{
	NSURL *currentURL = nil;
	@synchronized (self)	{
		if (gifPlayer != nil)	{
			currentURL = [[gifPlayer playerItem] fileURL];
		}
	}

	//	if it's a local file, show it in the finder
	if ([currentURL filePathURL] != nil)	{
		NSString *fileString = [currentURL relativePath];
		NSString *defaultGIFPath = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"gif"];
		NSLog(@"\t\tdisplaying %@ in the Finder", fileString);
		if ([defaultGIFPath isEqualToString: fileString])	{
			NSLog(@"\t\terr can not reveal default file");
		}
		else if ([[NSWorkspace sharedWorkspace] selectFile:fileString inFileViewerRootedAtPath:[fileString stringByDeletingLastPathComponent]])	{
			NSLog(@"\t\tdisplaying %@ in the Finder", fileString);
		}	
	}
	else	{
		if ([[NSWorkspace sharedWorkspace] openURL: currentURL])	{
			NSLog(@"\t\topening current URL %@",currentURL);
		}
	}
}

- (IBAction)loadDefaultGIFMenuUsed:(id)sender	{
	NSString *defaultGIFPath = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"gif"];
	[searchField setStringValue:@""];
	[self openGIFAtPath: defaultGIFPath];
}

- (IBAction)timeSliderUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	@synchronized (self)	{
		if (gifPlayer != nil)	{
			CMTime duration = [gifPlayer duration];
			CMTime newTime = CMTimeMakeWithSeconds([sender floatValue] * CMTimeGetSeconds(duration), 600);
			[gifPlayer seekToTime: newTime];
		}
	}
}

- (IBAction)rateSliderUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	@synchronized (self)	{
		if (gifPlayer != nil)
			[gifPlayer setRate:[sender floatValue]];
        [rateTimeField setStringValue:[NSString stringWithFormat:@"%.1f",[sender floatValue]]];
	}
}

- (IBAction)loopModeUsed:(id)sender	{
	@synchronized (self)	{
		//	set the loop mode- skip the cut to black option in here
		if (gifPlayer != nil)	{
			[gifPlayer setLoopMode:[sender selectedSegment] + 2];
		}
	}
}

- (IBAction)textFieldUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	NSURL *URL = nil;
	@synchronized (self)	{
		if (sender == rateTimeField)	{
			if (gifPlayer != nil)
				[gifPlayer setRate:[sender floatValue]];
			[rateSlider setFloatValue: [sender floatValue]];
		}
		else if (sender == startTimeField)	{
			CMTime newStartTime = CMTimeMakeWithSeconds([sender floatValue], 600);
			if (gifPlayer != nil)	{
				[gifPlayer setStartTime: newStartTime];
			}
		}
		else if (sender == endTimeField)	{
			CMTime newEndTime = CMTimeMakeWithSeconds([sender floatValue], 600);
			if (gifPlayer != nil)	{
				[gifPlayer setEndTime: newEndTime];
			}
		}
		else if (sender == currentTimeField)	{
			if (gifPlayer != nil)	{
				CMTime newTime = CMTimeMakeWithSeconds([sender floatValue], 600);
				[gifPlayer seekToTime: newTime];
			}
		}
		else if (sender == openURLTextField)	{
			URL = [NSURL URLWithString:[openURLTextField stringValue]];
			[openURLPanel orderOut: nil];
		}
	}
	
	if (URL)	{
		[self openGIFAtURL: URL];
	}
}

- (IBAction)randomButtonUsed:(id)sender	{
	NSString *adjustedSearchString = [[searchField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	[self _randomFromDownloadFolderForTerm:adjustedSearchString];
}

- (IBAction)randomFromGiphyButtonUsed:(id)sender	{
	NSString *tmpString = [searchField stringValue];
	[NSThread detachNewThreadSelector:@selector(_startRandomDownloadForTerm:) toTarget:self withObject:tmpString];
}


/*===================================================================================*/
#pragma mark --------------------- Loading and playing GIFs
/*------------------------------------*/


- (void) openDocument:(id)sender	{
	//NSLog(@"%s ... %@",__func__,sender);
	NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	NSString *openPanelDir = [def objectForKey:@"openPanelDir"];
	if (openPanelDir==nil)
		openPanelDir = [@"~/" stringByExpandingTildeInPath];
	[openPanel setDirectoryURL:[NSURL fileURLWithPath:openPanelDir]];
	[openPanel setAllowedFileTypes:OBJARRAY(@"gif")];
	[openPanel
		beginSheetModalForWindow:window
		completionHandler:^(NSInteger result)	{
			NSString *path = (result!=NSFileHandlingPanelOKButton) ? nil : [[openPanel URL] path];
			if (path != nil)	{
				NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
				[def setObject:[path stringByDeletingLastPathComponent] forKey:@"openPanelDir"];
				[def synchronize];
			}
			if ([openPanel URL])	{
				[self openGIFAtURL:[openPanel URL]];
				[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[openPanel URL]];
			}
			[openPanel release];
		}];
}

- (BOOL)openGIFAtURL:(NSURL *)URL	{
	NSLog(@"%s - %@",__func__,URL);
	BOOL returnMe = NO;
	
	NSString *adjustedSearchString = [[searchField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	NSArray *pathComponents = [[URL path] pathComponents];
	long componentsCount = [pathComponents count];
	NSString *newFileName = nil;
	if (componentsCount > 2)	{
		newFileName = [NSString stringWithFormat:@"%@%@",[pathComponents objectAtIndex:componentsCount-2],[pathComponents objectAtIndex:componentsCount-1]];
	}
	else if (componentsCount > 1)	{
		newFileName = [pathComponents objectAtIndex:componentsCount-1];
	}
	else	{
		newFileName = @"";
	}
	NSString *gifFilePath = [NSString stringWithFormat:@"%@/%@-%@",[GIFToSyphonDownloadsPath stringByExpandingTildeInPath],adjustedSearchString,newFileName];
	
	VVGIFPlayerItem *newGifPlayerItem = [[VVGIFPlayerItem alloc] initWithURL:URL copyToDownloadFolderPath: gifFilePath];
	VVGIFPlayer *newGifPlayer = nil;
	if (newGifPlayerItem)	{
		[newGifPlayerItem doPreload];
		newGifPlayer = [VVGIFPlayer playerWithGIFPlayerItem: newGifPlayerItem];
		[newGifPlayerItem release];
	}
	
	@synchronized (self)	{
		VVAUTORELEASE(gifPlayer);
		if (newGifPlayer != nil)	{
			gifPlayer = [newGifPlayer retain];
			[gifPlayer setDelegate: self];
			[gifPlayer setRate: 1.0];
			[rateSlider setFloatValue:1.0];
			[timeSlider setFloatValue:0.0];
			[rateTimeField setStringValue:[NSString stringWithFormat:@"%.1f",[rateSlider floatValue]]];
			[startTimeField setStringValue:[NSString stringWithFormat:@"%.1f",CMTimeGetSeconds([gifPlayer startTime])]];
			[endTimeField setStringValue:[NSString stringWithFormat:@"%.1f",CMTimeGetSeconds([gifPlayer endTime])]];
			returnMe = YES;
		}
	}
	
	[self loopModeUsed: loopModeButton];
	
	timeSliderRedraws = 0;
	
	return returnMe;
}

- (BOOL)openGIFAtPath:(NSString *)path	{
	NSURL *URL = [NSURL fileURLWithPath:path];
	return [self openGIFAtURL:URL];
}

- (BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename	{
	NSURL *URL = [NSURL fileURLWithPath:filename];
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:URL];
	return [self openGIFAtURL:URL];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename	{
	return [self openGIFAtPath:filename];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames	{
	if ([filenames count] == 0)
		return;
	NSURL *URL = [NSURL fileURLWithPath:[filenames objectAtIndex:0]];
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:URL];
	[self openGIFAtURL:URL];
}


/*===================================================================================*/
#pragma mark --------------------- Downloading GIFs
/*------------------------------------*/


- (void)_startRandomDownloadForTerm:(NSString *)term	{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL useLocalFallback = YES;
	NSString *searchAddress = nil;
	
	//	note that this the public / demo API key!
	//	replace this with your own in production code if you don't want rate limits
	
	//	note that the term can be nil, just do a search all
	if ((term == nil) || ([term length] < 1))	{
		searchAddress = [NSString stringWithFormat:@"https://api.giphy.com/v1/gifs/random?api_key=%@",GIFToSyphonGiphyAPIKey];
	}
	else	{
		NSString *adjustedSearchString = [term stringByReplacingOccurrencesOfString:@" " withString:@"+"];
		//NSLog(@"\t\tsearch term: %@",adjustedSearchString);
		searchAddress = [NSString stringWithFormat:@"https://api.giphy.com/v1/gifs/random?api_key=%@&tag=%@",GIFToSyphonGiphyAPIKey,adjustedSearchString];
	}
	
	//NSLog(@"\t\tsearch address: %@",searchAddress);
	@synchronized (self)	{
		VVRELEASE(_randomCURL);
		_randomCURL = [VVCURLDL createWithAddress:searchAddress];
		if (_randomCURL != nil)	{
			[_randomCURL retain];
			[_randomCURL performAsync:YES withDelegate:self];
		}
		else if (useLocalFallback)	{
			[self _randomFromDownloadFolderForTerm:term];
		}
	}

	[pool release];
}

- (void)_randomFromDownloadFolderForTerm:(NSString *)term	{
	//	note that currently the term option is not supported on this call!
	NSString *gifFolderPath = [GIFToSyphonDownloadsPath stringByExpandingTildeInPath];
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:gifFolderPath error:nil];
	if (files == nil)
		return;
	//	filter out just the GIFs then pick one randomly
	NSArray *searchTerms = [NSArray array];
	if (term != nil)	{
		searchTerms = [term componentsSeparatedByString:@"+"];
		if ([searchTerms count] == 0)	{
			searchTerms = [term componentsSeparatedByString:@" "];
		}
	}
	//NSLog(@"\t\tterm: %@",searchTerms);
	NSMutableArray *gifFiles = [NSMutableArray arrayWithCapacity:0];
	NSMutableArray *gifFilesMatchingTerms = [NSMutableArray arrayWithCapacity:0];
	for (NSString *fileName in files)	{
		if ([[fileName pathExtension] isEqualToString:@"gif"])	{
			[gifFiles addObject:fileName];
			int matchCount = 0;
			for (NSString *subTerm in searchTerms)	{
				NSRange subRange = [fileName rangeOfString: subTerm];
				if (subRange.length != 0)	{
					++matchCount;
				}
			}
			if (matchCount == [searchTerms count])	{
				[gifFilesMatchingTerms addObject:fileName];
			}
		}
	}
	//NSLog(@"\t\t%@",gifFiles);
	if ([gifFilesMatchingTerms count] > 0)	{
		double rand = [gifFilesMatchingTerms count] * ((double)random()/(RAND_MAX));
		if (rand > [gifFiles count] - 1)	{
			rand = [gifFiles count] - 1;
		}
		NSString *filePath = [NSString stringWithFormat:@"%@/%@",gifFolderPath,[gifFilesMatchingTerms objectAtIndex:rand]];
		NSURL *URL = [NSURL fileURLWithPath: filePath];
		[self openGIFAtURL: URL];
	}
	else	{
		double rand = [gifFiles count] * ((double)random()/(RAND_MAX));
		if (rand > [gifFiles count] - 1)	{
			rand = [gifFiles count] - 1;
		}
		NSString *filePath = [NSString stringWithFormat:@"%@/%@",gifFolderPath,[gifFiles objectAtIndex:rand]];
		NSURL *URL = [NSURL fileURLWithPath: filePath];
		[self openGIFAtURL: URL];	
	}
}

- (void) dlFinished:(id)h	{
	NSURL *URL = nil;
	BOOL randomFailed = NO;
	NSString *responseString = nil;
	@synchronized (self)	{
		if (h == _randomCURL)	{
			randomFailed = YES;
			NSData *jsonData = [_randomCURL responseData];
			responseString = [_randomCURL responseString];
			if (responseString == nil)	{
				responseString = @"No response";
			}
			if (jsonData)	{
				id jsonObject = [jsonData objectFromJSONData];
				if ([jsonObject isKindOfClass:[NSDictionary class]])	{
					//NSLog(@"\t\t\t%@",jsonObject);
					NSDictionary *jsonDataDict = [jsonObject objectForKey:@"data"];
					if ((jsonDataDict != nil) && ([jsonDataDict isKindOfClass:[NSDictionary class]]))	{
						NSString *originalAddress = [jsonDataDict objectForKey:@"image_original_url"];
						//NSLog(@"\t\t\tabout to download from %@",originalAddress);
						URL = [NSURL URLWithString:originalAddress];
						randomFailed = NO;
					}
				}
			}
		}
	}
	
	if (URL != nil)	{
		[self performSelectorOnMainThread:@selector(openGIFAtURL:) withObject:URL waitUntilDone:NO];
	}
	else if (randomFailed) {
		if (responseString != nil)	{
			NSLog(@"\t\tfailed random CURL with response - %@",responseString);
		}
		[self performSelectorOnMainThread:@selector(randomButtonUsed:) withObject:URL waitUntilDone:NO];
	}
}


/*===================================================================================*/
#pragma mark --------------------- Rendering
/*------------------------------------*/


- (void)_renderCallback	{
	//NSLog(@"%s",__func__);
	//	get a frame from from the gifPlayer
	VVBuffer *tmpBuffer = nil;
	float newTime = -1.0;
	float newTimeNormalized = -1.0;
	
	//	check to see if there is a GIF player and if it has a new frame get it
	@synchronized (self)	{
		OSSpinLockLock(&lastSourceBufferLock);
			if (gifPlayer!=nil)	{
				if ([gifPlayer hasNewFrame])	{
					//NSLog(@"\t\tnew frame!");
					NSBitmapImageRep *tmpRep = [gifPlayer copyCurrentFrameRep];
					if (tmpRep != nil)	{
						tmpBuffer = [_globalVVBufferPool allocBufferForBitmapRep:tmpRep];
						[tmpBuffer setFlipped:YES];
						[tmpRep release];
						VVRELEASE(lastSourceBuffer);
						lastSourceBuffer = [tmpBuffer retain];
					}
				}
				float durationInSeconds = CMTimeGetSeconds([gifPlayer duration]);
				if (durationInSeconds > 0.0)	{
					newTime = CMTimeGetSeconds([gifPlayer currentTime]);
					newTimeNormalized = newTime / durationInSeconds;
				}
				[gifPlayer renderUpkeep];
			}
		OSSpinLockUnlock(&lastSourceBufferLock);
	}
	
	if (tmpBuffer != nil)	{
		//	set the frame to display + publish to syphon
		[outputView drawBuffer:tmpBuffer];
		[myServer publishFrameTexture:[tmpBuffer name]
				textureTarget:[tmpBuffer target]
				imageRegion:[tmpBuffer srcRect]
				textureDimensions:[tmpBuffer srcRect].size
				flipped:[tmpBuffer flipped]];
		VVRELEASE(tmpBuffer);
	}

	//	if there was a new time value update the time slider on the main thread
	if (newTime != -1.0)	{
		++timeSliderRedraws;
		if ([window isVisible])	{
			if (timeSliderRedraws >= 8)	{
				if (lastReadTimeInSeconds != newTime)	{
					[self _updateTime];
					lastReadTimeInSeconds = newTime;
				}
			}
		}		
	}
	
	[_globalVVBufferPool housekeeping];
}

- (void)_updateTime	{
	float newTime = -1.0;
	float newTimeNormalized = -1.0;
	
	//	get the time from the GIF player and then display it if the window is visible
	@synchronized (self)	{
		if (gifPlayer!=nil)	{
			float durationInSeconds = CMTimeGetSeconds([gifPlayer duration]);
			if (durationInSeconds > 0.0)	{
				newTime = CMTimeGetSeconds([gifPlayer currentTime]);
				newTimeNormalized = newTime / durationInSeconds;
			}
		}
	}
	
	if (newTime != -1.0)	{
		if ([window isVisible])	{
			[timeSlider setFloatValue: newTimeNormalized];
			[currentTimeField setStringValue: [NSString stringWithFormat:@"%.1f",newTime]];
		}		
	}
	
	timeSliderRedraws = 0;
}

- (void)playerDidReachEnd:(id)p	{
	//NSLog(@"%s",__func__);
	if (p == nil)
		return;
	if ([p loopMode] == VVGIFPlayerEndActionNext)	{
		NSString *gifFolderPath = [GIFToSyphonDownloadsPath stringByExpandingTildeInPath];
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:gifFolderPath error:nil];
		NSUInteger filesCount = [files count];
		double rand = ((double)random()/(RAND_MAX));
		//	change these lines to switch between random from giphy or random from local collection
		//	note that random from giphy + downloading = full hard drive which is why this is set up the way it is
		//	as the number of files in the download directory goes up the chances of getting a new image from giphy goes down
		if (rand < 25.0 / (float)filesCount)	{
			[self performSelectorOnMainThread:@selector(randomFromGiphyButtonUsed:) withObject:nil waitUntilDone:NO];
		}
		else	{
			[self performSelectorOnMainThread:@selector(randomButtonUsed:) withObject:nil waitUntilDone:NO];
		}
	}
}


@end
