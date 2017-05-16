# ExcellentDataBase
![](https://img.shields.io/badge/build-passing-green.svg) ![](https://img.shields.io/badge/pod-0.0.1-orange.svg) ![](https://img.shields.io/badge/platform-iOS7.0%2B-green.svg) ![](https://img.shields.io/badge/dependency-FMDB-brightgreen.svg)
## 简介
``ExcellentDataBase``目的是使得数据库操作能够更加简单，支持链式的语法来创建表以及表的一些常规操作，同样通过链式的方法来捕获异常。

## 效果
- 1.直接手动添加相关数据
```
EDBuild *builder = [EDBuild new];
builder.make_database(@"database",^(EDSqlBridge *sqler){
    sqler.create(@"news",YES).append(@"id",@"int").constraint(EConstraintsPrimaryKey,nil).append(@"title",@"varchar(255)").constraint(EConstraintsNotNull,nil);
}).insert(^(EDSqlBridge *sqler){
    sqler.create(@"news",YES).append(@"id",@"100").append(@"title",@"zhendeshuai");
}).catchException(^(NSArray<NSError *> *errors){
    NSLog(@"%@",errors);
});
```
这里会创建一个名为__ database__的数据库，在``make_database``方法中通过链式的方式来创建一个表创建语句。同样在``insert``中通过链式的方式来创建一个表插入语句。总体上使用链式的方式来做数据的增删改查操作，以及最后的异常捕获操作。

- 2.传入一个数据模型，自动添加到数据库

## 使用
我并没有使用单例来作为操作本地数据库的对象，直接通过``EDBuild *builder = [EDBuild new];``，以下涉及到的操作都是在该对象上进行操作！
#### 建表
在建表之前必须要先创建一个db，而且在每次创建表之前会查看该表是否被创建。我们需要做的就是传入db的名称，表名，存在的列和每一列对应的数据类型。同时在创建表的时候支持对列添加约束（EDSQLConstraints），具体方法如下：
```
builder.make_database(@"database",^(EDSqlBridge *sqler){
    sqler.create(@"news",YES).append(@"id",@"int").constraint(EConstraintsPrimaryKey,nil).append(@"title",@"varchar(255)").constraint(EConstraintsNotNull,nil);
}).catchException(^(NSArray<NSError *> *errors){
    NSLog(@"%@",errors);
});
```
该例中最后的异常捕获是可选的，这完全取决于您自己。在例子中为每一列添加约束的``constraint``方法有一个``EDSQLConstraints``

#### 插入

#### 删除

#### 修改

#### 查询
