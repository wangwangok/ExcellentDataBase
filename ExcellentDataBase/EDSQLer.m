//
//  EDSQLer.m
//  新成都范儿
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 dev@huaxi100.com. All rights reserved.
//

#import "EDSQLer.h"
#include <string.h>
#include <regex.h>

void deleteCharactersInRange(char *sql ,NSRange range);
void c_base_end(char *sql){
    /// http://c.biancheng.net/cpp/html/1428.html
    const char *regex = ",\\)";
    regex_t reg;
    regmatch_t __p_match[1];
    size_t match_size = 1;
    regcomp(&reg, regex, REG_EXTENDED);
    int result = regexec(&reg, sql, match_size, __p_match, 0);
    if (REG_NOMATCH == result) {/// 匹配失败
        regfree(&reg);
        return;
    }else if (0 == result){///__p_match[0].rm_so ,__p_match[0].rm_eo
        deleteCharactersInRange(sql, NSMakeRange(__p_match[0].rm_so, 1));
        regfree(&reg);
        c_base_end(sql);
    }
}

void deleteCharactersInRange(char *sql ,NSRange range){
    int i,j;
    char *copy_sql = sql;
    NSRange delete_range = (range.location + range.length > strlen(sql)) ? NSMakeRange(range.location, strlen(sql) - range.location) : range;
    for (i = 0, j = 0; sql[i] != '\0'; i++){
        if (i < delete_range.location || i >= delete_range.location + delete_range.length ) {
            sql[j++] = sql[i];
        }
    }
    sql[j] = '\0';
    *sql = *copy_sql;
}

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
- (void)end:(NSMutableString *)sql theTableName:(NSString *)table_name{
    if (table_name) {
        _table_name = table_name;
    }
    /**
    NSString *regex = @",\\)";
    NSRange range = [sql rangeOfString:regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        [sql deleteCharactersInRange:NSMakeRange(range.location, 1)];
        [self end:sql theTableName:table_name];
    }
     */
    
}

- (EDSqlBridge *(^)(NSString *,NSString *))end{
#warning TODO: this is a error function
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


