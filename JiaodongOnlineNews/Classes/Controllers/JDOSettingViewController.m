//
//  JDOSettingViewController.m
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-5-22.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDOSettingViewController.h"
//#import "JDOShareAuthController.h"
#import "JDORightViewController.h"
#import "TTFadeSwitch.h"
#import "SDImageCache.h"
#import "JDOFeedbackViewController.h"
#import "JDOOffDownloadManager.h"
#import "ITWLoadingPanel.h"
#import "BPush.h"

@interface JDOSettingViewController ()

@end

@implementation JDOSettingViewController

BOOL downloadItemClickable = TRUE;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView{
    [super loadView];
    self.view.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, 320, App_Height-44) style:UITableViewStylePlain];
    self.tableView.rowHeight = (App_Height-44.0f)/JDOSettingItemCount;
    self.tableView.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = false;
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)setupNavigationView{
    [self.navigationView addBackButtonWithTarget:self action:@selector(onBackBtnClick)];
    [self.navigationView setTitle:@"设置选项"];
}

- (void) onBackBtnClick{
    [(JDORightViewController *)self.stackViewController popViewController];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return JDOSettingItemCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"reuseIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
        cell.selectionStyle = UITableViewCellAccessoryNone;
        cell.detailTextLabel.numberOfLines = 2;
    }
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    switch (indexPath.row) {
        case JDOSettingItemPushService:{
            cell.textLabel.text = @"接收新闻推送";
            cell.detailTextLabel.text = @"新闻推送服务，及时获取第一手新闻咨询。";
#warning 非正常状态可以将accessoryView替换为一个提醒图标,点击后通过弹出菜单提示信息
            if ([userDefault objectForKey:@"JDO_Push_News"] == nil) {  // 可能是获取token失败或者bindChannel失败或者setTag失败,总之是当前推送不可到达。
                cell.detailTextLabel.text = @"新闻推送服务尚未成功注册";
                cell.accessoryView = nil;
            }else{
                UIRemoteNotificationType enabledType=[[UIApplication sharedApplication] enabledRemoteNotificationTypes];
                if( !(enabledType & UIRemoteNotificationTypeAlert) && !(enabledType & UIRemoteNotificationTypeBadge) ){
                    cell.detailTextLabel.text = @"请在通知设置中开启提醒样式和图标标记，并开启通知中心以保留您未及时查看的通知。";
                    cell.accessoryView = nil;
                }else{
                    TTFadeSwitch *pushSwitch = [self buildCustomSwitch];
                    pushSwitch.tag = JDOSettingItemPushService;
                    pushSwitch.on = [[userDefault objectForKey:@"JDO_Push_News"] boolValue];
                    [pushSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = pushSwitch;
                }
            }
            break;
        }
        case JDOSettingItem3GSwitch:{
            cell.textLabel.text = @"2G/3G网络不下载图片";
            cell.detailTextLabel.text = @"在2G/3G网络环境不会自动下载图片，已经缓存的图片将正常显示。";
            TTFadeSwitch *_3GSwitch = [self buildCustomSwitch];
            _3GSwitch.tag = JDOSettingItem3GSwitch;
            _3GSwitch.on = [(NSNumber *)[userDefault objectForKey:@"JDO_No_Image"] boolValue];
            [_3GSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = _3GSwitch;
            break;
        }
        case JDOSettingItemClearCache:{
            cell.textLabel.text = @"清除缓存";
            
//            int diskFileCount = [JDOCommonUtil getDiskCacheFileCount];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"目前缓存文件占用磁盘空间%@。",[self calculateCacheSize]];
//            UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//            clearButton.frame = CGRectMake(0, 0, 65, 27);
//            clearButton.tag = JDOSettingItemClearCache;
//            [clearButton setTitle:@"清除" forState:UIControlStateNormal];
//            [clearButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = nil;
            break;
        }
        case JDOSettingItemDownload:{
            cell.textLabel.text = @"离线下载";
            cell.detailTextLabel.text = @"下载新闻、图片、话题等内容，在无网络时可离线阅读已经下载的内容。";
//            UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//            downloadButton.frame = CGRectMake(0, 0, 65, 27);
//            downloadButton.tag = JDOSettingItemDownload;
//            [downloadButton setTitle:@"下载" forState:UIControlStateNormal];
//            [downloadButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = nil;
            break;
        }
        case JDOSettingItemCheckVersion:{
            cell.textLabel.text = @"检查更新";
            cell.detailTextLabel.text = @"从App Store获取程序的最新版本，获得更好的使用体验。";
//            UIButton *updateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//            updateButton.frame = CGRectMake(0, 0, 65, 27);
//            updateButton.tag = JDOSettingItemCheckVersion;
//            [updateButton setTitle:@"更新" forState:UIControlStateNormal];
//            [updateButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = nil;
            break;
        }
        case JDOSettingItemFeedback:{
            cell.textLabel.text = @"意见反馈";
            cell.detailTextLabel.text = @"告诉我们您的意见和建议，我们将不断改进。";
            cell.accessoryView = nil;
            break;
        }
        default:
            break;
    }
    
    return cell;
}

- (TTFadeSwitch *) buildCustomSwitch{
    TTFadeSwitch *switchCtrl = [[TTFadeSwitch alloc] initWithFrame:CGRectMake(0, 0, 65, 27)];
    switchCtrl.thumbImage = [UIImage imageNamed:@"switch_thumb"];
    switchCtrl.trackImageOn = [UIImage imageNamed:@"switch_on"];
    switchCtrl.trackImageOff = [UIImage imageNamed:@"switch_off"];
    switchCtrl.thumbInsetX = -3.0;
    switchCtrl.thumbOffsetY = -1.0;
    return switchCtrl;
}

- (void)switchChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case JDOSettingItemPushService:{
            // 通知服务器开启或关闭推送服务
            if (sender.on) {
                [BPush setTag:@"ALL_NEWS_TAG"];
#warning 回调函数修正后下面一行应去掉
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"JDO_Push_News"];
            }else{
                [BPush delTag:@"ALL_NEWS_TAG"];
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"JDO_Push_News"];
            }
            break;
        }
        case JDOSettingItem3GSwitch:{
            NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
            [userDefault setObject:[NSNumber numberWithBool:sender.on] forKey:@"JDO_No_Image"];
            [userDefault synchronize];
            break;
        }
        default:
            break;
    }
}

