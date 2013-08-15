//
//  JDOViolationViewController.m
//  JiaodongOnlineNews
//
//  Created by Roc on 13-6-24.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDOViolationViewController.h"
#import "JDOJsonClient.h"
#import "JDOViolationTableCell.h"
#import "JDOCarManagerViewController.h"
#import "JDOCommonUtil.h"

@interface JDOViolationViewController ()

@end

@implementation JDOViolationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        types = @[@"大型汽车",@"小型汽车",@"使馆汽车",@"领馆汽车",@"境外汽车",@"外籍汽车",@"两、三轮摩托车",@"轻便摩托车",@"使馆摩托车",@"领馆摩托车",@"境外摩托车",@"外籍摩托车",@"农用运输车",@"拖拉机",@"挂车",@"教练汽车",@"教练摩托车",@"实验汽车",@"实验摩托车",@"临时入境汽车",@"临时入境摩托车",@"临时行驶车",@"公安警车",@"公安警车",@"其他"];
    }
    return self;
}

- (void)setCartype:(NSString *)type index:(int)index
{
    [CarType setTitle:type forState:UIControlStateNormal];
    NSMutableString *tmp = [[NSMutableString alloc] initWithString:@"0"];
    if (index < 10) {
        [tmp appendString:[NSString stringWithFormat:@"%d", index]];
        CarTypeString = tmp;
    } else {
        CarTypeString = [NSString stringWithFormat:@"%d", index];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [CarNum addTarget:self action:@selector(changeToUpperCase:) forControlEvents:UIControlEventEditingDidEnd];
    
    [ChassisNum setKeyboardType:UIKeyboardTypeNumberPad];
    [carnumlabel setTextColor:[UIColor colorWithHex:Light_Blue_Color]];
    [cartypelabel setTextColor:[UIColor colorWithHex:Light_Blue_Color]];
    [chassisnumlabel setTextColor:[UIColor colorWithHex:Light_Blue_Color]];
    [CarType setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [CarType setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    CarType.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 30);
    
    CarTypeString = [[NSMutableString alloc] initWithString:@"02"];
    resultArray = [[NSMutableArray alloc] init];
    
    checkBox1 = [[M13Checkbox alloc] initWithTitle:@"保存车辆信息" andHeight:18];
    [checkBox1 setTitleColor:Light_Blue_Color];
    [checkBox1 setCheckAlignment:M13CheckboxAlignmentLeft];
    checkBox1.frame = CGRectMake(13, CGRectGetMaxY(ChassisNum.frame)+12, checkBox1.frame.size.width, checkBox1.frame.size.height);
    [tp addSubview:checkBox1];
    
    checkBox2 = [[M13Checkbox alloc] initWithTitle:@"接收违章推送" andHeight:18];
    [checkBox2 setTitleColor:Light_Blue_Color];
    [checkBox2 setCheckAlignment:M13CheckboxAlignmentLeft];
    checkBox2.frame = CGRectMake(320-13-checkBox2.frame.size.width, CGRectGetMaxY(ChassisNum.frame)+12, checkBox2.frame.size.width, checkBox2.frame.size.height);
    [tp addSubview:checkBox2];
    
    [tp setScrollEnabled:NO];
    
    [result setBounces:NO];
    [result setDataSource:self];
    [result setDelegate:self];
    
    [result setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [result setHidden:YES];
    [resultline setHidden:YES];
    [resultline_shadow setHidden:YES];
    [no_result_image setHidden:YES];
    
    UIImageView *header = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 294, 45)];
    [header setImage:[UIImage imageNamed:@"vio_result_label"]];
    UILabel *resultlabel = [[UILabel alloc] initWithFrame:CGRectMake(106, 12, 90, 20)];
    [resultlabel setText:@"查询结果"];
    [resultlabel setTextColor:[UIColor colorWithRed:1.0 green:.0 blue:.0 alpha:1.0]];
    [resultlabel setFont:[UIFont systemFontOfSize:20.0]];
    [resultlabel setBackgroundColor:[UIColor clearColor]];
    [header addSubview:resultlabel];
    [result setTableHeaderView:header];
}

- (void) changeToUpperCase:(UITextField *) textField{
    textField.text = [textField.text uppercaseString];
}

- (void)setupNavigationView
{
    [self.navigationView addBackButtonWithTarget:self action:@selector(onBackBtnClick)];
    [self.navigationView addRightButtonImage:@"vio_head_btn" highlightImage:@"vio_head_btn" target:self action:@selector(onRightBtnClick)];
    [self.navigationView setTitle:@"违章查询"];
}

- (void) onBackBtnClick
{
    JDOCenterViewController *centerViewController = (JDOCenterViewController *)self.navigationController;
    [centerViewController popToViewController:[centerViewController.viewControllers objectAtIndex:centerViewController.viewControllers.count - 2] animated:true];
}

- (void) onRightBtnClick
{
    JDOCarManagerViewController *carmanager = [[JDOCarManagerViewController alloc] initWithNibName:nil bundle:nil];
    carmanager.back = self;
    [self.navigationController pushViewController:carmanager animated:YES];
}

- (IBAction)selectCarType:(id)sender
{
    stringpicker = [[ActionSheetStringPicker alloc] initWithTitle:@"选择号牌种类" rows:types initialSelection:1 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        [CarType setTitle:[types objectAtIndex:selectedIndex] forState:UIControlStateNormal];
        NSMutableString *tmp = [[NSMutableString alloc] initWithString:@"0"];
        if (selectedIndex < 9) {
            [tmp appendString:[NSString stringWithFormat:@"%d", selectedIndex + 1]];
            CarTypeString = tmp;
        } else {
            CarTypeString = [NSString stringWithFormat:@"%d", selectedIndex + 1];
        }
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:sender];
    
    [stringpicker showActionSheetPicker];
}

- (void)cleanData
{
    [defaultback setHidden:NO];
    [result setHidden:YES];
    [resultline setHidden:YES];
    [resultline_shadow setHidden:YES];
    [no_result_image setHidden:YES];
}

- (IBAction)sendToServer:(id)sender
{
    CarNumString = [[NSMutableString alloc] initWithString:CarNum.text];
    ChassisNumString = [[NSMutableString alloc] initWithString:ChassisNum.text];
    
    if( ![Reachability isEnableNetwork]){
        [JDOCommonUtil showHintHUD:No_Network_Connection inView:self.view withSlidingMode:WBNoticeViewSlidingModeUp];
        return;
    }
    if ([self checkEmpty]) {
        return;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:CarNumString forKey:@"hphm"];
    [params setValue:CarTypeString forKey:@"cartype"];
    [params setValue:ChassisNumString forKey:@"vin"];
    
    [result setHidden:YES];
    [resultline setHidden:YES];
    [resultline_shadow setHidden:YES];
    [no_result_image setHidden:YES];
    
    [[JDOJsonClient sharedClient] getPath:VIOLATION_SERVICE parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([[(NSDictionary *)responseObject objectForKey:@"status"] isKindOfClass:[NSNumber class]]) {
            NSArray *datas = [(NSDictionary *)responseObject objectForKey:@"data"];
            [defaultback setHidden:YES];
            [resultline_shadow setHidden:NO];
            [resultline setHidden:NO];
            if (datas.count > 0) {
                [result setHidden:NO];
                [resultArray removeAllObjects];
                [resultArray addObjectsFromArray:datas];
                [result reloadData];
            } else if (datas.count == 0) {
#warning no_result_image的图片在iphone5下需要更换
                [no_result_image setHidden:NO];
            }
        } else {
            NSLog(@"wrongParams%@",params);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    
    [CarNum resignFirstResponder];
    [ChassisNum resignFirstResponder];
    
    // 设置违章推送
    if (checkBox2.isChecked) {
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"JDO_Push_UserId"];
        if (userId == nil) {
            [self dealWithBindError];
        }else{
            [params setObject:userId forKey:@"userid"];
            [[JDOJsonClient sharedClient] getPath:BINDVIOLATIONINFO_SERVICE parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                id status = [(NSDictionary *)responseObject objectForKey:@"status"];
                if ([status isKindOfClass:[NSNumber class]]) {
                    int _status = [status intValue];
                    if (_status == 1) { //绑定成功
                        if (checkBox1.isChecked) {
                            [self saveCarMessage:true];
                        }
                    }else if(_status == 0){
                        [self dealWithBindError];
                    }
                } else if([status isKindOfClass:[NSString class]]){
                    if ([status isEqualToString:@"wrongparam"]) {
                        NSLog(@"参数错误");
                        [self dealWithBindError];
                    }else if([status isEqualToString:@"exist"]){
                        NSLog(@"已经存在绑定信息:%@",status);
                        if (checkBox1.isChecked) {
                            [self saveCarMessage:true];
                        }
                    }
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self dealWithBindError];
            }];
        }
    }else{
        if (checkBox1.isChecked) {
            [self saveCarMessage:false];
        }
    }
}

- (void) dealWithBindError{
    [JDOCommonUtil showHintHUD:@"设置违章推送失败，请稍后再试。" inView:self.view withSlidingMode:WBNoticeViewSlidingModeUp];
    [checkBox2 setCheckState:M13CheckboxStateUnchecked];
    if (checkBox1.isChecked) {
        [self saveCarMessage:false];
    }
}

- (void)saveCarMessage:(BOOL)isPush
{
    NSDictionary *carMessage = @{@"hphm":CarNumString, @"cartype":CarTypeString, @"vin":ChassisNumString, @"cartypename":CarType.titleLabel.text,@"ispush":[NSNumber numberWithBool:isPush]};
    if ([self readCarMessage]) {
        BOOL isExisted = NO;
        for (int i = 0; i < carMessageArray.count; i++) {
            if ([[carMessageArray objectAtIndex:i] isEqualToDictionary:carMessage]) {
                isExisted = YES;
            }
        }
        if (!isExisted) {
            [carMessageArray addObject:carMessage];
        }
    } else {
        carMessageArray = [[NSMutableArray alloc] init];
        [carMessageArray addObject:carMessage];
    }
    [NSKeyedArchiver archiveRootObject:carMessageArray toFile:JDOGetDocumentFilePath(@"CarMessage")];
    carMessageArray = nil;
}

- (BOOL) readCarMessage{
    carMessageArray = [NSKeyedUnarchiver unarchiveObjectWithFile: JDOGetDocumentFilePath(@"CarMessage")];
    return (carMessageArray != nil);
}

- (BOOL)checkEmpty
{
    if (CarNumString.length < 7) {
        [JDOCommonUtil showHintHUD:@"车牌号不足5位" inView:self.view withSlidingMode:WBNoticeViewSlidingModeUp];
        return YES;
    }
    if (ChassisNumString.length < 4){
        [JDOCommonUtil showHintHUD:@"车架号不足4位" inView:self.view withSlidingMode:WBNoticeViewSlidingModeUp];
        return YES;
    }
    return NO;
}

- (void)setData:(NSDictionary *)data
{
    [CarType.titleLabel setText:[data objectForKey:@"cartypename"]];
    CarTypeString = [data objectForKey:@"cartype"];
    [CarNum setText:[data objectForKey:@"hphm"]];
    [ChassisNum setText:[data objectForKey:@"vin"]];
}


#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell.height;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (resultArray.count > 0) {
        NSString *cellIdentifier = @"ViolationTableCell";
        
        JDOViolationTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[JDOViolationTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        NSDictionary *temp = [resultArray objectAtIndex:indexPath.row];
        if ((App_Height > 480)&&(resultArray.count == 1)) {
            cell.iphone5Style = 85.0;
        } else {
            cell.iphone5Style = 0.0;
        }
        [cell setData:temp];
        if (indexPath.row == resultArray.count - 1) {
            [cell setSeparator:[UIImage imageNamed:@"vio_line_wavy"]];
        } else {
            [cell setSeparator:nil];
        }
        
        return cell;
    }
    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return resultArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

@end
