//
//  JDOConvenienceItemController.h
//  JiaodongOnlineNews
//
//  Created by Roc on 13-6-8.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebViewJavascriptBridge_iOS.h"

@interface JDOConvenienceItemController : JDONavigationController <JDOStatusView,JDOStatusViewDelegate,UIWebViewDelegate>

@property (strong,nonatomic) JDOStatusView *statusView;
@property (nonatomic,assign) ViewStatusType status;
@property (nonatomic,strong) UIWebView *webView;
@property BOOL deletetitle;

@property (strong, nonatomic) NSString *service;
@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) NSString *navTitle;

- (id)initWithService:(NSString *)service params:(NSDictionary *)params title:(NSString *)title;
-(void)backToParent;

@end
