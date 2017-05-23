//
//  NSObject+Constraint.h
//  ExcellentDataBase
//
//  Created by 王望 on 2017/5/22.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import <Foundation/Foundation.h>

#if DEBUG
#define bool_log(desc,bool) NSLog(@""desc"%@",bool==YES?@"YES":@"NO")
#endif

@class EDSqlCreateBridge,EDSqlInsertBridge;
typedef void(^ErrorHandle)(NSArray<NSError *>*);
typedef void(^EDCreateHandle)(EDSqlCreateBridge *sqler);
typedef void(^EDInsertHandle)(EDSqlInsertBridge *sqler);

#pragma mark - Stack -
struct stack_table {
    char *sql;
    char *table_name;
};
typedef struct sql_stack* stack_pointer;
typedef struct sql_stack {
    struct stack_table table;
    stack_pointer next;
}SqlStack;

void stack_push(stack_pointer *top, NSString * const sql, NSString * const table_name);
struct stack_table stack_pop(stack_pointer *top);
stack_pointer stack_query(stack_pointer top ,const char *table_name);

#pragma mark - C Base End -
void c_base_end(char *sql);

///https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html


typedef enum : NSUInteger {///这里为什么没有用移位操作，是因为8位用来移位只能表示8个有效数字，但是这里类型明显大于8。
    EDEncodeTypeMask    = 0xff,/// 掩码
    EDEncodeTypeUnknown = 0,
    EDEncodeTypeChar    = 1,
    EDEncodeTypeInt     = 2,
    EDEncodeTypeShort   = 3,
    EDEncodeTypeInt32   = 4,
    EDEncodeTypeInt64   = 5,
    EDEncodeTypeUChar   = 6,
    EDEncodeTypeUInt    = 7,
    EDEncodeTypeUShort  = 8,
    EDEncodeTypeUInt32  = 9,
    EDEncodeTypeUInt64  = 10,
    EDEncodeTypeFloat   = 11,
    EDEncodeTypeDouble  = 12,
    EDEncodeTypeBool    = 13,
    EDEncodeTypeVoid    = 14,
    EDEncodeTypeChars   = 15,
    EDEncodeTypeObject  = 16,
    EDEncodeTypePointer = 17,
    EDEncodeTypeStruct  = 18
} EDEncodingType;

EDEncodingType EDEncodeTheType(char const *value);

/// 用于限制加入表的数据的类型
typedef enum sql_constraints:int{
    EConstraintsNone       = 1 << 0,
    EConstraintsNotNull    = 1 << 1,
    EConstraintsUnique     = 1 << 2,
    EConstraintsPrimaryKey = 1 << 3,
    EConstraintsCheck      = 1 << 4,
    EConstraintsDefault    = 1 << 5
}EDSQLConstraints;

@interface NSObject (Constraint)

- (NSObject *(^)(int constraint,NSMutableString *sql, NSString *others))constraint;

@end
