//
//  VVGIFPlayer.m
//  GifToSyphon
//
//  Created by David Lublin on 2/10/15.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import "VVGIFPlayer.h"


@implementation VVGIFPlayer


+ (id)playerWithURL:(NSURL *)URL	{
	VVGIFPlayer *returnMe = [[VVGIFPlayer alloc] initWithURL:URL];
	if (returnMe != nil)
		[returnMe autorelease];
	return returnMe;
}
- (id)initWithURL:(NSURL *)URL	{
	if (self = [super init])	{
		playerItem = nil;
		[self setPlayerItem:[VVGIFPlayerItem playerItemWithURL:URL]];
		_timeSinceLastRead = [[VVStopwatch alloc] init];
		currentTime = CMTimeMakeWithSeconds(0.0,600);
		return self;
	}
	[self release];
	return nil;
}

+ (id)playerWithGIFPlayerItem:(VVGIFPlayerItem *)item	{
	VVGIFPlayer *returnMe = [[VVGIFPlayer alloc] initWithGIFPlayerItem:item];
	if (returnMe != nil)
		[returnMe autorelease];
	return returnMe;
}

- (id)initWithGIFPlayerItem:(VVGIFPlayerItem *)item	{
	if (self = [super init])	{
		playerItem = nil;
		[self setPlayerItem:item];
		_timeSinceLastRead = [[VVStopwatch alloc] init];
		currentTime = CMTimeMakeWithSeconds(0.0,600);
		return self;
	}
	[self release];
	return nil;
}

- (void)dealloc	{
	//NSLog(@"%s",__func__);
	VVRELEASE(playerItem);
	VVRELEASE(_timeSinceLastRead);
	VVRELEASE(_lastReadFrame);
	[super dealloc];
}

- (void)renderUpkeep	{
	//NSLog(@"\t\told time is %f",CMTimeGetSeconds(currentTime));
	//	if we're seeking to a time, do so now
	BOOL	didReachEnd = NO;
	BOOL	didReachStart = NO;
	float	localRate = rate;
	
	if (_reverse)	{
		localRate = localRate * -1.0;
	}
	
	//	seek if needed and reset the reached end flag
	if (CMTIME_IS_VALID(seekTime))	{
		currentTime = seekTime;
		seekTime = kCMTimeInvalid;
		_reachedEnd = NO;
	}
	//	otherwise advance as needed
	else	{
		CMTime timeSinceLastUpkeep = CMTimeMakeWithSeconds([_timeSinceLastRead timeSinceStart] * localRate, 600);
		currentTime = CMTimeAdd(currentTime, timeSinceLastUpkeep);
	}

	//	compare the new current time to the end and start times to see if we need to do a loop action
	if ((localRate > 0.) && (CMTimeCompare(currentTime, endTime) != -1))	{
		//NSLog(@"\t\treached end of movie");
		didReachEnd = YES;
	}
	else if ((localRate < 0.) && (CMTimeCompare(currentTime, startTime) != 1))	{
		//NSLog(@"\t\treached start of movie");
		didReachStart = YES;
	}
	
	//	now handle looping if needed
	double startTimeInSeconds = CMTimeGetSeconds(startTime);
	double durationInSeconds = CMTimeGetSeconds(endTime) - startTimeInSeconds;
	double loopedTime = CMTimeGetSeconds(currentTime);

	if (didReachEnd)	{
		switch(loopMode)	{
			case VVGIFPlayerEndActionHold:
			case VVGIFPlayerEndActionCutToBlack:
			case VVGIFPlayerEndActionNext:
				loopedTime = CMTimeGetSeconds(endTime);
				break;
			case VVGIFPlayerEndActionLoop:
				loopedTime = CMTimeGetSeconds(currentTime) - startTimeInSeconds;
				if (durationInSeconds > 0.0)	{
					loopedTime = startTimeInSeconds + loopedTime - durationInSeconds * floor(loopedTime / durationInSeconds);
				}
				else	{
					loopedTime = startTimeInSeconds;
				}
				break;
			case VVGIFPlayerEndActionReverse:
				loopedTime = CMTimeGetSeconds(endTime);
				if (_reverse)
					_reverse = NO;
				else
					_reverse = YES;
				break;
		}
	}
	else if (didReachStart)	{
		switch(loopMode)	{
			case VVGIFPlayerEndActionHold:
			case VVGIFPlayerEndActionCutToBlack:
			case VVGIFPlayerEndActionNext:
				loopedTime = CMTimeGetSeconds(startTime);
				break;
			case VVGIFPlayerEndActionLoop:
				loopedTime = CMTimeGetSeconds(currentTime) - startTimeInSeconds;
				if (durationInSeconds > 0.0)	{
					loopedTime = startTimeInSeconds + loopedTime - durationInSeconds * floor(loopedTime / durationInSeconds);
				}
				else	{
					loopedTime = startTimeInSeconds;
				}
				break;
			case VVGIFPlayerEndActionReverse:
				loopedTime = CMTimeGetSeconds(startTime);
				if (_reverse)
					_reverse = NO;
				else
					_reverse = YES;
				break;
		}	
	}

	currentTime = CMTimeMakeWithSeconds(loopedTime, 600);
	//NSLog(@"\t\tnew time is %f",CMTimeGetSeconds(currentTime));
	[_timeSinceLastRead start];
	
	if ((didReachEnd)||(didReachStart))	{
		id d = [self delegate];
		if (!_reachedEnd)	{
			if ((d != nil) && ([(id)d conformsToProtocol:@protocol(VVGIFPlayerDelegate)]))	{
				[d playerDidReachEnd:self];
			}
		}
		//	do this so that the end notifications don't keep sending off over and over if we're in a nonlooping mode
		if ((loopMode == VVGIFPlayerEndActionHold) || (loopMode == VVGIFPlayerEndActionCutToBlack) || (loopMode == VVGIFPlayerEndActionNext))	{
			_reachedEnd = YES;
		}
		else	{
			_reachedEnd = NO;
		}
	}
}

