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

@interface EDSqlBridge : NSObject

@property (nonatomic, copy)NSMutableString *sql_statements;

/**
 *
 * 在“create”方法之后调用，为create中创建的表添加列。
 * column_name :创建表时的每一列名称
 * data_type   :数据类型
 * constraints :用于配置每一行具体的约束和一些附加选项
 */
- (EDSqlBridge *(^)(NSString *column_name,NSString *data_type))append;

/**
 *
 * 它是可选的，在“append”方法之后调用，为append方法中添加的列添加其他约束
 * constraints :列约束，列约束可以是多个，调用时使用:EConstraintsNotNull | EConstraintsPrimaryKey
 * others      :其他附加语句，比如：Id_P int NOT NULL CHECK (Id_P>0),其中(Id_P>0)就属于others
 *
 */
- (EDSqlBridge *(^)(int constraint, NSString *others,...))constraint;

@end

@interface EDSQLer : NSObject

/**
 *
 * name        :表名
 * ifnotExists :是否是IF NOT EXISTS
 */
- (EDSqlBridge *(^)(NSString *name,BOOL ifnotExists))create;

@end
