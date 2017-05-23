//
//  NSObject+Constraint.m
//  ExcellentDataBase
//
//  Created by 王望 on 2017/5/22.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import "NSObject+Constraint.h"
#import <objc/runtime.h>
#include <regex.h>

#pragma mark - C Base End -
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

#pragma mark - Stack -
void stack_push(stack_pointer *top, NSString * const sql, NSString * const table_name){
    if (!sql) return;
    char *sql_chars = (char *)sql.UTF8String;
    char *table_names = (char *)table_name.UTF8String;
    stack_pointer node = malloc(sizeof(stack_pointer));
    if (!node) return;
    node->table.sql = sql_chars;
    node->table.table_name = table_names;
    if (!top) {
        node->next = NULL;
        *top = node;
    }else{
        node->next = *top;
        *top = node;
    }
}

struct stack_table stack_pop(stack_pointer *top){
    stack_pointer temp = *top;
    if (!temp) {
        struct stack_table null_table = {NULL,NULL};
        return null_table;
    }
    struct stack_table table_value = temp->table;
    *top = temp->next;
    free(temp);
    return table_value;
}

stack_pointer stack_query(stack_pointer top ,const char *table_name){
    stack_pointer query_point;
    while ((query_point = top) != NULL) {///O(n)
        if (table_name == query_point->table.table_name) {
            return query_point;
        }
    }
    return NULL;
}


@implementation NSObject (Constraint)

unsigned long location(NSMutableString *const sql,NSString * const col){
    if (col != nil) {/// 根据col确定需要插入的位置
        NSString *regex = col ;
        NSRange range = [sql rangeOfString:regex options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            return range.location + range.length;
        }
    }else{/// 末尾插入
        return sql.length - 2;
    }
    return 0;
}

#define CALL_ORIGIN NSLog(@"Origin: [%@]", [[[[NSThread callStackSymbols] objectAtIndex:1] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] objectAtIndex:1])
#define MAX_CONSTRAINTS_SIZE 6
- (NSObject *(^)(int constraint,NSMutableString *sql, NSString *others))constraint{
    
    NSObject *(^method)(int constraint,NSMutableString *sql, NSString *others) = ^NSObject *(int constraint,NSMutableString *sql, NSString *others){
        CALL_ORIGIN;
        NSString *col = @"sub";
        NSLog(@"%@ , %@",self ,NSStringFromSelector(_cmd));
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
        NSInteger index = location(sql, col);
        [sql insertString:sql_constraints atIndex:index];
        if (!others) {
            return self;
        }
        index = location(sql, sql_constraints);
        [sql insertString:[NSString stringWithFormat:@" %@",others] atIndex:index];
        return self;
    };
    return method;
}

@end