//- (void)buttonClicked:(UIButton *)sender {
//    switch (sender.tag) {
//        case JDOSettingItemClearCache:{
//            MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:SharedAppDelegate.window];
//            [SharedAppDelegate.window addSubview:HUD];
//            HUD.labelText = @"正在清除缓存";
//            HUD.margin = 15.f;
//            HUD.removeFromSuperViewOnHide = true;
//            [HUD show:true];
//            [[SDImageCache sharedImageCache] clearDisk];    // 图片缓存
//            [JDOCommonUtil deleteJDOCacheDirectory];    // 文件缓存
//            [JDOCommonUtil createJDOCacheDirectory];
//            [JDOCommonUtil deleteURLCacheDirectory];    // URL在sqlite的缓存(cache.db)
//            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
//            HUD.mode = MBProgressHUDModeCustomView;
//            HUD.labelText = @"清除缓存完成";
//            [HUD hide:true afterDelay:1.0];
//            
//            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:JDOSettingItemClearCache inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
//            break;
//        }
//        case JDOSettingItemDownload:
//            [self offDownload];
//            break;
//        case JDOSettingItemCheckVersion:
//            [SharedAppDelegate checkForNewVersion];
//            break;
//        default:
//            break;
//    }
//}

//- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
//    switch (indexPath.row) {
//        case 0:
//            return UITableViewCellAccessoryCheckmark;
//            break;
//            
//        default:
//            break;
//    }
//    return UITableViewCellAccessoryNone;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case JDOSettingItemClearCache: {
            MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:SharedAppDelegate.window];
            [SharedAppDelegate.window addSubview:HUD];
            HUD.labelText = @"正在清除缓存";
            HUD.margin = 15.f;
            HUD.removeFromSuperViewOnHide = true;
            [HUD show:true];
            [[SDImageCache sharedImageCache] clearDisk];    // 图片缓存
            [JDOCommonUtil deleteJDOCacheDirectory];    // 文件缓存
            [JDOCommonUtil createJDOCacheDirectory];
            [JDOCommonUtil deleteURLCacheDirectory];    // URL在sqlite的缓存(cache.db)
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
            HUD.mode = MBProgressHUDModeCustomView;
            HUD.labelText = @"清除缓存完成";
            [HUD hide:true afterDelay:1.0];
            
            [self refreshCacheSize];
            break;
        }
        case JDOSettingItemDownload:
            if (downloadItemClickable) {
                downloadItemClickable = FALSE;
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                JDOOffDownloadManager *downloadOperation = [[JDOOffDownloadManager alloc] initWithTarget:self action:@selector(refreshProgressWithCount:)];
                NSOperationQueue *queue = [[NSOperationQueue alloc] init];
                [queue addOperation:downloadOperation];
                [ITWLoadingPanel showPanelInView:cell title:@"开始下载" cancelTitle:@"" cancel:^{
                    downloadItemClickable = TRUE;
                    [downloadOperation cancel];
                } disappear:^{
                    downloadItemClickable = TRUE;
                    [NSTimer scheduledTimerWithTimeInterval:3 target:self
                                                   selector:@selector(refreshCacheSize)
                                                   userInfo:nil repeats:NO];
                }];
            }
            break;
        case JDOSettingItemCheckVersion:
            [SharedAppDelegate checkForNewVersion];
            break;
        case JDOSettingItemFeedback: {
            JDOFeedbackViewController *feedbackController = [[JDOFeedbackViewController alloc] init];
            [(JDORightViewController *)self.stackViewController pushViewController:feedbackController];
            break;
        }
        default:
            break;
    }
}

- (void) refreshCacheSize{
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:JDOSettingItemClearCache inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSString *) calculateCacheSize {
    float diskFileSize = [JDOCommonUtil getDiskCacheFileSize]/1000.0f;
    NSString *sizeUnit = @"K";
    if (diskFileSize > 1000.0f) {
        diskFileSize = diskFileSize/1000.0f;
        sizeUnit = @"M";
    }
    NSString *ret = [NSString stringWithFormat:@"%.2f%@", diskFileSize, sizeUnit];
    return ret;
}

- (void) refreshProgressWithCount:(NSDictionary *) result {
    NSString *title = [result objectForKey:@"title"];
    if (title) {
        UILabel *titleLabel = [[ITWLoadingPanel sharedInstance] titleLabel];
        titleLabel.text = title;
    }
    NSNumber *count = [result objectForKey:@"count"];
    if (count) {
        UIProgressView *progressView = [[ITWLoadingPanel sharedInstance] progressView];
        
        [ITWLoadingPanel setProgress:([count floatValue]) animated:YES];
        if (1 == progressView.progress) {
            UILabel *titleLabel = [[ITWLoadingPanel sharedInstance] titleLabel];
            titleLabel.text = @"下载完成";
            [ITWLoadingPanel showSuccess];
        }
    }    
}

@end
