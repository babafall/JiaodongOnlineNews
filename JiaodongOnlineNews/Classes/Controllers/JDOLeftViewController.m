//
//  LeftViewController.m
//  ViewDeckExample
//


#import "JDOLeftViewController.h"
#import "IIViewDeckController.h"
#import "JDOCenterViewController.h"
//#import "JDOLeftMenuCell.h"
#import "JDOXmlClient.h"
#import "JDOWeatherForcast.h"
#import "JDOWeather.h"
#import "JDOConvenienceItemController.h"

#define Menu_Cell_Height 55.0f
#define Menu_Image_Tag 101
#define Left_Margin 40.0f
#define Top_Margin 7.5f
#define Padding 5.0f
#define Weather_Icon_Height 56
#define Weather_Icon_Width 180.0/130.0*56
#define Separator_Y 324.0

@interface JDOLeftViewController ()

@property (strong) UIView *blackMask;
@property (strong) JDOWeather *weather;
@property (strong) JDOWeatherForcast *forcast;

@end

@implementation JDOLeftViewController{
    NSArray *iconNames;
    NSArray *iconSelectedNames;
    NSArray *iconTitles;
    int lastSelectedRow;
    UILabel *cityLabel;
    UIImageView *weatherIcon;
    UILabel *temperatureLabel;
    UILabel *weatherLabel;
    UILabel *dateLabel;
    NSArray *weekDayNames;
}

- (id)init{
    self = [super init];
    if (self) {
        lastSelectedRow = 0;
        iconNames = @[@"menu_news",@"menu_picture",@"menu_topic",@"menu_convenience",@"menu_livehood"];
        iconSelectedNames = @[@"menu_news_selected",@"menu_picture_selected",@"menu_topic_selected",@"menu_convenience_selected",@"menu_livehood_selected"];
        iconTitles = @[@"胶东在线",@"精选图片",@"每日一题",@"便民查询",@"网上民声"];
        weekDayNames = @[@"周日",@"周一",@"周二",@"周三",@"周四",@"周五",@"周六"];
    }
    return self;
}

- (void)loadView{
    [super loadView];
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds ];
    backgroundView.image = [UIImage imageNamed:@"menu_background.png"];
    [self.view addSubview:backgroundView];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, Menu_Cell_Height*5) style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.rowHeight = Menu_Cell_Height;
    _tableView.scrollEnabled = false;
    [self.view addSubview:_tableView];
    
    UIImageView *separateView = [[UIImageView alloc] initWithFrame:CGRectMake(0, Separator_Y, 320, 1)];
    separateView.image = [UIImage imageNamed:@"menu_separator.png"];
    [self.view addSubview:separateView];
    
    _blackMask = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320 , App_Height)];
    _blackMask.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_blackMask];
    
    // 天气部分
    UITapGestureRecognizer *weatherSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openWeather)];
    
    float topMargin = Separator_Y+Top_Margin;
    cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(Left_Margin, topMargin, 0, 0)];
    cityLabel.text = @"烟台";
    cityLabel.font = [UIFont boldSystemFontOfSize:18];
    cityLabel.textColor = [UIColor whiteColor];
    cityLabel.backgroundColor = [UIColor clearColor];
    [cityLabel sizeToFit];
    [self.view addSubview:cityLabel];
    
    weatherIcon = [[UIImageView alloc] initWithFrame:CGRectMake(Left_Margin+cityLabel.bounds.size.width+Padding, topMargin, Weather_Icon_Width, Weather_Icon_Height)];
    weatherIcon.image = [UIImage imageNamed:@"默认.png"];
    weatherIcon.userInteractionEnabled = YES;
    [weatherIcon addGestureRecognizer:weatherSingleTap];
    [self.view addSubview:weatherIcon];
    
    temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(Left_Margin, topMargin+Weather_Icon_Height, 0, 0)];
    temperatureLabel.text = @" ";
    temperatureLabel.font = [UIFont boldSystemFontOfSize:14];
    temperatureLabel.textColor = [UIColor whiteColor];
    temperatureLabel.backgroundColor = [UIColor clearColor];
    [temperatureLabel sizeToFit];
    [self.view addSubview:temperatureLabel];
    
    weatherLabel = [[UILabel alloc] initWithFrame:CGRectMake(Left_Margin, topMargin+Weather_Icon_Height+temperatureLabel.height + Padding, 0, 0)];
    weatherLabel.text = @" ";
    weatherLabel.font = [UIFont systemFontOfSize:12];
    weatherLabel.textColor = [UIColor whiteColor];
    weatherLabel.backgroundColor = [UIColor clearColor];
    [weatherLabel sizeToFit];
    [self.view addSubview:weatherLabel];
    
    dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(Left_Margin,  topMargin+Weather_Icon_Height+temperatureLabel.height +weatherLabel.height+ 2*Padding, 0, 0)];
    dateLabel.text = @" ";
    dateLabel.font = [UIFont systemFontOfSize:12];
    dateLabel.textColor = [UIColor whiteColor];
    dateLabel.backgroundColor = [UIColor clearColor];
    [dateLabel sizeToFit];
    [self.view addSubview:dateLabel];
}

