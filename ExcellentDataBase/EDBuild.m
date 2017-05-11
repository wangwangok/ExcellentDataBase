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
}EDErrorCode;

#define EDErrorDomain @"ExcellentDataBaseErrorDomain"

#ifdef EDErrorDomain
static NSString *const EDDataBaseOpenErrorDescription = @"the database open failed";
static NSString *const EDCreateTableErrorDescription = @"create table failed";
#endif

static NSString *const EDTableExistsSQL = @"select [sql] from sqlite_master where [type] = 'table' and lower(name) = ?";

static const char *EDQueueName = "com.ExcellentDataBase.queue";
#define CREATE_QUEUE(queue) if(queue == nil){\
                                queue = dispatch_queue_create(EDQueueName, DISPATCH_QUEUE_CONCURRENT);\
                            }\

#define CREATE_DATABASE(build,db_name) NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];\
                                 NSString *path = [cachesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",db_name]];\
                                 build.db = [FMDatabase databaseWithPath:path];

@interface EDBuild ()

@property (nonatomic,strong)FMDatabase *db;
@property (nonatomic,strong)EDSQLer *sqler;
@property (nonatomic,copy)ErrorHandle error_handle;

@end

@implementation EDBuild

static dispatch_queue_t db_queue;

- (instancetype)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - Public Method -
- (EDBuild *(^)(NSString *db_name ,EDCreateHandle making))make_database{
    
    EDBuild *(^method)(NSString *db_name ,EDCreateHandle making) =^EDBuild *(NSString *db_name ,EDCreateHandle making){
        if (!self.db) {
            CREATE_DATABASE(self,db_name);
        }
        EDSQLer *sqler = EDSQLer.new;
        sqler.sql_state = SQLStatementCreate;
        making(sqler);
        self.sqler = sqler;
        self.create_table(db_name,self.error_handle);
        return self;
    };
    return method;
}

- (EDBuild *(^)(EDInsertHandle inserts))insert{
    EDBuild *(^method)(EDInsertHandle inserts) =^EDBuild *(EDInsertHandle inserts){
        inserts(self.sqler.bridge,self.sqler);
        return self;
    };
    return method;
}

- (EDBuild *(^)(ErrorHandle))catchException{
    EDBuild *(^method)(ErrorHandle error) = ^EDBuild *(ErrorHandle error){
        if (error) {
            self.error_handle = error;
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
    NSString *tableName = [self.sqler.bridge.table_name lowercaseString];
    FMResultSet *rs = [self.db executeQuery:EDTableExistsSQL, tableName];
    result = [rs next];
    [rs close];
    [self.db close];
    return result;
}

#pragma mark - Private Method -
///MARK:- 重置 -
- (EDBuild *)reset{
    self.sqler.bridge.sql_statements = nil;
    return self;
}

///MARK:- 创建表 -
- (EDBuild *(^)(NSString *,ErrorHandle))create_table{
    CREATE_QUEUE(db_queue);
    return ^EDBuild *(NSString * db_name,ErrorHandle handle){
        if (!self.db) {
            CREATE_DATABASE(self,db_name);
            ///[EDBuild create_db:db_name];
        }
        
        if (![self.db open]) {
            self.db = nil;
            handle([NSError errorWithDomain:EDErrorDomain code:EDDataBaseOpenError userInfo:@{NSLocalizedDescriptionKey:EDDataBaseOpenErrorDescription}]);
            return self;
        }
        BOOL result = [self.db executeStatements:self.sqler.bridge.sql_statements];
        if (!result) {
            handle([NSError errorWithDomain:EDErrorDomain code:EDCreateTableError userInfo:@{NSLocalizedDescriptionKey:EDCreateTableErrorDescription}]);
        }
        [self.db close];
        return self.reset;
    };
}




- (EDBuild *(^)(id value))insert{
    return ^EDBuild *(id value){
        if ([value isMemberOfClass:[NSArray class]]) {
            
            ///<NSCopying, NSMutableCopying, NSSecureCoding, NSFastEnumeration>
        }
        
        if ([value isMemberOfClass:[NSDictionary class]]) {
            
            ///<NSCopying, NSMutableCopying, NSSecureCoding, NSFastEnumeration>
            
        }
        return self;
    };
}


@end
