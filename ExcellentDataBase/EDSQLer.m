//
//  EDSQLer.m
//  EDSQLer
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import "EDSQLer.h"
#import "NSObject+Constraint.h"

@implementation EDSqlBridge
@synthesize table_name = _table_name;

+ (BOOL)accessInstanceVariablesDirectly{
    return NO;
}

- (void)setSql_statements:(NSMutableString *)sql_statements{
    _sql_statements = [sql_statements mutableCopy];
}

- (void)setTable_name:(NSMutableString *)table_name{
    _table_name = [table_name mutableCopy];
}

#pragma mark - Public -
- (EDSqlBridge *(^)(NSString *,NSString *))end{
    return ^EDSqlBridge *(NSString *sql,NSString * table_name){
        if (!self.table_name) {
            _table_name = table_name;
        }
        char *c_sql = (char *)sql.UTF8String;
        c_base_end(c_sql);
        self.sql_statements = [NSMutableString stringWithUTF8String:c_sql];
        return self;
    };
}

@end


