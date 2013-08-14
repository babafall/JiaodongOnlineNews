//
//  JDOFeedbackViewController.m
//  JiaodongOnlineNews
//
//  Created by Roc on 13-5-30.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDOFeedbackViewController.h"
#import "JDOHttpClient.h"
#import "JDORightViewController.h"
#import "JDOCommonUtil.h"

@interface JDOFeedbackViewController () <UITextFieldDelegate>

@end

@implementation JDOFeedbackViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)reportButtonClick:(id)sender
{
    contentString = [[NSString alloc] init];
    nameString = [[NSString alloc] init];
    telString = [[NSString alloc] init];
    emailString = [[NSString alloc] init];
    nameString = name.text;
    telString = tel.text;
    emailString = email.text;
    contentString = content.text;
    
    if (contentString.length == 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"提醒" message:@"意见内容为空，不能提交" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
    } else {
        [self sendToServer];
    }
}


- (void)sendToServer
{
    [self hiddenKeyBoard];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:contentString forKey:@"content"];
    if (nameString.length != 0) {
        [params setValue:nameString forKey:@"username"];
    }
    if (telString.length != 0) {
        [params setValue:telString forKey:@"phone"];
    }
    if (emailString.length != 0) {
        [params setValue:emailString forKey:@"email"];
    }
   
    JDOHttpClient *httpclient = [JDOHttpClient sharedClient];
    
    [httpclient getPath:FEEDBACK_SERVICE parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *json = [(NSData *)responseObject objectFromJSONData];
        id jsonvalue = [json objectForKey:@"status"];
        if ([jsonvalue isKindOfClass:[NSNumber class]]) {
            int status = [[json objectForKey:@"status"] intValue];
            if (status == 1) {
                [JDOCommonUtil showSuccessHUD:@"提交成功" inView:self.view withSlidingMode:WBNoticeViewSlidingModeUp];
            } else {
                [JDOCommonUtil showHintHUD:@"提交失败" inView:self.view withSlidingMode:WBNoticeViewSlidingModeUp];
            }
        } else {
            [JDOCommonUtil showHintHUD:@"提交失败" inView:self.view withSlidingMode:WBNoticeViewSlidingModeUp];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *errorString = [JDOCommonUtil formatErrorWithOperation:operation error:error];
        [JDOCommonUtil showHintHUD:@"提交失败" inView:self.view withSlidingMode:WBNoticeViewSlidingModeUp];
        NSLog(@"status:%@", errorString);
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [namelabel setTextColor:[UIColor colorWithHex:Light_Blue_Color]];
    [tellabel setTextColor:[UIColor colorWithHex:Light_Blue_Color]];
    [emaillabel setTextColor:[UIColor colorWithHex:Light_Blue_Color]];
    [contentlabel setTextColor:[UIColor colorWithHex:Light_Blue_Color]];
    [tpkey setScrollEnabled:NO];
}

- (void)setupNavigationView{
    [self.navigationView addBackButtonWithTarget:self action:@selector(onBackBtnClick)];
    [self.navigationView setTitle:@"意见反馈"];
}

- (void)hiddenKeyBoard{
    [name resignFirstResponder];
    [email resignFirstResponder];
    [tel resignFirstResponder];
    [content resignFirstResponder];
}

- (void)onBackBtnClick{
    [self hiddenKeyBoard];
    [(JDORightViewController *)self.stackViewController popViewController];
}
/*
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
}
*/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
