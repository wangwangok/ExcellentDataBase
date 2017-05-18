//
//  EDSQLer.m
//  新成都范儿
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 dev@huaxi100.com. All rights reserved.
//

#import "EDSQLer.h"
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
#warning TODO: this is a error function
    return ^EDSqlBridge *(NSString *sql,NSString * table_name){
        if (!self.table_name) {
            _table_name = table_name;
        }
        NSString *regex = @",\\)";
        self.sql_statements = [sql mutableCopy];
        NSRange range = [self.sql_statements rangeOfString:regex options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            [self.sql_statements deleteCharactersInRange:NSMakeRange(range.location, 1)];
            self.end(self.sql_statements,table_name);
        }
        return self;
    };
}

@end
