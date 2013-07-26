//
//  JDOShareAuthController.m
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-19.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDOShareAuthController.h"
#import <AGCommon/UIImage+Common.h>
#import "AGShareCell.h"
#import <AGCommon/UIColor+Common.h>
#import "JDOShareViewDelegate.h"
#import "JDORightViewController.h"
//#import "MBSwitch.h"
#import "TTFadeSwitch.h"

#define TARGET_CELL_ID @"targetCell"
#define BASE_TAG 100

@interface JDOShareAuthController ()

@end

@implementation JDOShareAuthController{
    UITableView *_tableView;
    NSMutableArray *_shareTypeArray;
    JDOShareViewDelegate *sharedDelegate;
}

#warning 分享绑定界面出现时稍微有点卡
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        //监听用户信息变更
        [ShareSDK addNotificationWithName:SSN_USER_INFO_UPDATE
                                   target:self
                                   action:@selector(userInfoUpdateHandler:)];
        
        _shareTypeArray = [[NSMutableArray alloc] initWithObjects:
                           @{@"title":@"新浪微博",@"type":[NSNumber numberWithInteger:ShareTypeSinaWeibo]},
                           @{@"title":@"腾讯微博",@"type":[NSNumber numberWithInteger:ShareTypeTencentWeibo]},
                           @{@"title":@"搜狐微博",@"type":[NSNumber numberWithInteger:ShareTypeSohuWeibo]},
                           @{@"title":@"网易微博",@"type":[NSNumber numberWithInteger:ShareType163Weibo]},
                           @{@"title":@"豆瓣社区",@"type":[NSNumber numberWithInteger:ShareTypeDouBan]},
                           @{@"title":@"QQ空间",@"type":[NSNumber numberWithInteger:ShareTypeQQSpace]},
                           @{@"title":@"人人网",@"type":[NSNumber numberWithInteger:ShareTypeRenren]},
                           @{@"title":@"开心网",@"type":[NSNumber numberWithInteger:ShareTypeKaixin]},
                           nil];
    }
    return self;
}

- (void) updateAuth{
    NSArray *authList = [NSArray arrayWithContentsOfFile:[NSString stringWithFormat:@"%@/authListCache.plist",NSTemporaryDirectory()]];
    if (authList == nil){
        [_shareTypeArray writeToFile:[NSString stringWithFormat:@"%@/authListCache.plist",NSTemporaryDirectory()] atomically:YES];
    }else{
        for (int i = 0; i < [authList count]; i++){
            NSDictionary *item = [authList objectAtIndex:i];
            for (int j = 0; j < [_shareTypeArray count]; j++){
                if ([[[_shareTypeArray objectAtIndex:j] objectForKey:@"type"] integerValue] == [[item objectForKey:@"type"] integerValue]){
                    [_shareTypeArray replaceObjectAtIndex:j withObject:[NSMutableDictionary dictionaryWithDictionary:item]];
                    break;
                }
            }
        }
    }
    if(_tableView){
        [_tableView reloadData];
    }
}

- (void)dealloc{
    [ShareSDK removeNotificationWithName:SSN_USER_INFO_UPDATE target:self];
}

- (void)loadView{
    [super loadView];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, self.view.width, App_Height-44)
                                              style:UITableViewStylePlain];
    _tableView.rowHeight = (App_Height-44.0f)/8;
    _tableView.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.scrollEnabled = false;
    [self.view addSubview:_tableView];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    _tableView = nil;
}

- (void) setupNavigationView{
    [self.navigationView addBackButtonWithTarget:self action:@selector(onBackBtnClick)];
    [self.navigationView setTitle:@"分享授权"];
}

- (void) onBackBtnClick{
    [(JDORightViewController *)self.stackViewController popViewController];
}

