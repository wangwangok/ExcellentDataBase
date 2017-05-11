//
//  EDSQLer.h
//  新成都范儿
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 dev@huaxi100.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 用于限制加入表的数据的类型
typedef enum sql_constraints:int{
    EConstraintsNone       = 1 << 0,
    EConstraintsNotNull    = 1 << 1,
    EConstraintsUnique     = 1 << 2,
    EConstraintsPrimaryKey = 1 << 3,
    EConstraintsCheck      = 1 << 4,
    EConstraintsDefault    = 1 << 5
}EDSQLConstraints;

typedef enum : NSUInteger {
    SQLStatementCreate,
    SQLStatementInsert,
    SQLStatementDenite,
    SQLStatementUpdate,
    SQLStatementEquery
} SQLStatement;

@interface EDSqlBridge : NSObject

@property (nonatomic, copy)NSMutableString *sql_statements;

@property (nonatomic, copy)NSMutableString *table_name;

/**
 *
 * value1 :如果用于创建表时是每一列名称，如果用于插入数据是列名称
 * value2 :如果用于创建表时是数据类型，如果用于插入数据是列对应的值
 * constraints :用于配置每一行具体的约束和一些附加选项
 */
- (EDSqlBridge *(^)(NSString *value1,NSString *value2))append;

/**
 *
 * 它是可选的，在“append”方法之后调用，为append方法中添加的列添加其他约束
 * constraints :列约束，列约束可以是多个，调用时使用:EConstraintsNotNull | EConstraintsPrimaryKey
 * others      :其他附加语句，比如：Id_P int NOT NULL CHECK (Id_P>0),其中(Id_P>0)就属于others
 *
 */
- (EDSqlBridge *(^)(int constraint, NSString *others,...))constraint;

/**
 *
 * 一次性将所有数据放入数据库。
 * value1 :如果用于创建表时是每一列名称，如果用于插入数据是列名称
 * value2 :如果用于创建表时是数据类型，如果用于插入数据是列对应的值
 * constraints :用于配置每一行具体的约束和一些附加选项
 */
- (EDSqlBridge *(^)(NSArray *contents))allin;

@end

@interface EDSQLer : NSObject

@property (nonatomic,assign)SQLStatement sql_state;

@property (nonatomic,strong)EDSqlBridge *bridge;

/**
 *
 * name        :表名
 * ifnotExists :是否是IF NOT EXISTS
 */
- (EDSqlBridge *(^)(NSString *name,BOOL ifnotExists))create;

@end
