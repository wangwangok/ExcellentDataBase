//
//  EDBuild.h
//  新成都范儿
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 dev@huaxi100.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDSQLer.h"

typedef void(^ErrorHandle)(NSArray<NSError *>*);
typedef void(^EDCreateHandle)(EDSqlBridge *sqler);
typedef void(^EDInsertHandle)(EDSqlBridge *sqler);

@interface EDBuild : NSObject

/**
 * 创建一个DB，并创建table
 * para db_name: db名称
 * para create : 操作域
 * para handle : 错误回调操作
 */
- (EDBuild *(^)(NSString *db_name ,EDCreateHandle making))make_database;

/**
 * 数据的插入操作
 * para value:需要插入的数据，或者插入的数据和列名称。只支持array和dictionary，其他的是无效的。
 *            如果需要整行插入：传入array
 *            如果需要插入对应列的值：传入dictionary
 */
- (EDBuild *(^)(EDInsertHandle inserts))insert;

//- (EDBuild *(^)(NSString *db_name ,EDCreateHandle making))denite;
//
//- (EDBuild *(^)(NSString *db_name ,EDCreateHandle making))update;
//
//- (EDBuild *(^)(NSString *db_name ,EDCreateHandle making))equery;



- (BOOL)tableExists;

/**
 
 */
- (EDBuild *(^)(ErrorHandle))catchException;

@end
