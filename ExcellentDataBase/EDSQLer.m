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

@interface EDSQLer ()

@end

@implementation EDSQLer

- (EDSqlBridge *(^)(NSString *, BOOL))create{
    
    EDSqlBridge*(^method)(NSString *name, BOOL ifnotExists) = ^ EDSqlBridge* (NSString *name, BOOL ifnotExists){
        EDSqlBridge *bridge = EDSqlBridge.new;
        bridge.table_name = [name mutableCopy];
        bridge.sql_statements = nil;
        bridge.e_append_type = ESqlAppendAppend;
        self.bridge = bridge;
        localc_sql_state = self.sql_state;
        switch (localc_sql_state) {
            case SQLStatementCreate:
            {
                NSString *create_table_sql = [NSString stringWithFormat:@"CREATE TABLE %@ %@()",YES == ifnotExists ? @"IF NOT EXISTS" : @"",name];
                bridge.sql_statements = [create_table_sql mutableCopy];
            }
                break;
            case SQLStatementInsert:
            {
                NSString *create_table_sql = [NSString stringWithFormat:@"INSERT INTO %@",name];
                bridge.sql_statements = [create_table_sql mutableCopy];
            }
                break;
            default:
                break;
        }
        return bridge;
    };
    return method;
}

@end

@implementation EDSqlBridge

- (void)setSql_statements:(NSMutableString *)sql_statements{
    _sql_statements = [sql_statements mutableCopy];
}

- (void)setTable_name:(NSMutableString *)table_name{
    _table_name = [table_name mutableCopy];
}

#define MAX_CONSTRAINTS_SIZE 6
- (EDSqlBridge *(^)(NSString *value1,NSString *value2))append{
    /// (id integer PRIMARY KEY ,discoverData blob NOT NULL )
    if (!self.sql_statements) {
        NSAssert(NO, @"Sql statement is empty, Please call \"create\" method before");
    }
    self.e_append_type = ESqlAppendAppend;
    return ^ EDSqlBridge* (NSString *value1,NSString *value2){
        switch (localc_sql_state) {
            case SQLStatementCreate:{
                NSString *colum_sql = [NSString stringWithFormat:@"%@ %@,",value1,value2];
                NSInteger index = self.sql_statements.length - 1;
                [self.sql_statements insertString:colum_sql atIndex:index];
            }
                break;
            case SQLStatementInsert:{
                NSRegularExpression
            }
                break;
            default:
                break;
        }
        return self;
    };
}

- (EDSqlBridge *(^)(NSArray *))allin{
    EDSqlBridge *(^method)(NSArray *contents) = ^EDSqlBridge *(NSArray *contents){
        
        return self;
    };
    
    return method;
}

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
        NSInteger index = self.sql_statements.length - 1;
        [self.sql_statements insertString:sql_constraints atIndex:index];
        if (!others) {
            return self;
        }
        index = self.sql_statements.length - 1;
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



@end
