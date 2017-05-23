//
//  EDSQLer.h
//  新成都范儿
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 dev@huaxi100.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+Constraint.h"

@interface EDSqlBridge : NSObject

/** sql 语句 */
///
@property (nonatomic, copy)NSMutableString *sql_statements;

/** 表名称 */
@property (nonatomic, readonly, copy)NSString *table_name;

- (EDSqlBridge *(^)(NSString *,NSString *))end;


@end
