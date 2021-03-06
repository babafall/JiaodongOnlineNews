//
//  JDOTopicModel.h
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-7-2.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//
#import "JDOToolbarModel.h"
#import "JDONewsModel.h"

@interface JDOPartyModel : NSObject <NSCoding,JDOToolbarModel>
@property (nonatomic,strong) NSString *id;
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *mpic;
@property (nonatomic,strong) NSString *summary;
@property (nonatomic,strong) NSString *modifytime;
@property (nonatomic,strong) NSString *pubtime;
@property (nonatomic,strong) NSString *active_starttime;
@property (nonatomic,strong) NSString *active_endtime;
@property (nonatomic,strong) NSString *active_address;
@property (nonatomic,strong) NSString *clicknum;

@property (nonatomic,strong) NSString *imageurl;

@property (nonatomic,strong) NSString *showMore;

- (id)initWithNewsModel:(JDONewsModel *)model;

@property (nonatomic,strong) NSString *tinyurl;

@end