- (void)authSwitchChangeHandler:(UISwitch *)sender{
    
    NSInteger index = sender.tag - BASE_TAG;
    
    if (index < [_shareTypeArray count]){
        NSMutableDictionary *item = [_shareTypeArray objectAtIndex:index];
        if (sender.on){
            //用户用户信息
            ShareType type = [[item objectForKey:@"type"] integerValue];
            sharedDelegate = [[JDOShareViewDelegate alloc] initWithPresentView:self.view backBlock:^{
                sender.on = false;
            } completeBlock:nil];
//            [ShareSDK authWithType:type options:JDOGetOauthOptions(sharedDelegate) result:^(SSAuthState state, id<ICMErrorInfo> error) {
//                if (state == SSAuthStateSuccess){
//                    [_tableView reloadData];
//                }else if(state == SSAuthStateCancel){
//                    sender.on = false;
//                }else if(state == SSAuthStateFail){
//                    sender.on = false;
//                    NSLog(@"%d:%@",[error errorCode], [error errorDescription]);
//                }
//            }];
            [ShareSDK getUserInfoWithType:type
                              authOptions:JDOGetOauthOptions(sharedDelegate)
                                   result:^(BOOL result, id<ISSUserInfo> userInfo, id<ICMErrorInfo> error) {
                                       if (result){
                                           [item setObject:[userInfo nickname] forKey:@"username"];
                                           [_shareTypeArray writeToFile:[NSString stringWithFormat:@"%@/authListCache.plist",NSTemporaryDirectory()] atomically:YES];
                                           [_tableView reloadData];
                                       }else{
                                           sender.on = false;   // 从SSO点取消返回时
                                           if ([error errorCode] != -103){
                                               UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"绑定失败" message:[error errorDescription] delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
                                               [alertView show];
                                           }
                                       }
                                   }];
        }else{
            //取消授权
            [ShareSDK cancelAuthWithType:[[item objectForKey:@"type"] integerValue]];
            [_tableView reloadData];
        }
        
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_shareTypeArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TARGET_CELL_ID];
    if (cell == nil){
        cell = [[AGShareCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TARGET_CELL_ID] ;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:16.0f];
        
//        MBSwitch *switchCtrl = [[MBSwitch alloc] initWithFrame:CGRectMake(0, 0, 53, 31)];
//        [switchCtrl setTintColor:[UIColor grayColor]];
//        [switchCtrl setOnTintColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"滑动02"]]];
//        [switchCtrl setOffTintColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"滑动03"]]];
//        [switchCtrl setThumbTintColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"滑动01"]]];
        
#warning 缺少高亮图和mask，thumb图片要放大，即使圆圈不调大，周围也要加透明，为的是方便接受tap手势
        TTFadeSwitch *switchCtrl = [[TTFadeSwitch alloc] initWithFrame:CGRectMake(0, 0, 65, 27)];
        switchCtrl.thumbImage = [UIImage imageNamed:@"switch_thumb"];
//        switchCtrl.thumbHighlightImage = [UIImage imageNamed:@"滑动01"];
//        switchCtrl.trackMaskImage = [UIImage imageNamed:@"switchMask"];
        switchCtrl.trackImageOn = [UIImage imageNamed:@"switch_on"];
        switchCtrl.trackImageOff = [UIImage imageNamed:@"switch_off"];
        
        switchCtrl.thumbInsetX = -3.0;
        switchCtrl.thumbOffsetY = -1.0;
        
        [switchCtrl addTarget:self action:@selector(authSwitchChangeHandler:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = switchCtrl;
    }
    if (indexPath.row < [_shareTypeArray count]){
        NSDictionary *item = [_shareTypeArray objectAtIndex:indexPath.row];
        cell.imageView.image = [ShareSDK getClientIconWithType:[[item objectForKey:@"type"] integerValue]];
        
        UISwitch *accessoryView =  (UISwitch *)cell.accessoryView;
        accessoryView.on = [ShareSDK hasAuthorizedWithType:[[item objectForKey:@"type"] integerValue]];
        accessoryView.tag = BASE_TAG + indexPath.row;
        
        if (accessoryView.on){
#warning 是显示用户名还是"已授权"?若显示用户名，则需要在所有授权返回的位置都向authListCache.plist文件保存用户名信息
#warning 需要保证3处授权的地方都保存authListCache.plist，调整cell的内容，新浪微博:已授权(intotherainzy)
            cell.textLabel.text = [NSString stringWithFormat:@"已授权:%@",[item objectForKey:@"username"]];
        }else{
            cell.textLabel.text = @"未授权";
        }
    }
    return cell;
}

- (void)userInfoUpdateHandler:(NSNotification *)notif
{
    NSInteger plat = [[[notif userInfo] objectForKey:SSK_PLAT] integerValue];
    id<ISSUserInfo> userInfo = [[notif userInfo] objectForKey:SSK_USER_INFO];
    
    for (int i = 0; i < [_shareTypeArray count]; i++)
    {
        NSMutableDictionary *item = [_shareTypeArray objectAtIndex:i];
        ShareType type = [[item objectForKey:@"type"] integerValue];
        if (type == plat)
        {
            [item setObject:[userInfo nickname] forKey:@"username"];
            [_tableView reloadData];
        }
    }
}

@end
