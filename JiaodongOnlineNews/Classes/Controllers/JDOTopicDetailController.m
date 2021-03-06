//
//  JDOTopicDetailController.m
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-7-4.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDOTopicDetailController.h"
#import "UIWebView+RemoveShadow.h"
#import "JDOTopicModel.h"
#import "JDOWebClient.h"
#import "JDOTopicDetailModel.h"
#import "JDOCenterViewController.h"
#import "WebViewJavascriptBridge_iOS.h"
#import "JDOReviewListController.h"
#import "UIDevice+IdentifierAddition.h"
#import "JDORegxpUtil.h"
#import "SDImageCache.h"
#import "JDOImageModel.h"
#import "JDOImageDetailModel.h"
#import "JDOImageDetailController.h"
#import "JDORightViewController.h"
#define Default_Image @"news_head_placeholder.png"

@interface JDOTopicDetailController ()

@property (strong, nonatomic) WebViewJavascriptBridge *bridge;
@property (strong, nonatomic) UITapGestureRecognizer *closeReviewGesture;
@property (strong, nonatomic) UIView *blackMask;

@end

@implementation JDOTopicDetailController

NSArray *imageUrls;

- (id)initWithTopicModel:(JDOTopicModel *)topicModel pController:(JDOTopicViewController *)pController{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.topicModel = topicModel;
        self.pController = pController;
    }
    return self;
}

#pragma mark - View Life Cycle

- (void)loadView{
    [super loadView];
    // 内容
    self.view.backgroundColor = [UIColor colorWithHex:Main_Background_Color];// 与html的body背景色相同
    // 工具栏
    NSArray *toolbarBtnConfig = @[
                                  [NSNumber numberWithInt:ToolBarButtonReview],
                                  [NSNumber numberWithInt:ToolBarButtonShare],
                                  [NSNumber numberWithInt:ToolBarButtonFont],
                                  [NSNumber numberWithInt:ToolBarButtonCollect]
                                  ];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 44, 320, App_Height-44-44/*_toolbar.height*/)]; // 去掉导航栏和工具栏
    [self.webView makeTransparentAndRemoveShadow];
//    self.webView.delegate = self;
    self.webView.scalesPageToFit = true;
    [self.view addSubview:_webView];
    
    _toolbar = [[JDOToolBar alloc] initWithModel:self.topicModel parentController:self typeConfig:toolbarBtnConfig widthConfig:nil frame:CGRectMake(0, App_Height-56.0, 320, 56.0) theme:ToolBarThemeWhite];// 背景有透明渐变,高度是56不是44
    _toolbar.shareTarget = self;
    [self.view addSubview:_toolbar];
    
    self.statusView = [[JDOStatusView alloc] initWithFrame:CGRectMake(0, 44, 320, App_Height-44)];
    self.statusView.delegate = self;
    [self.view addSubview:self.statusView];
}

- (void) onRetryClicked:(JDOStatusView *) statusView{
    [self loadWebView];
}

- (void) onNoNetworkClicked:(JDOStatusView *) statusView{
    [self loadWebView];
}

- (void) setCurrentState:(ViewStatusType)status{
    _status = status;
    
    self.statusView.status = status;
    if(status == ViewStatusNormal){
        self.webView.hidden = false;
    }else{
        self.webView.hidden = true;
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self loadWebView];
    [self buildWebViewJavascriptBridge];
    
    _toolbar.bridge = self.bridge;
    
    self.closeReviewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self.toolbar action:@selector(hideReviewView)];
    _blackMask = self.view.blackMask;
    [_blackMask addGestureRecognizer:self.closeReviewGesture];
}

- (void) setupNavigationView{
    [self.navigationView addBackButtonWithTarget:self action:@selector(backToListView)];
    [self.navigationView setTitle:@"每日一题"];
    [self.navigationView addRightButtonImage:@"top_navigation_review" highlightImage:@"top_navigation_review" target:self action:@selector(showReviewList)];
}

- (void) backToListView{
    JDOCenterViewController *centerViewController = (JDOCenterViewController *)[SharedAppDelegate deckController].centerController;
    [centerViewController popToViewController:[centerViewController.viewControllers objectAtIndex:centerViewController.viewControllers.count -2] orientation:JDOTransitionToRight animated:true complete:^{
        [_pController returnFromDetail];
    }];
}

- (BOOL) onSharedClicked {
    if (self.topicModel == nil) {
        [JDOCommonUtil showHintHUD:@"话题尚未加载！" inView:self.view];
        return FALSE;
    }
    return TRUE;
}

-(void)viewDidUnload{
    [super viewDidUnload];
    [self setWebView:nil];
    [self setToolbar:nil];
    [self setStatusView:nil];
    
    [_blackMask removeGestureRecognizer:self.closeReviewGesture];
}

