//
//  DraggingDelegate.h
//  GifToSyphon
//
//  Created by Daniel Ellis on 26/10/2015.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

@protocol DraggingDelegate <NSObject>

-(void)fileWasDraggedWithPath:(NSString *)filePath;

@end
