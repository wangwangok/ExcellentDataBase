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
#define CREATE_QUEUE(queue) if(queue == nil){\
                                queue = dispatch_queue_create(EDQueueName, DISPATCH_QUEUE_CONCURRENT);\
                            }\

#define CREATE_DATABASE(build,db_name) if(self.db == nil){\
                                            NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];\
                                            NSString *path = [cachesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",db_name]];\
                                            NSLog(@"%@",path);\
                                            build.db = [FMDatabase databaseWithPath:path];\
                                        }\


#define CREATE_SQLER(state) if (!self.sqler) {\
                                self.sqler =EDSqlBridge.new;\
                            }\
                            self.sqler.sql_state = state;\

@interface EDBuild ()
@property (nonatomic,strong) FMDatabase  *db;
@property (nonatomic,strong) EDSqlBridge *sqler;
@property (nonatomic,strong) NSMutableArray<NSError *> *errors;
@end

@implementation EDBuild
static dispatch_queue_t db_queue;

- (instancetype)init{
    self = [super init];
    if (self) {
        self.errors = [NSMutableArray array];
        CREATE_QUEUE(db_queue);
    }
    return self;
}


#pragma mark - Public Method -
- (EDBuild *(^)(NSString *db_name ,EDCreateHandle making))make_database{
    
    EDBuild *(^method)(NSString *db_name ,EDCreateHandle making) =^EDBuild *(NSString *db_name ,EDCreateHandle making){
        CREATE_DATABASE(self,db_name);
        CREATE_SQLER(SQLStatementCreate);
        making(self.sqler);
        if([self tableExists]){/// 判断表是否存在
            self.drop_table(db_name);
        }
        [self.sqler end];
        dispatch_sync(db_queue, ^{
            self.create_table(db_name);
        });
        return self;
    };
    return method;
}

- (EDBuild *(^)(EDInsertHandle inserts))insert{
    EDBuild *(^method)(EDInsertHandle inserts) =^EDBuild *(EDInsertHandle inserts){
        CREATE_SQLER(SQLStatementInsert);
        inserts(self.sqler);
        [self.sqler end];
        self.insert_data();
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
- (BOOL)tableExists{
    if (self.db == nil) {
        return NO;
    }
    if (![self.db open]) {
        return NO;
    }
    BOOL result = NO;
    NSString *tableName = [self.sqler.table_name lowercaseString];
    FMResultSet *rs = [self.db executeQuery:EDTableExistsSQL, tableName];
    result = [rs next];
    [rs close];
    [self.db close];
    return result;
}

#pragma mark - Private Method -
///MARK:- 重置 -
- (EDBuild *)reset{
    self.sqler.sql_statements = nil;
    return self;
}

///MARK:- 创建表 -
- (EDBuild *(^)(NSString *))create_table{
    
    return ^EDBuild *(NSString * db_name){
        CREATE_DATABASE(self,db_name);
        if (![self.db open]) {
            self.db = nil;
            [self.errors addObject:[NSError errorWithDomain:EDErrorDomain code:EDDataBaseOpenError userInfo:@{NSLocalizedDescriptionKey:EDDataBaseOpenErrorDescription}]];
            return self;
        }
        BOOL result = [self.db executeStatements:self.sqler.sql_statements];
        if (!result) {
            [self.errors addObject:[NSError errorWithDomain:EDErrorDomain code:EDCreateTableError userInfo:@{NSLocalizedDescriptionKey:EDCreateTableErrorDescription}]];
        }
        [self.db close];
        return self.reset;
        ///CREATE TABLE IF NOT EXISTS table(column1 int PRIMARY KEY,column2 int NOT NULL)
    };
}

///MARK:- 删除表 -
/// 用于每次调用make_database的时候，不是每一次都去创建一个db，如果db存在的话，就删除表，重新建表
- (EDBuild *(^)(NSString *))drop_table{
    
    return ^EDBuild *(NSString * db_name){
        CREATE_DATABASE(self,db_name);
        if (![self.db open]) {
            self.db = nil;
            return self;
        }
        NSString *sql = [NSString stringWithFormat:EDTableDropSQL,self.sqler.table_name];
        [self.db executeStatements:sql];
        [self.db close];
        return self;
    };
}


///MARK:- 插入数据 -

- (EDBuild *(^)())insert_data{
    EDBuild *(^method)() = ^EDBuild *(){
        if (![self.db open]) {
            self.db = nil;
            return self;
        }
        __block BOOL result = NO;
        dispatch_barrier_sync(db_queue, ^{
            result = [self.db executeUpdate:self.sqler.sql_statements,nil];
        });
        if (result == NO) {
            [self.errors addObject:[NSError errorWithDomain:EDErrorDomain code:EDInsertDataError userInfo:@{NSLocalizedDescriptionKey:EDInsertDataErrorDescription}]];
        }
        [self.db close];
        return self;
    };
    return method;
}
@end
