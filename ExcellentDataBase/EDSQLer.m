//
//  EDSQLer.m
//  新成都范儿
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 dev@huaxi100.com. All rights reserved.
//

#import "EDSQLer.h"
typedef enum e_SqlAppend{
    ESqlAppendAppend,/// 添加类型为添加列
    ESqlAppendConstraint///添加约束
}ESqlAppendType;

static SQLStatement localc_sql_state;

@interface EDSqlBridge()

@property (nonatomic, assign)ESqlAppendType e_append_type;

@end

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

#pragma mark - Private -
- (void)append_for_create:(NSString *)value1 aValue2:(NSString *)value2{
    NSString *colum_sql = [NSString stringWithFormat:@"%@ %@,",value1,value2];
    NSInteger index = self.sql_statements.length - 1;
    [self.sql_statements insertString:colum_sql atIndex:index];
}

- (void)append_for_insert:(NSString *)value1 aValue2:(NSString *)value2{
    NSString *regex = @"\\)\\s+" ;
    NSRange range = [self.sql_statements rangeOfString:regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        [self.sql_statements insertString:[NSString stringWithFormat:@"%@,",value1] atIndex:range.location];
    }
    [self.sql_statements insertString:[NSString stringWithFormat:@"'%@',",value2] atIndex:self.sql_statements.length - 1];
}

- (void)allin_for_insert:(NSArray *)contents{
    if (SQLStatementInsert != localc_sql_state) {
        return;
    }
    NSString *delete_regex = @"\\(\\)\\B\\s" ;
    NSRange range = [self.sql_statements rangeOfString:delete_regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        [self.sql_statements deleteCharactersInRange:range];
    }
    for (NSString *value in contents) {
        [self.sql_statements insertString:[NSString stringWithFormat:@"'%@',",value] atIndex:self.sql_statements.length - 1];
    }
}

#pragma mark - Public -
- (EDSqlBridge *(^)(NSString *, BOOL))create{
    self.sql_statements = nil;
    self.e_append_type = ESqlAppendAppend;
    localc_sql_state = self.sql_state;
    EDSqlBridge*(^method)(NSString *name, BOOL ifnotExists) = ^ EDSqlBridge* (NSString *name, BOOL ifnotExists){
        self->_table_name = [name mutableCopy];
        self.ifnotExists = ifnotExists;
        switch (localc_sql_state) {
            case SQLStatementCreate:
            {
                NSString *create_table_sql = [NSString stringWithFormat:@"CREATE TABLE %@ %@()",NO == ifnotExists ? @"IF NOT EXISTS" : @"",name];
                self.sql_statements = [create_table_sql mutableCopy];
            }
                break;
            case SQLStatementInsert:
            {
                NSString *create_table_sql = [NSString stringWithFormat:@"INSERT INTO %@ () VALUES ()",name];
                self.sql_statements = [create_table_sql mutableCopy];
            }
                break;
            default:break;
        }
        return self;
    };
    return method;
}

- (EDSqlBridge *(^)(NSString *value1,NSString *value2))append{
    /// (id integer PRIMARY KEY ,discoverData blob NOT NULL )
    if (!self.sql_statements) {
        NSAssert(NO, @"Sql statement is empty, Please call \"create\" method before");
    }
    self.e_append_type = ESqlAppendAppend;
    EDSqlBridge *(^method)(NSString *value1,NSString *value2) = ^EDSqlBridge *(NSString *value1, NSString *value2){
        switch (localc_sql_state) {
            case SQLStatementCreate:[self append_for_create:value1 aValue2:value2];break;
            case SQLStatementInsert:[self append_for_insert:value1 aValue2:value2];break;
            default:break;
        }
        return self;
    };
    return method;
}

#define MAX_CONSTRAINTS_SIZE 6
- (EDSqlBridge *(^)(int constraint, NSString *others,...))constraint{
    
    return ^EDSqlBridge *(int constraint, NSString *others,...){
        if (ESqlAppendConstraint == self.e_append_type) {/// 防止在约束后面连续添加约束
            return self;
        }
        NSMutableString *sql_constraints = [NSMutableString string];
        int enum_constraint[MAX_CONSTRAINTS_SIZE] = {
            EConstraintsNone,
            EConstraintsNotNull,
            EConstraintsUnique,
            EConstraintsPrimaryKey,
            EConstraintsCheck,
            EConstraintsDefault
        };
        for (int i = 0; i < MAX_CONSTRAINTS_SIZE; i++) {
            if ((constraint & enum_constraint[i]) == enum_constraint[i]) {
                switch (enum_constraint[i]) {
                    case EConstraintsNone:break;
                    case EConstraintsNotNull:[sql_constraints appendString:@" NOT NULL"];break;
                    case EConstraintsUnique:[sql_constraints appendString:@" UNIQUE"];break;
                    case EConstraintsPrimaryKey:[sql_constraints appendString:@" PRIMARY KEY"];break;
                    case EConstraintsCheck:[sql_constraints appendString:@" CHECK"];break;
                    case EConstraintsDefault:[sql_constraints appendString:@" DEFAULT"];break;
                }
            }
        }
        NSInteger index = self.sql_statements.length - 2;
        [self.sql_statements insertString:sql_constraints atIndex:index];
        if (!others) {
            return self;
        }
        index = self.sql_statements.length - 2;
        [self.sql_statements insertString:[NSString stringWithFormat:@" %@",others] atIndex:index];
        va_list args;
        va_start(args, others);
        NSString *arg;
        if(others){
            while((arg = va_arg(args, NSString *))){
                index = self.sql_statements.length - 1;
                [self.sql_statements insertString:[NSString stringWithFormat:@" %@",arg] atIndex:index];
            }
        }
        va_end(args);
        self.e_append_type = ESqlAppendConstraint;
        return self;
    };
}

- (EDSqlBridge *(^)(NSArray *))allin {
    EDSqlBridge *(^method)(NSArray *contents) = ^EDSqlBridge *(NSArray *contents){
        [self allin_for_insert:contents];
        return self;
    };
    return method;
}

- (void)end{
    NSString *regex = @",\\)" ;
    NSRange range = [self.sql_statements rangeOfString:regex options:NSRegularExpressionSearch];
    if (range.location == NSNotFound) {
        return;
    }
    [self.sql_statements deleteCharactersInRange:NSMakeRange(range.location, 1)];
    [self end];
}


@end