- (BOOL)hasNewFrame	{
	BOOL returnMe = YES;
	
	//	call the render upkeep now so we've got the most up to date time
	//[self renderUpkeep];
	
	@synchronized (self)	{
		if (playerItem == nil)	{
			returnMe = NO;
		}
		else	{
			if (_lastReadFrame != nil)	{
				if (CMTimeRangeContainsTime([_lastReadFrame timeRange], currentTime))	{
					returnMe = NO;
				}
			}
			//	if a new frame is available grab it now!
			if (returnMe == YES)	{
				VVGIFFrame *tmpFrame = [playerItem frameForTime: currentTime];
				if (tmpFrame != nil)	{
					VVRELEASE(_lastReadFrame);
					_lastReadFrame = [tmpFrame retain];
				}
			}
		}
	}
	
	return returnMe;
}

- (NSBitmapImageRep *)copyCurrentFrameRep	{
	NSBitmapImageRep *returnMe = nil;
	
	@synchronized (self)	{
		if (_lastReadFrame != nil)	{
			NSBitmapImageRep *frameRep = [_lastReadFrame imageRep];
			if (frameRep != nil)	{
				returnMe = [frameRep retain];
			}
		}
	}
	
    return returnMe;
}

- (CMTime)currentTime	{
	return currentTime;
}

- (void)seekToTime:(CMTime)time	{
	seekTime = time;
}

- (CMTime)startTime	{
	return startTime;
}

- (void)setStartTime:(CMTime)time	{
	startTime = time;
}

- (CMTime)endTime	{
	return endTime;
}

- (void)setEndTime:(CMTime)time	{
	endTime = time;
}

- (VVGIFPlayerEndActionType)loopMode	{
	return loopMode;
}

- (void)setLoopMode:(VVGIFPlayerEndActionType)m	{
	loopMode = m;
	_reverse = NO;
}

- (id)delegate	{
	id returnMe = nil;

	@synchronized (self)	{
		returnMe = delegate;
	}
	
	return returnMe;
}

- (void)setDelegate:(id)d	{
	@synchronized (self)	{
		delegate = d;
	}
}

- (float)rate	{
	return rate;
}

- (void)setRate:(float)r	{
	rate = r;
}

- (CMTime)duration	{
	CMTime returnMe;
	@synchronized (self)	{
		if (playerItem != nil)	{
			returnMe = [playerItem duration];
		}
	}
	return returnMe;
}

- (NSSize)presentationSize	{
	NSSize returnMe;
	@synchronized (self)	{
		if (playerItem != nil)	{
			returnMe = [playerItem presentationSize];
		}
	}
	return returnMe;
}

- (VVGIFPlayerItem *)playerItem	{
	VVGIFPlayerItem *returnMe = nil;
	@synchronized (self)	{
		returnMe = playerItem;
	}
	return returnMe;
}

- (void)setPlayerItem:(VVGIFPlayerItem *)item	{
	@synchronized (self)	{
		VVRELEASE(playerItem);
		if (item != nil)	{
			//	retain the item and then reset the start / end times / loop mode
			playerItem = [item retain];
			[playerItem doPreload];
			startTime = CMTimeMakeWithSeconds(0.0,600);
			currentTime = startTime;
			endTime = [playerItem duration];
			rate = 0.0;
			loopMode = VVGIFPlayerEndActionReverse;
			_reverse = NO;
		}
	}
}


@end
