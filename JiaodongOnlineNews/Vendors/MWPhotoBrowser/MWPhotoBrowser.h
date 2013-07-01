//
//  MWPhotoBrowser.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhoto.h"
#import "MWPhotoProtocol.h"
#import "MWCaptionView.h"
#import "JDOToolBar.h"
#import "MWZoomingScrollView.h"

// Debug Logging
#if 0 // Set to 1 to enable debug logging
#define MWLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

// Delgate
@class MWPhotoBrowser;
@protocol MWPhotoBrowserDelegate <NSObject>
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser;
- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;
@end

// MWPhotoBrowser
@interface MWPhotoBrowser : UIViewController <UIScrollViewDelegate> 

// Properties
@property (nonatomic,assign,getter = isCollected) BOOL collected;
@property (nonatomic,strong) UIView *navigationView;
@property (nonatomic,assign) NSUInteger currentPageIndex;
@property (nonatomic,strong) JDOToolBar *toolbar;
@property (nonatomic,assign) BOOL showToolbar;
@property (nonatomic,strong) MWCaptionView *captionView;

// Init
- (id)initWithPhotos:(NSArray *)photosArray  __attribute__((deprecated)); // Depreciated
- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate;

// Reloads the photo browser and refetches data
- (void)reloadData;

- (MWZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;

@end