- (void) showReviewList{
    JDOCenterViewController *centerViewController = (JDOCenterViewController *)[SharedAppDelegate deckController].centerController;
    JDOReviewListController *reviewController = [[JDOReviewListController alloc] initWithType:JDOReviewTypeNews params:@{@"aid":self.topicModel.id,@"deviceId":[[UIDevice currentDevice] uniqueDeviceIdentifier]}];
    reviewController.model = self.topicModel;
    [centerViewController pushViewController:reviewController animated:true];
}

#pragma mark - Load WebView

- (void) buildWebViewJavascriptBridge{
    //    [WebViewJavascriptBridge enableLogging];
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        responseCallback(@"Response for message from ObjC");
    }];
    [_bridge registerHandler:@"showImageDetail" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *imageId = [(NSDictionary *)data valueForKey:@"imageId"];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        for (int i=0; i<[imageUrls count]; i++) {
            NSString *localUrl = [imageCache cachePathForKey:[imageUrls objectAtIndex:i]];
            JDOImageDetailModel *imageDetail = [[JDOImageDetailModel alloc] initWithUrl:[imageUrls objectAtIndex:i] andLocalUrl:localUrl andContent:self.topicModel.title andTitle:self.topicModel.title andTinyUrl:self.topicModel.tinyurl];
            [array addObject:imageDetail];
        }
        JDOImageDetailController *detailController = [[JDOImageDetailController alloc] initWithImageModel:[[JDOImageModel alloc] init]];
        detailController.imageIndex = [imageId integerValue];
        detailController.imageDetails = array;
        JDOCenterViewController *centerController = (JDOCenterViewController *)[[SharedAppDelegate deckController] centerController];
        [centerController pushViewController:detailController animated:true];
        // 显示图片详情
        responseCallback(imageId);
    }];
    [_bridge registerHandler:@"loadImage" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *realUrl = [(NSDictionary *)data valueForKey:@"realUrl"];
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        UIImage *cachedImage = [imageCache imageFromKey:realUrl fromDisk:YES]; // 将需要缓存的图片加载进来
        if (cachedImage) {
            [self callJsToRefreshWebview:realUrl andLocal:[imageCache cachePathForKey:realUrl]];
        } else {
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            [manager downloadWithURL:[NSURL URLWithString:realUrl] delegate:self storeDelegate:self];
        }
    }];
    [_bridge registerHandler:@"showImageSet" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *linkId = [(NSDictionary *)data valueForKey:@"linkId"];
        JDOImageModel *imageModel = [[JDOImageModel alloc] init];
        imageModel.id = linkId;
        JDOImageDetailController *detailController = [[JDOImageDetailController alloc] initWithImageModel:imageModel];
        JDOCenterViewController *centerController = (JDOCenterViewController *)[[SharedAppDelegate deckController] centerController];
        // 通过pushViewController 显示图集视图
        [centerController pushViewController:detailController animated:true];
        responseCallback(linkId);
    }];
}

- (void) saveTopicDetailToLocalCache:(NSDictionary *) topicDetail{
    NSString *cacheFilePath = [[SharedAppDelegate topicDetailCachePath] stringByAppendingPathComponent:[@"TopicDetail_" stringByAppendingString:[topicDetail objectForKey:@"id"]]];
    [NSKeyedArchiver archiveRootObject:topicDetail toFile:cacheFilePath];
}

- (id) readTopicDetailFromLocalCache{
    NSDictionary *topicModel = [NSKeyedUnarchiver unarchiveObjectWithFile: JDOGetCacheFilePath([@"JDOCache/TopicDetailCache" stringByAppendingPathComponent:[@"TopicDetail_" stringByAppendingString:self.topicModel.id]])];
    return topicModel;
}

