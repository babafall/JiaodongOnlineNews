//
//  LeftViewController.h
//  ViewDeckExample
//


@interface JDOLeftViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) UITableView *tableView;

- (void) transitionToAlpha:(float) alpha Scale:(float) scale;

@end