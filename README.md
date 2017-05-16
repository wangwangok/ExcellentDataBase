![](https://img.shields.io/badge/build-passing-green.svg) ![](https://img.shields.io/badge/pod-0.0.1-orange.svg) ![](https://img.shields.io/badge/platform-iOS7.0%2B-green.svg) ![](https://img.shields.io/badge/dependency-FMDB-brightgreen.svg)
## 简介
``ExcellentDataBase``目的是使得数据库操作能够更加简单，支持链式的语法来创建表以及表的一些常规操作，同样通过链式的方法来捕获异常。

## 效果
```
EDBuild *builder = [EDBuild new];
builder.make_database(@"database",^(EDSqlCreateBridge *sqler){
    sqler.create(@"news",NO).append(@"id",@"int").constraint(EConstraintsPrimaryKey,nil).append(@"title",@"varchar(255)").constraint(EConstraintsNotNull,nil);
}).insert(^(EDSqlInsertBridge *sqler){
    sqler.create(@"news").append(@"id",@"101").append(@"title",@"Chunxi Road");
}).catchException(^(NSArray<NSError *> *errors){
    NSLog(@"%@",errors);
});
```
这里会创建一个名为__ database__的数据库，在``make_database``方法中通过链式的方式来创建一个表创建语句。同样在``insert``中通过链式的方式来创建一个表插入语句。总体上使用链式的方式来做数据的增删改查操作，以及最后的异常捕获操作。

## 使用
#### 建表
- 1.手动通过输入列名称和数据类型，以及对每个列名称的约束：

```
sqler.create(@"news",NO).append(@"id",@"int").constraint(EConstraintsPrimaryKey,nil).append(@"title",@"varchar(255)").constraint(EConstraintsNotNull,nil);
```
其中``constraint ``方法的两个参数是用来约束键（列名称）的，形如``EConstraintsPrimaryKey, EConstraintsNotNull ``同时，还可以为同一个键添加多个约束``EConstraintsPrimaryKey  | EConstraintsNotNull ``。第二个参数是给其值加约束，比如：``id < 1000``之类的约束，这是一个可变参数。

#### 插入
- 1.Key-Value方式插入数据：

```
sqler.create(@"news").append(@"id",@"101").append(@"title",@"Chunxi Road");
```
- 2.插入整行数据：

```
sqler.create(@"news").allin(@[@"104",@"Changan Street"]);
```
将一行数据按照顺序放入数组中。

- 3.传入一个模型数据：

```
EDModel *data = [EDModel new];
data.ID = @"108";
data.Title = @"ShuangQiaoZi";
sqler.create(@"news").input(data);
```
但是这里需要注意的是，如果数据库表中的列名称和系统命名有冲突的话，你需要调用方法:
```
@implementation EDModel
- (NSDictionary *)SystemKeywordsReplace{
    return @{@"ID":@"id",
            @"Title":@"title"};
}
@end
```
会根据该方法提供的key-value进行替换。

#### 删除

#### 修改

#### 查询
