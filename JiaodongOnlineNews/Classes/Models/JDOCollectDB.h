//
//  JDOCollectDB.h
//  JiaodongOnlineNews
//收藏辅助类，使用时通过JDOCollectDBDelegate来设置要操作的表名，
//因为收藏都是通过关键字id进行查找，所以在model类必须包含id属性
//JDOCollectDB根据JDOCollectDBDelegate两个方法返回的字段在initWithDelegate中进行建表
//  Created by 陈鹏 on 13-7-25.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"
#import "JDOToolbarModel.h"


@interface JDOCollectDB : NSObject{
    	    sqlite3 *db; //声明一个sqlite3数据库
}
@property (nonatomic,copy) NSString *tableName;
@property (nonatomic,strong) NSArray *columns;
-(BOOL)save:(NSObject*)obj;
-(BOOL)deleteById:(NSString*)idValue;
-(NSArray*)selectByModelClassString:(NSString*)modelClassString;
-(BOOL)isExistById:(NSString*)idValue;
@end