- (void)openWeather {
    JDOConvenienceItemController *controller = nil;
    controller = [[JDOConvenienceItemController alloc] initWithService:CONVENIENCE_SERVICE params:@{@"channelid":@"21"} title:@"烟台天气"];
    controller.deletetitle = NO;
    JDOCenterViewController *centerController = (JDOCenterViewController *)[[SharedAppDelegate deckController] centerController];

    [centerController pushViewController:controller animated:YES];
    [self.viewDeckController closeLeftViewAnimated:true];
}

- (void)viewDidLoad{
    [super viewDidLoad];
#warning 天气增加"更新时间"字段,提供两个按钮分别显示预报和详情,预报可以用Flip+Scrollview
#warning 若客户端直接访问天气webservice有问题，可以切换成在服务器端实现
    [self updateWeather];
    [self updateCalendar];
}

- (void) updateWeather {
    // 天气信息最小刷新间隔
    double lastUpdateTime = [[NSUserDefaults standardUserDefaults] doubleForKey:Weather_Update_Time];
    if (lastUpdateTime == 0 || [[NSDate date] timeIntervalSince1970] - lastUpdateTime > Weather_Update_Interval){
        [self loadWeatherFromNetwork];
    }else{
        BOOL hasCache = [self readWeatherFromLocalCache];
        if (!hasCache) {    // 若缓存被清空,则继续从网络获取
            [self loadWeatherFromNetwork];
        }
    }
}

