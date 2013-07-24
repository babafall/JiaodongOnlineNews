//
//  JDOViolationViewController.h
//  JiaodongOnlineNews
//
//  Created by Roc on 13-6-24.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "M13Checkbox.h"
#import "TPKeyboardAvoidingScrollView.h"

@interface JDOViolationViewController : JDONavigationController <UITableViewDataSource, UITableViewDelegate>
{
    IBOutlet UITextField *CarNum;
    IBOutlet UIButton *CarType;
    IBOutlet UITextField *ChassisNum;
    IBOutlet TPKeyboardAvoidingScrollView *tp;
    IBOutlet UITableView *result;
    IBOutlet UIImageView *defaultback;
    
    M13Checkbox *checkBox1;
    M13Checkbox *checkBox2;
    
    NSMutableString *CarNumString;
    NSMutableString *CarTypeString;
    NSMutableString *ChassisNumString;
    NSMutableArray *resultArray;
}
@property (nonatomic ,strong) NSMutableArray *listArray;
- (BOOL)checkEmpty;
- (void)setCartype:(NSString*) type index:(int)index;
- (IBAction)selectCarType:(id)sender;
- (IBAction)sendToServer:(id)sender;
- (void) onBackBtnClick;
- (void) onRightBtnClick;

@end
