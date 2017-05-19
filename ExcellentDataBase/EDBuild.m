//
//  EDBuild.m
//  新成都范儿
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 dev@huaxi100.com. All rights reserved.
//

#import "EDBuild.h"
#import <FMDB/FMDB.h>

typedef enum ed_error_code:long{
    EDDataBaseOpenError = 1001000,
    EDCreateTableError  = 1001001,
    EDInsertDataError   = 1001002
}EDErrorCode;

#define EDErrorDomain @"ExcellentDataBaseErrorDomain"

#ifdef EDErrorDomain
static NSString *const EDDataBaseOpenErrorDescription = @"the database open failed";
static NSString *const EDCreateTableErrorDescription  = @"create table failed";
static NSString *const EDInsertDataErrorDescription   = @"insert data to table failed";
#endif

///SELECT count(*) FROM sqlite_master WHERE type='table' AND name='要查询的表名';
static NSString *const EDTableExistsSQL = @"select [sql] from sqlite_master where [type] = 'table' and lower(name) = ?";
#define EDTableDropSQL  @"DROP TABLE %@"

static const char *EDQueueName = "com.ExcellentDataBase.queue";

#define CREATE_DATABASE(build,db_name) if(self.db == nil){\
                                            NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];\
                                            NSString *path = [cachesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",db_name]];\
                                            NSLog(@"%@",path);\
                                            build.db = [FMDatabase databaseWithPath:path];\
                                        }\


#define CREATE_SQLER(sqler) if (!sqler) {\
                                sqler =EDSqlBridge.new;\
                            }\

@interface EDBuild ()
@property (nonatomic,strong) FMDatabase  *db;
@property (nonatomic,strong) EDSqlBridge *sqler;
@property (nonatomic,strong) NSMutableArray<NSError *> *errors;
@end

@implementation EDBuild

- (instancetype)init{
    self = [super init];
    if (self) {
        self.errors = [NSMutableArray array];
        CREATE_SQLER(self.sqler);
    }
    return self;
}

static dispatch_queue_t ed_database_queue() {
    static dispatch_queue_t ed_database_opration_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ed_database_opration_queue = dispatch_queue_create(EDQueueName, DISPATCH_QUEUE_CONCURRENT);
    });
    
    return ed_database_opration_queue;
}


#pragma mark - Public Method -
- (EDBuild *(^)(NSString *db_name ,EDCreateHandle making))make_database{
    self.sqler.sql_statements = nil;
    EDBuild *(^method)(NSString *db_name ,EDCreateHandle making) =^EDBuild *(NSString *db_name ,EDCreateHandle making){
        CREATE_DATABASE(self,db_name);
        EDSqlCreateBridge *create = EDSqlCreateBridge.new;
        making(create);
        /// 这里需要判断是模型创建的栈sql，还是普通的sql。
        if (create.sql_statements) {/// 普通sql
            self.sqler.end(create.sql_statements,create.table_name);
            if([self tableExists:self.sqler.table_name] && create.ifnotExists){/// 判断表是否存在
                self.drop_table(self.sqler.table_name);
            }
            dispatch_async(ed_database_queue(), ^{
                self.create_table(db_name,self.sqler.sql_statements);
            });
        }else{
            dispatch_group_t create_table_group = dispatch_group_create();
            stack_pointer top = create -> top;
            while (top) {
                struct stack_table table = stack_pop(&top);
                dispatch_group_async(create_table_group, ed_database_queue(), ^{
                    self.create_table(db_name,[NSString stringWithUTF8String:table.sql]);
                });
            }
            dispatch_group_wait(create_table_group, (int64_t)(10 * NSEC_PER_SEC));
        }
        return self;
    };
    return method;
}

- (EDBuild *(^)(EDInsertHandle inserts))insert{
#warning TODO
    self.sqler.sql_statements = nil;
    EDBuild *(^method)(EDInsertHandle inserts) =^EDBuild *(EDInsertHandle inserts){
        dispatch_async(ed_database_queue(), ^{
            EDSqlInsertBridge *insert_sql = EDSqlInsertBridge.new;
            inserts(insert_sql);
            self.sqler.end(insert_sql.sql_statements,insert_sql.table_name);
            self.insert_data(self.sqler.sql_statements);
        });
        return self;
    };
    return method;
}

- (EDBuild *(^)(ErrorHandle))catchException{
    EDBuild *(^method)(ErrorHandle error) = ^EDBuild *(ErrorHandle error){
        if (error) {
            error(self.errors);
        }
        return self;
    };
    return method;
}

///MARK:- 判断表是否存在 -
- (BOOL)tableExists:(NSString *)table_name{
    if (self.db == nil) {
        return NO;
    }
    if (![self.db open]) {
        return NO;
    }
    BOOL result = NO;
    NSString *tableName = [table_name lowercaseString];
    FMResultSet *rs = [self.db executeQuery:EDTableExistsSQL, tableName];
    result = [rs next];
    [rs close];
    [self.db close];
    return result;
}

#pragma mark - Private Method -
///MARK:- 重置 -
- (EDBuild *(^)(NSString *))reset{
    return ^EDBuild *(NSString *sql){
        sql = nil;
        return self;
    };
}

///MARK:- 创建表 -
- (EDBuild *(^)(NSString *, NSString *))create_table{
    
    return ^EDBuild *(NSString * db_name,NSString *sql){
        CREATE_DATABASE(self,db_name);
        if (![self.db open]) {
            self.db = nil;
            [self.errors addObject:[NSError errorWithDomain:EDErrorDomain code:EDDataBaseOpenError userInfo:@{NSLocalizedDescriptionKey:EDDataBaseOpenErrorDescription}]];
            return self;
        }
        BOOL result = [self.db executeStatements:sql];
        if (!result) {
            [self.errors addObject:[NSError errorWithDomain:EDErrorDomain code:EDCreateTableError userInfo:@{NSLocalizedDescriptionKey:EDCreateTableErrorDescription}]];
        }
        [self.db close];
        return self.reset(sql);
        ///CREATE TABLE IF NOT EXISTS table(column1 int PRIMARY KEY,column2 int NOT NULL)
    };
}

///MARK:- 删除表 -
/// 用于每次调用make_database的时候，不是每一次都去创建一个db，如果db存在的话，就删除表，重新建表
- (EDBuild *(^)(NSString *))drop_table{
    
    return ^EDBuild *(NSString * table_name){
        if (![self.db open]) {
            self.db = nil;
            return self;
        }
        NSString *sql = [NSString stringWithFormat:EDTableDropSQL,table_name];
        [self.db executeStatements:sql];
        [self.db close];
        return self;
    };
}

///MARK:- 插入数据 -
- (EDBuild *(^)(NSString *))insert_data{
    EDBuild *(^method)(NSString *sql) = ^EDBuild *(NSString *sql){
        __block BOOL result = NO;
        dispatch_barrier_async(ed_database_queue(), ^{
            if (![self.db open]) {
                self.db = nil;
                return ;
            }
            result = [self.db executeUpdate:sql,nil];
            if (result == NO) {
                [self.errors addObject:[NSError errorWithDomain:EDErrorDomain code:EDInsertDataError userInfo:@{NSLocalizedDescriptionKey:EDInsertDataErrorDescription}]];
            }
            [self.db close];
        });
        return self;
    };
    return method;
}

@end