// 加载天气信息
- (void) loadWeatherFromNetwork{
    JDOXmlClient *xmlClient = [[JDOXmlClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://webservice.webxml.com.cn"]];
    [xmlClient getXMLByServiceName:@"/WebServices/WeatherWS.asmx/getWeather" params:@{@"theCityCode":@"909",@"theUserID":@""} success:^(NSXMLParser *xmlParser) {
        _weather = [[JDOWeather alloc] initWithParser:xmlParser];
        if([_weather parse]){
            if(_weather.success){
                [self refreshWeather];
                [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970] forKey:Weather_Update_Time];
            }else{
                NSLog(@"天气webservice超出访问次数限制,从本地缓存获取");
                [self readWeatherFromLocalCache];
            }
        }else{
            NSLog(@"解析天气XML失败");
        }
    } failure:^(NSString *errorStr) {
        NSLog(@"%@",errorStr);
        [self readWeatherFromLocalCache];
    }];
}

// 本地xml仅供测试用
//- (void) readWeatherFromXML{
//    NSString *xmlPath = [[NSBundle mainBundle] pathForResource:@"weather" ofType:@"xml"];
//    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
//    NSXMLParser *_parser = [[NSXMLParser alloc] initWithData:xmlData];
//    _weather = [[JDOWeather alloc] initWithParser:_parser];
//    if([_weather parse]){
//        [self refreshWeather];
//    }
//}

- (BOOL) readWeatherFromLocalCache{
    if((_weather = [JDOWeather readFromFile])){
        [self refreshWeather];
        return true;
    }else{
#warning 无法获取时应该可以点击重试
        temperatureLabel.text = @"无法获取天气信息";
        [temperatureLabel sizeToFit];
        return false;
    }
}

- (void) refreshWeather{
    @try {  // 防止webservice接口变动造成异常
#warning 天气预报的第一天并不一定是当天，是否要加判断？
        _forcast = [_weather.forecast objectAtIndex:0];
        cityLabel.text = _weather.city;
        [cityLabel sizeToFit];
        UIImage *weatherImg = [UIImage imageNamed:[_forcast.weatherDetail stringByAppendingPathExtension:@"png"] ];
        if( weatherImg ){
            weatherIcon.image = weatherImg;
        }else{  // xx转xx的情况,用前者的天气图标
            NSString *firstWeather = [[_forcast.weatherDetail componentsSeparatedByString:@"转"] objectAtIndex:0];
            //xx到xx的情况，使用后者的天气图标
            NSString *secondWeather = [[firstWeather componentsSeparatedByString:@"到"] objectAtIndex:1];
            weatherImg = [UIImage imageNamed:[secondWeather stringByAppendingPathExtension:@"png"] ];
            if( weatherImg ){   // 没有对应的天气图标则使用默认.png
                weatherIcon.image = weatherImg;
            }
        }
        temperatureLabel.text = _forcast.temperature;
        [temperatureLabel sizeToFit];
        
        // 天气状况部分
        weatherLabel.text = [NSString stringWithFormat:@"%@ %@",_forcast.weatherDetail,_forcast.wind];
        float weatherLabelWidth = [weatherLabel.text sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(999, 15)].width;
        if(weatherLabelWidth > 140){    // 若天气情况太长显示不开,则不显示风力部分的后半部分
            NSArray *windComponents = [_forcast.wind componentsSeparatedByString:@"转"];
            weatherLabel.text = [NSString stringWithFormat:@"%@ %@",_forcast.weatherDetail,[windComponents objectAtIndex:0]];
            weatherLabelWidth = [weatherLabel.text sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(999, 15)].width;
            if (weatherLabelWidth > 140){   // 若还太长,则不显示风力部分
                weatherLabel.text = _forcast.weatherDetail;
            }
        }
        [weatherLabel sizeToFit];
    }
    @catch (NSException *exception) {
        NSLog(@"刷新天气控件异常:%@,%@",exception.name,exception.reason);
        temperatureLabel.text = @"无法获取天气信息";
        [temperatureLabel sizeToFit];
    }
    @finally {
        
    }

}

- (void) updateCalendar{
    // 计算星期几和农历
    NSCalendar *calendar = [NSCalendar currentCalendar]; //gregorian GMT+8
    NSDateComponents *dateComp = [calendar components:NSYearCalendarUnit|NSWeekdayCalendarUnit fromDate:[NSDate date]];
    
    NSString *weekDay = [weekDayNames objectAtIndex:dateComp.weekday-1]; //weekday从1开始，在gregorian历法中代表星期天
    
//    NSString *dateString = [NSString stringWithFormat:@"%d年%@",dateComp.year,_forcast.date];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
//    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];    //Asia/Shanghai
//    NSDate *aDate = [dateFormatter dateFromString:dateString];
    // 用本地时间替换天气预报中获取的时间,因为:1 天气服务可能失效, 2 天气服务不能实时更新会导致日期显示不正确
    NSDate *aDate = [NSDate date];
    
    dateComp = [calendar components:NSMonthCalendarUnit|NSDayCalendarUnit fromDate:aDate];
    NSString *monthDay = [NSString stringWithFormat:@"%d/%d",dateComp.month,dateComp.day]; //显示的日期样式 mm/dd
    
    dateLabel.text = [NSString stringWithFormat:@"%@ %@ 农历%@",monthDay,weekDay,[[JDOCommonUtil getChineseCalendarWithDate:aDate] substringFromIndex:2] ]; //阴历不显示年份
    [dateLabel sizeToFit];
}


- (void)viewWillAppear:(BOOL)animated{
    //    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:false scrollPosition:UITableViewScrollPositionNone];
}

- (void) transitionToAlpha:(float) alpha Scale:(float) scale{
    self.blackMask.alpha = alpha;
    self.view.transform = CGAffineTransformMakeScale(scale, scale);
}

- (void)viewDidUnload{
    [super viewDidUnload];
    self.tableView = nil;
    self.blackMask = nil;
    self.weather = nil;
    self.forcast = nil;
    cityLabel = nil;
    weatherIcon = nil;
    temperatureLabel = nil;
    weatherLabel = nil;
    dateLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return MenuItemCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MenuItem";
    
    UIImageView *imageView;
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(Left_Margin, 0, 115, Menu_Cell_Height)];
        [imageView setTag:Menu_Image_Tag];
        [cell.contentView addSubview:imageView];
    }
    
    imageView = (UIImageView *)[cell viewWithTag:Menu_Image_Tag];
    if(indexPath.row == lastSelectedRow){
        imageView.image = [UIImage imageNamed:[iconSelectedNames objectAtIndex:indexPath.row]];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_row_selected.png"]];
        //        cell.textLabel.textColor = [UIColor colorWithRed:87.0/255.0 green:169.0/255.0 blue:237.0/255.0 alpha:1.0];
    }else{
        imageView.image = [UIImage imageNamed:[iconNames objectAtIndex:indexPath.row]];
        cell.backgroundView = nil;
        //        cell.textLabel.textColor = [UIColor whiteColor];
    }
    //    cell.textLabel.text = [iconTitles objectAtIndex:indexPath.row];
    
    return cell;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return 50.0;
