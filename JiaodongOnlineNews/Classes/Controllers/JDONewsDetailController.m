//
//  JDONewsDetailController.m
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-4.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDONewsDetailController.h"
#import "UIWebView+RemoveShadow.h"
#import "JDONewsModel.h"
#import "JDOWebClient.h"
#import "JDONewsDetailModel.h"
#import "JDOImageModel.h"
#import "JDOImageDetailModel.h"
#import "JDOImageDetailController.h"
#import "JDOCenterViewController.h"
#import "WebViewJavascriptBridge_iOS.h"
#import "JDOReviewListController.h"
#import "UIDevice+IdentifierAddition.h"
#import "SDImageCache.h"
#import "JDORegxpUtil.h"
#import "DCKeyValueObjectMapping.h"

#define Default_Image @"news_head_placeholder.png"


@interface JDONewsDetailController ()

@property (strong, nonatomic) WebViewJavascriptBridge *bridge;
@property (strong, nonatomic) UITapGestureRecognizer *closeReviewGesture;
@property (strong, nonatomic) UIView *blackMask;

@end

@implementation JDONewsDetailController

NSArray *imageUrls;

- (id)initWithNewsModel:(JDONewsModel *)newsModel{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.newsModel = newsModel;
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
    self.webView.delegate = self;
    self.webView.scalesPageToFit = true;
    [self.view addSubview:_webView];
    
    _toolbar = [[JDOToolBar alloc] initWithModel:self.newsModel parentController:self typeConfig:toolbarBtnConfig widthConfig:nil frame:CGRectMake(0, App_Height-56.0, 320, 56.0) theme:ToolBarThemeWhite];// 背景有透明渐变,高度是56不是44
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

-(void)viewDidUnload{
    [super viewDidUnload];
    [self setWebView:nil];
    [self setToolbar:nil];
    [self setStatusView:nil];
    
    [_blackMask removeGestureRecognizer:self.closeReviewGesture];
}

#pragma mark - Navigation

- (void) setupNavigationView{
    [self.navigationView addBackButtonWithTarget:self action:@selector(backToViewList)];
    [self.navigationView setTitle:@"新闻详情"];
    [self.navigationView addRightButtonImage:@"top_navigation_review" highlightImage:@"top_navigation_review" target:self action:@selector(showReviewList)];
}

- (void) backToViewList{
    JDOCenterViewController *centerViewController = (JDOCenterViewController *)self.navigationController;
    [centerViewController popToViewController:[centerViewController.viewControllers objectAtIndex:0] animated:true];
}

- (void) showReviewList{
    JDOCenterViewController *centerViewController = (JDOCenterViewController *)self.navigationController;
    JDOReviewListController *reviewController = [[JDOReviewListController alloc] initWithType:JDOReviewTypeNews params:@{@"aid":self.newsModel.id,@"deviceId":[[UIDevice currentDevice] uniqueDeviceIdentifier]}];
    [centerViewController pushViewController:reviewController animated:true];
}

#pragma mark - Load WebView
     
- (void) buildWebViewJavascriptBridge{
//    [WebViewJavascriptBridge enableLogging];
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"ObjC received message from JS: %@", data);
        responseCallback(@"Response for message from ObjC");
    }];
    
    [_bridge registerHandler:@"showImageDetail" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *imageId = [(NSDictionary *)data valueForKey:@"imageId"];
        NSLog(@"showImageDetail js  imageId: %@", imageId);
        NSMutableArray *array = [[NSMutableArray alloc] init];
        JDOImageModel *imageModel = [[JDOImageModel alloc] init];
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        for (int i=0; i<[imageUrls count]; i++) {
            NSString *localUrl = [imageCache cachePathForKey:[imageUrls objectAtIndex:i]];
            JDOImageDetailModel *imageDetail = [[JDOImageDetailModel alloc] initWithUrl:localUrl andContent:self.newsModel.title];
            [imageDetail setIsLocalUrl:true];
            [array addObject:imageDetail];
        }
        
        JDOImageDetailController *detailController = [[JDOImageDetailController alloc] initWithImageModel:imageModel];
        detailController.imageIndex = [imageId integerValue];
        detailController.imageDetails = array;
        JDOCenterViewController *centerController = (JDOCenterViewController *)[[SharedAppDelegate deckController] centerController];
        [centerController pushViewController:detailController animated:true];
        // 显示图片详情
        responseCallback(imageId);
    }];
    [_bridge registerHandler:@"showImageSet" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *linkId = [(NSDictionary *)data valueForKey:@"linkId"];
        // 通过pushViewController 显示图集视图
        responseCallback(linkId);
    }];
}

