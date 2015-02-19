//
//  AppDelegate.h
//  GifToSyphon
//
//  Created by David Lublin on 2/10/15.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreMedia/CoreMedia.h>
#import <VVBasics/VVBasics.h>
#import <VVBufferPool/VVBufferPool.h>
#import <Syphon/Syphon.h>
#import <JSONKit/JSONKit.h>
#import "VVGIFPlayer.h"




/*

	This is a test app for making something that is like AVPlayer / AVPlayerItem but for animated gifs
	The idea being we can use this in place of those objects when we've got an animated gif

	For the purposes of making something FUN and USEFUL as a test app, this one is set up to...
	1. Search the web and/or it's fixed local collection for animated gifs based on a provided term
	2. Provide controls for adjusting the current time and rate of the gif playback
	3. Publish the result to a Syphon output

*/




//	set the directory to download cached files
#define GIFToSyphonDownloadsPath @"~/Pictures/GifToSyphon Downloads/"

//	note- this is the public API key, replace with your own in production code
//	especially if you don't want rate limits
#define GIFToSyphonGiphyAPIKey @"dc6zaTOxFJmzC"




@interface AppDelegate : NSObject <NSApplicationDelegate, VVCURLDLDelegate, VVGIFPlayerDelegate>   {

	//	thing to disable app nap
	id	appNapThing;
	
	//	the GIF player object
	VVGIFPlayer *gifPlayer;

	//	Rendering Engine
	NSOpenGLContext				*sharedContext;
	VVThreadLoop				*renderThread;
	OSSpinLock					lastSourceBufferLock;
	VVBuffer					*lastSourceBuffer;
	SyphonServer 				*myServer;

	VVCURLDL 					*_randomCURL;

	//	interface stuff
	IBOutlet NSSlider			*timeSlider;
	IBOutlet NSSlider			*rateSlider;
	IBOutlet NSSegmentedControl	*loopModeButton;

	IBOutlet NSSearchField		*searchField;
	IBOutlet NSTextField		*openURLTextField;

	IBOutlet NSTextField		*startTimeField;
	IBOutlet NSTextField		*endTimeField;
	IBOutlet NSTextField		*currentTimeField;
	IBOutlet NSTextField		*rateTimeField;
	IBOutlet VVBufferGLView		*outputView;
	
	IBOutlet NSWindow *window;
	IBOutlet NSPanel *openURLPanel;

	int timeSliderRedraws;
	float lastReadTimeInSeconds;
	
}

- (IBAction)openMenuUsed:(id)sender;
- (IBAction)openURLMenuUsed:(id)sender;
- (IBAction)openURLButtonUsed:(id)sender;
- (IBAction)revealGIFFolderMenuUsed:(id)sender;
- (IBAction)revealCurrentGIFMenuUsed:(id)sender;
- (IBAction)loadDefaultGIFMenuUsed:(id)sender;

- (IBAction)timeSliderUsed:(id)sender;
- (IBAction)rateSliderUsed:(id)sender;
- (IBAction)loopModeUsed:(id)sender;

- (IBAction)textFieldUsed:(id)sender;

- (IBAction)randomButtonUsed:(id)sender;
- (IBAction)randomFromGiphyButtonUsed:(id)sender;

- (BOOL)openGIFAtURL:(NSURL *)URL;
- (BOOL)openGIFAtPath:(NSString *)path;

- (void)_startRandomDownloadForTerm:(NSString *)term;
- (void)_randomFromDownloadFolderForTerm:(NSString *)term;
- (void)_renderCallback;
- (void)_updateTime;

@end