//}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if( indexPath.row == lastSelectedRow){
        [self.viewDeckController closeLeftViewAnimated:true];
        return ;
    }
//    UITableViewCell *cell  = [tableView cellForRowAtIndexPath:indexPath];
//    cell.imageView.image = [UIImage imageNamed:[iconSelectedNames objectAtIndex:indexPath.row]];
//    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_row_selected.png"]];
//    if( lastSelectedRow != -1){
//        UITableViewCell *lastSelectedCell  = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:lastSelectedRow inSection:0]];
//        lastSelectedCell.imageView.image = [UIImage imageNamed:[iconNames objectAtIndex:lastSelectedRow]];
//        lastSelectedCell.backgroundView = nil;
//    }
    lastSelectedRow = indexPath.row;
    [tableView reloadData];
    
    // 使用slide动画关闭左菜单
//    if ([self.viewDeckController.centerController isKindOfClass:[JDOCenterViewController class]]) {
//        JDOCenterViewController *centerController = (JDOCenterViewController *)self.viewDeckController.centerController;
//        [centerController setRootViewControllerType:indexPath.row];
//    }
//    [self.viewDeckController closeLeftViewAnimated:true];
    
    // 使用Bouncing动画关闭左菜单
    [self.viewDeckController closeSideView:IIViewDeckLeftSide bounceOffset:320-self.viewDeckController.leftSize+30 bounced:^(IIViewDeckController *controller) {
        if ([self.viewDeckController.centerController isKindOfClass:[JDOCenterViewController class]]) {
            JDOCenterViewController *centerController = (JDOCenterViewController *)self.viewDeckController.centerController;
            [centerController setRootViewControllerType:indexPath.row];
        }
    } completion:^(IIViewDeckController *controller, BOOL success) {
        
    }];
    
}

@end