- (void) loadWebView{
#warning 若有缓存可以从缓存读取,话题涉及到动态的投票数量,是否缓存有待考虑
    NSMutableDictionary *topicModel = [self readTopicDetailFromLocalCache];
    if (topicModel && ![Reachability isEnableNetwork]/*无网络但是有缓存*/) {
        [self setCurrentState:ViewStatusLoading];
        self.topicModel.tinyurl = [topicModel objectForKey:@"tinyurl"];
        [self.navigationView setRightBtnCount:[topicModel objectForKey:@"commentCount"]];
        if (self.topicModel.showMore) {
            [topicModel setObject:@"1" forKey:@"showMore"];
        } else {
            [topicModel setObject:@"0" forKey:@"showMore"];
        }
        NSString *mergedHTML = [JDOTopicDetailModel mergeToHTMLTemplateFromDictionary:[self replaceUrlAndAsyncLoadImage:topicModel]];
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        [self.webView loadHTMLString:mergedHTML baseURL:[NSURL fileURLWithPath:bundlePath isDirectory:true]];
    }else if( ![Reachability isEnableNetwork]){
        [self setCurrentState:ViewStatusNoNetwork];
    }else{
        [self setCurrentState:ViewStatusLoading];
        [[JDOJsonClient sharedClient] getPath:TOPIC_DETAIL_SERVICE parameters:@{@"aid":self.topicModel.id} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if([responseObject isKindOfClass:[NSArray class]] && [(NSArray *)responseObject count]==0){
                // 新闻不存在
                [self setCurrentState:ViewStatusRetry];
            }else if([responseObject isKindOfClass:[NSDictionary class]]){
                NSMutableDictionary *dict = [responseObject mutableCopy];
                [dict setObject:self.topicModel.id forKey:@"id"];
                // 从新闻列表导航进来没有评论数，获取评论数需要sum，为防止性能问题暂不添加
                if(self.topicModel.follownums == nil){
                    [dict setObject:@"0" forKey:@"commentCount"];
                }else{
                    [dict setObject:self.topicModel.follownums forKey:@"commentCount"];
                }
                
                [self saveTopicDetailToLocalCache:dict];
                self.topicModel.tinyurl = [dict objectForKey:@"tinyurl"];
                [self.navigationView setRightBtnCount:[dict objectForKey:@"commentCount"]];
                if (self.topicModel.showMore) {
                    [dict setObject:@"1" forKey:@"showMore"];
                } else {
                    [dict setObject:@"0" forKey:@"showMore"];
                }
                NSString *mergedHTML = [JDOTopicDetailModel mergeToHTMLTemplateFromDictionary:[self replaceUrlAndAsyncLoadImage:dict]];
                NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
                [self.webView loadHTMLString:mergedHTML baseURL:[NSURL fileURLWithPath:bundlePath isDirectory:true]];
            }else{
                [self setCurrentState:ViewStatusRetry];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self setCurrentState:ViewStatusRetry];
        }];
    }
}

- (id) replaceUrlAndAsyncLoadImage:(NSDictionary *) dictionary{
    NSString *html = [dictionary objectForKey:@"content"];
    
    //获取图片原始url进行异步加载，原图替换为占位图，加载结束后再替换
    imageUrls = [JDORegxpUtil getXmlTagAttrib: html andTag:@"img" andAttr:@"src"];
    for (int i=0; i<[imageUrls count]; i++) {
        NSString *realUrl = [imageUrls objectAtIndex:i];
        //更改图片为占位图
        NSMutableString *replaceWithString = [[NSMutableString alloc] init];
        [replaceWithString appendString:Default_Image];
        UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromKey:realUrl fromDisk:YES];
        if ([JDOCommonUtil ifNoImage] && !cachedImage) {
            [replaceWithString appendString:@"\" tapToLoad=\"true"];
        }
        [replaceWithString appendString:@"\" realUrl=\""];
        [replaceWithString appendString:realUrl];
        html = [html stringByReplacingOccurrencesOfString:realUrl withString:replaceWithString];
    }
    NSMutableDictionary *newsDetail = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    [newsDetail setObject:html forKey:@"content"];
    return newsDetail;
}

-(void) callJsToRefreshWebview:(NSString *)realUrl andLocal:(NSString *) localUrl {
    //图片加载成功，调用js，刷新图片
    NSMutableString *js = [[NSMutableString alloc] init];
    [js appendString:@"refreshImg('"];
    [js appendString:realUrl];
    [js appendString:@"', '"];
    [js appendString:localUrl];
    [js appendString:@"')"];
    [self.webView stringByEvaluatingJavaScriptFromString:js];
    
}

// 当下载完成并且保存成功后，调用回调方法，使下载的图片显示
- (void)didFinishStoreForKey:(NSString *)key {
    NSString *realUrl = key;
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [self callJsToRefreshWebview:realUrl andLocal:[imageCache cachePathForKey:realUrl]];
}

#pragma mark - Webview delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return false;
    }
    return true;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [self setCurrentState:ViewStatusNormal];
    //webview加载完成，再开始异步加载图片
    if(imageUrls) {
        for (int i=0; i<[imageUrls count]; i++) {
            NSString *realUrl = [imageUrls objectAtIndex:i];
            NSURL *url = [NSURL URLWithString:realUrl];
            SDImageCache *imageCache = [SDImageCache sharedImageCache];
            UIImage *cachedImage = [imageCache imageFromKey:realUrl fromDisk:YES]; // 将需要缓存的图片加载进来
            if (cachedImage) {
                [self callJsToRefreshWebview:realUrl andLocal:[imageCache cachePathForKey:realUrl]];
            } else {
                if ([JDOCommonUtil ifNoImage]) {//3g下，不下载图片
                    [self callJsToRefreshWebview:realUrl andLocal:@"base_empty_view.png"];
                } else {
                    SDWebImageManager *manager = [SDWebImageManager sharedManager];
                    [manager downloadWithURL:url delegate:self storeDelegate:self];
                }
            }
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [self setCurrentState:ViewStatusRetry]; 
}
@end
