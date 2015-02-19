//
//  VVGIFPlayer.h
//  GifToSyphon
//
//  Created by David Lublin on 2/10/15.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VVBasics/VVBasics.h>
#import <CoreMedia/CoreMedia.h>
#import "VVGIFPlayerItem.h"
#import "VVGIFFrame.h"




/*

	Similar to AVPlayer but for GIFs
	-- this object handles the timing related to playback
	-- it reads from a VVGIFPlayerItem that contains the pre-loaded frames for the file
	-- where appropriate returns as you'd expect for a movie

*/


typedef NS_ENUM(NSInteger, VVGIFPlayerEndActionType)	{
	VVGIFPlayerEndActionCutToBlack = 1,
	VVGIFPlayerEndActionHold = 2,
	VVGIFPlayerEndActionLoop = 3,
	VVGIFPlayerEndActionReverse = 4,
	VVGIFPlayerEndActionNext = 5
};



@protocol VVGIFPlayerDelegate
- (void) playerDidReachEnd:(id)p;
@end




@interface VVGIFPlayer : NSObject	{

	//	the time and rate variables for this player
	CMTime currentTime;
	float rate;

	//	the loop points
	CMTime startTime;
	CMTime endTime;
	VVGIFPlayerEndActionType loopMode;
	
	BOOL _reverse;
	BOOL _reachedEnd;

	//	retain the last frame we've read
	VVGIFFrame *_lastReadFrame;
	
	//	measure the time since the last upkeep
	VVStopwatch *_timeSinceLastRead;
	
	//	if the seekTime is not kCMTimeInvalid we'll be jumping to a particular time on the next render
	CMTime seekTime;
	
	//	the player item currently being read from
	VVGIFPlayerItem *playerItem;
	
	//	the delegate for this player
	id delegate;

}

//	methods for creating a new player, either by URL or from an existing GIFPlayerItem
+ (id)playerWithURL:(NSURL *)URL;
- (id)initWithURL:(NSURL *)URL;

+ (id)playerWithGIFPlayerItem:(VVGIFPlayerItem *)item;
- (id)initWithGIFPlayerItem:(VVGIFPlayerItem *)item;

//	rendering methods
- (void)renderUpkeep;
- (BOOL)hasNewFrame;
- (NSBitmapImageRep *)copyCurrentFrameRep;

//	playback time
- (CMTime)currentTime;
- (void)seekToTime:(CMTime)time;

//	start and end times
- (CMTime)startTime;
- (void)setStartTime:(CMTime)time;
- (CMTime)endTime;
- (void)setEndTime:(CMTime)time;

//	loop modes
- (VVGIFPlayerEndActionType)loopMode;
- (void)setLoopMode:(VVGIFPlayerEndActionType)m;

//	playback rate
- (float)rate;
- (void)setRate:(float)r;

//	delegate setup
- (id)delegate;
- (void)setDelegate:(id)d;

//	player properties
- (CMTime)duration;
- (NSSize)presentationSize;

//	while you don't usually need to access this, the player item contains the actual loaded GIF frames
- (VVGIFPlayerItem *)playerItem;
- (void)setPlayerItem:(VVGIFPlayerItem *)item;


@end
