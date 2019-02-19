//
//  EDSQLer.h
//  EDSQLer
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDSqlBridge : NSObject

/** sql 语句 */
///
@property (nonatomic, copy)NSMutableString *sql_statements;

/** 表名称 */
@property (nonatomic, readonly, copy)NSString *table_name;

- (EDSqlBridge *(^)(NSString *,NSString *))end;


@end
