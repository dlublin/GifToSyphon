//
//  VVBufferGLView+Dragging.h
//  GifToSyphon
//
//  Created by Daniel Ellis on 26/10/2015.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VVBufferPool/VVBufferGLView.h>
#import "DraggingDelegate.h"

@interface VVBufferGLView(Dragging)

@property (nonatomic, weak) id<DraggingDelegate> dragDelegate;

@end
