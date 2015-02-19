//
//  VVGIFPlayerItem.h
//  GifToSyphon
//
//  Created by David Lublin on 2/10/15.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VVBasics/VVBasics.h>
#import <CoreMedia/CoreMedia.h>
#import "VVGIFFrame.h"



/*

	Wrapper for an NSBitmapImageRep and the GIF reps that it might contain
	Use with a VVGIFPlayer to pull frames

*/




@interface VVGIFPlayerItem : NSObject	{

	BOOL _deleted;

	NSURL *fileURL;
	NSBitmapImageRep *_gifRep;
	MutLockArray *_framesArray;
	CMTime duration;
	CGSize presentationSize;
	
	BOOL cacheAllFrames;
	NSString *_downloadPath;

}

//	create a player from a URL
+ (VVGIFPlayerItem *)playerItemWithURL:(NSURL *)URL;
- (id)initWithURL:(NSURL *)URL;

//	if downloading from a remote URL, use these to specify an optional directory to download the file to
//	the download happens if / when the preroll is successful
+ (VVGIFPlayerItem *)playerItemWithURL:(NSURL *)URL copyToDownloadFolderPath:(NSString *)fp;
- (id)initWithURL:(NSURL *)URL copyToDownloadFolderPath:(NSString *)fp;

//	internal method for loading the timing / caching the frames
//	also downloads the file if on a remote server
//	this method may be called automatically when a player takes control or tries to grab the first frame
- (void)doPreload;
- (void)_preloadFramesFromURL:(NSURL *)URL;
- (void)_preloadFramesFromData:(NSData *)gifData;

//	variables for setting whether or not the player item caches its frames when it preloads
//	changing invalidates any existing preloading
//	most useful when set to YES before attaching to a VVGIFPlayer
//	if set to NO it still may cache frame data during playback
- (BOOL)cacheAllFrames;
- (void)setCacheAllFrames:(BOOL)c;

//	external method used by VVGIFPlayer to pull frames
- (VVGIFFrame *)frameForTime:(CMTime)t;

//	general info about the loaded GIF asset
- (CMTime)duration;
- (NSSize)presentationSize;
- (NSURL *)fileURL;

@end
