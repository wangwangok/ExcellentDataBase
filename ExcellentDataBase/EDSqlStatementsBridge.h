//
//  EDSqlCreateBridge.h
//  ExcellentDataBase
//
//  Created by 王望 on 2017/5/16.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import "EDSQLer.h"

/// 用于限制加入表的数据的类型
typedef enum sql_constraints:int{
    EConstraintsNone       = 1 << 0,
    EConstraintsNotNull    = 1 << 1,
    EConstraintsUnique     = 1 << 2,
    EConstraintsPrimaryKey = 1 << 3,
    EConstraintsCheck      = 1 << 4,
    EConstraintsDefault    = 1 << 5
}EDSQLConstraints;


@interface EDSqlCreateBridge : EDSqlBridge

/** 是否删除原来的旧表重新创建新表 */
@property (nonatomic,assign)BOOL ifnotExists;

/**
 *
 * name        :表名
 * ifnotExists :是否删除原来的旧表重新创建新表
 */
- (EDSqlCreateBridge *(^)(NSString * name,BOOL ifnotExists))create;

/**
 *
 * value1 :如果用于创建表时是每一列名称，如果用于插入数据是列名称
 * value2 :如果用于创建表时是数据类型，如果用于插入数据是列对应的值
 * constraints :用于配置每一行具体的约束和一些附加选项
 */
- (EDSqlCreateBridge *(^)(NSString *value1,NSString *value2))append;

/**
 *
 * 它是可选的，在“append”方法之后调用，为append方法中添加的列添加其他约束
 * constraints :列约束，列约束可以是多个，调用时使用:EConstraintsNotNull | EConstraintsPrimaryKey
 * others      :其他附加语句，比如：Id_P int NOT NULL CHECK (Id_P>0),其中(Id_P>0)就属于others
 *
 */
- (EDSqlCreateBridge *(^)(int constraint, NSString *others,...))constraint;

@end

@interface EDSqlInsertBridge : EDSqlBridge


- (EDSqlInsertBridge *(^)(NSString * name))create;

- (EDSqlInsertBridge *(^)(NSString *value1,NSString *value2))append;

/**
 *
 * 一次性将所有数据放入数据库。
 * 将数据的一整行存入其中
 *
 */
- (EDSqlInsertBridge *(^)(NSArray *contents))allin;

- (EDSqlInsertBridge *(^)(id))input;

@end

@interface EDSqlDeleteBridge : EDSqlBridge

@end

@interface EDSqlUpdateBridge : EDSqlBridge

@end

@interface EDSqlQueryBridge : EDSqlBridge

@end

@interface NSObject (EDSqlSystemKeyword)

/**
 *
 * 用于替换数据库表和系统关键字存在冲突的情况
 * @{@"ID":@"id"}
 * id为系统关键字不能作为模型的属性名称，则将属性名称改为ID。所以在这种情况下就要传入上诉字典，这会在sql语句时将ID变为id。
 */
- (NSDictionary *)SystemKeywordsReplace;

@end