- (void) loadWebView{
    #warning 若有缓存可以从缓存读取
    if (false /*有缓存*/) {
        [self setCurrentState:ViewStatusLogo];
    }else if( ![Reachability isEnableNetwork]){
        [self setCurrentState:ViewStatusNoNetwork];
    }else{
        [self setCurrentState:ViewStatusLoading];
        [[JDOJsonClient sharedClient] getPath:NEWS_DETAIL_SERVICE parameters:@{@"aid":self.newsModel.id} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if([responseObject isKindOfClass:[NSArray class]] && [(NSArray *)responseObject count]==0){
                // 新闻不存在
                [self setCurrentState:ViewStatusRetry];
            }else if([responseObject isKindOfClass:[NSDictionary class]]){
                // 如果需要保存detailModel对象,可以在这里解析
//                DCKeyValueObjectMapping *mapper = [DCKeyValueObjectMapping mapperForClass: [JDONewsDetailModel class]];
//                JDONewsDetailModel *detailModel = [mapper parseDictionary:responseObject];
                // 设置url短地址
                self.newsModel.tinyurl = [responseObject objectForKey:@"tinyurl"];
                
                NSString *mergedHTML = [JDONewsDetailModel mergeToHTMLTemplateFromDictionary:[self replaceUrlAndAsyncLoadImage:responseObject]];
                NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
                [self.webView loadHTMLString:mergedHTML baseURL:[NSURL fileURLWithPath:bundlePath isDirectory:true]];
            }else{
                // 返回结构不是json结构
                [self setCurrentState:ViewStatusRetry];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self setCurrentState:ViewStatusRetry];
        }];
    }
}

# warning 需测试异步加载
// 当下载完成后，调用回调方法，使下载的图片显示
- (id) replaceUrlAndAsyncLoadImage:(NSDictionary *) dictionary{
    NSString *html = [dictionary objectForKey:@"content"];
    
    //获取图片原始url进行异步加载，原图替换为占位图，加载结束后再替换
    imageUrls = [JDORegxpUtil getXmlTagAttrib: html andTag:@"img" andAttr:@"src"];
    for (int i=0; i<[imageUrls count]; i++) {
        NSString *realUrl = [imageUrls objectAtIndex:i];
        //更改图片为占位图
        NSMutableString *replaceWithString = [[NSMutableString alloc] init];
        [replaceWithString appendString:Default_Image];
        [replaceWithString appendString:@"\" realUrl=\""];
        [replaceWithString appendString:realUrl];
        [replaceWithString appendString:@"\""];
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

#pragma mark - Webview delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
//    NSString *scheme = request.URL.scheme;
//    NSString *host = request.URL.host;
//    NSString *query = request.URL.query;
//    NSNumber *port = request.URL.port;
    return true;
}

- (void)didFinishStoreForKey:(NSString *)key {
    NSLog(@"didFinishStoreForKey ");
    NSString *realUrl = key;
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [self callJsToRefreshWebview:realUrl andLocal:[imageCache cachePathForKey:realUrl]];
}

- (void)webViewDidStartLoad:(UIWebView *)webView{

}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [self setCurrentState:ViewStatusNormal];
    //webview加载完成，再开始异步加载图片
    if(imageUrls) {
        //NSLog(@"webview finished");
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        for (int i=0; i<[imageUrls count]; i++) {
            NSString *realUrl = [imageUrls objectAtIndex:i];
            NSURL *url = [NSURL URLWithString:realUrl];
            SDImageCache *imageCache = [SDImageCache sharedImageCache];
            UIImage *cachedImage = [imageCache imageFromKey:realUrl fromDisk:YES]; // 将需要缓存的图片加载进来
            if (cachedImage) {
                [self callJsToRefreshWebview:realUrl andLocal:[imageCache cachePathForKey:realUrl]];
            } else {
                [manager downloadWithURL:url delegate:self storeDelegate:self];
            }
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [self setCurrentState:ViewStatusRetry];
}
@end
