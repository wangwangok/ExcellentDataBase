//
//  EDSqlStatementsBridge.m
//  ExcellentDataBase
//
//  Created by 王望 on 2017/5/16.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import "EDSqlStatementsBridge.h"
#import <objc/runtime.h>

#define SQL_NULL if (!self.sql_statements) {\
                NSAssert(NO, @"Sql statement is empty, Please call \"create\" method before");\
              }

typedef enum e_SqlAppend{
    ESqlAppendAppend,/// 添加类型为添加列
    ESqlAppendConstraint///添加约束
}ESqlAppendType;

@interface EDSqlCreateBridge ()

@property (nonatomic, assign) ESqlAppendType e_append_type;

@end

@implementation EDSqlCreateBridge : EDSqlBridge
@synthesize table_name = _table_name;

#pragma mark - Private -
- (void)append_for_create:(NSString *)value1 aValue2:(NSString *)value2{
    NSString *colum_sql = [NSString stringWithFormat:@"%@ %@,",value1,value2];
    NSInteger index = self.sql_statements.length - 1;
    [self.sql_statements insertString:colum_sql atIndex:index];
}
#pragma mark - Public -
- (EDSqlCreateBridge *(^)(NSString *, BOOL))create{
    self.sql_statements = nil;
    self.e_append_type = ESqlAppendAppend;
    EDSqlCreateBridge*(^method)(NSString *name, BOOL ifnotExists) = ^ EDSqlCreateBridge* (NSString *name, BOOL ifnotExists){
        self->_table_name = [name mutableCopy];
        self.ifnotExists = ifnotExists;
        NSString *create_table_sql = [NSString stringWithFormat:@"CREATE TABLE %@ %@()",NO == ifnotExists ? @"IF NOT EXISTS" : @"",name];
        self.sql_statements = [create_table_sql mutableCopy];
        return self;
    };
    return method;
}

- (EDSqlCreateBridge *(^)(NSString *value1,NSString *value2))append{
    if (!self.sql_statements) {
        NSAssert(NO, @"Sql statement is empty, Please call \"create\" method before");
    }
    self.e_append_type = ESqlAppendAppend;
    EDSqlCreateBridge *(^method)(NSString *value1,NSString *value2) = ^EDSqlCreateBridge *(NSString *value1, NSString *value2){
        [self append_for_create:value1 aValue2:value2];
        return self;
    };
    return method;
}

#define MAX_CONSTRAINTS_SIZE 6
- (EDSqlCreateBridge *(^)(int constraint, NSString *others,...))constraint{
    
    return ^EDSqlCreateBridge *(int constraint, NSString *others,...){
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

@end

typedef enum {
    EDInsertCallNone,EDInsertCallAppend,EDInsertCallAllIn,
} EDInsertCallType;

@interface EDSqlInsertBridge ()

@property (nonatomic ,assign)EDInsertCallType _called_type;

@end

@implementation EDSqlInsertBridge : EDSqlBridge

- (void)allin_for_insert:(NSArray *)contents{
    if (self._called_type == EDInsertCallAppend) {
        return ;
    }
    self._called_type = EDInsertCallAllIn;
    NSString *delete_regex = @"\\(\\)\\B\\s" ;
    NSRange range = [self.sql_statements rangeOfString:delete_regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        [self.sql_statements deleteCharactersInRange:range];
    }
    for (NSString *value in contents) {
        [self.sql_statements insertString:[NSString stringWithFormat:@"'%@',",value] atIndex:self.sql_statements.length - 1];
    }
}

- (void)append_for_insert:(NSString *)value1 aValue2:(NSString *)value2{
    if (self._called_type == EDInsertCallAllIn) {
        return ;
    }
    self._called_type = EDInsertCallAppend;
    NSString *regex = @"\\)\\s+" ;
    NSRange range = [self.sql_statements rangeOfString:regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        [self.sql_statements insertString:[NSString stringWithFormat:@"%@,",value1] atIndex:range.location];
    }
    [self.sql_statements insertString:[NSString stringWithFormat:@"'%@',",value2] atIndex:self.sql_statements.length - 1];
}

- (void)input_for_insert:(id)source_data{
    NSDictionary *replace_dic;
    if ([source_data respondsToSelector:@selector(SystemKeywordsReplace)]) {
        replace_dic = [source_data SystemKeywordsReplace];
    }
    Class clazz = [source_data class];
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(clazz, &count);///class_copyIvarList 成员变量
    for (unsigned int i = 0; i<count; i++) {/// 获取数据对应的属性名称
        NSString *property = [NSString stringWithUTF8String:property_getName(*(properties + i))];
        /// 过滤掉系统自动添加的元素
        if ([property isEqualToString:@"hash"]
            || [property isEqualToString:@"superclass"]
            || [property isEqualToString:@"description"]
            || [property isEqualToString:@"debugDescription"]) {
            continue;
        }
        NSString *value = [NSString stringWithFormat:@"%@",[source_data valueForKey:property]];
        NSString *value_utf8;
        if ([value respondsToSelector:@selector(stringByReplacingPercentEscapesUsingEncoding:)]) {
            value_utf8 = [NSMutableString stringWithString:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        if (replace_dic && [replace_dic.allKeys containsObject:property]) {/// 进行关键字替换
            property = [replace_dic objectForKey:property];
        }
        if (value_utf8) {/// 这里会存在，属性存在的key-value在数据库表中没有改字段。
            self.append(property,value_utf8);
        }
    }
    free(properties);
}


#pragma mark - Public -
- (EDSqlInsertBridge *(^)(NSString *))create{
    self._called_type = EDInsertCallNone;
    self.sql_statements = nil;
    EDSqlInsertBridge*(^method)(NSString *name) = ^ EDSqlInsertBridge* (NSString *name){
        NSString *create_table_sql = [NSString stringWithFormat:@"INSERT INTO %@ () VALUES ()",name];
        self.sql_statements = [create_table_sql mutableCopy];
        return self;
    };
    return method;
}

- (EDSqlInsertBridge *(^)(NSString *value1,NSString *value2))append{
    SQL_NULL;
    EDSqlInsertBridge *(^method)(NSString *value1,NSString *value2) = ^EDSqlInsertBridge *(NSString *value1, NSString *value2){
        [self append_for_insert:value1 aValue2:value2];
        return self;
    };
    return method;
}

- (EDSqlInsertBridge *(^)(NSArray *))allin {
    SQL_NULL;
    EDSqlInsertBridge *(^method)(NSArray *contents) = ^EDSqlInsertBridge *(NSArray *contents){
        [self allin_for_insert:contents];
        return self;
    };
    return method;
}

- (EDSqlInsertBridge *(^)(id))input {
    SQL_NULL;
    EDSqlInsertBridge *(^method)(id source_data) = ^EDSqlInsertBridge *(id source_data){
        [self input_for_insert:source_data];
        return self;
    };
    return method;
}

@end

@implementation EDSqlDeleteBridge : EDSqlBridge

@end

@implementation EDSqlUpdateBridge : EDSqlBridge

@end

@implementation EDSqlQueryBridge : EDSqlBridge

@end

@implementation NSObject (EDSqlSystemKeyword)

- (NSDictionary *)SystemKeywordsReplace{
    return nil;
}

@end
