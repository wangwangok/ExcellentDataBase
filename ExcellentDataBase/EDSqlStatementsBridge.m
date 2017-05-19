//
//  EDSqlStatementsBridge.m
//  ExcellentDataBase
//
//  Created by 王望 on 2017/5/16.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import "EDSqlStatementsBridge.h"
#import <objc/runtime.h>

#define SQL_NULL if (!self.sql_statements) {\
                NSAssert(NO, @"Sql statement is empty, Please call \"create\" method before");\
              }

/**
 在将model创建表的时候，这个model的属性里面可能还包含了其他的model，所以这时候我们就需要去创建这个表。为此我使用stack来保存sql，也就是最先创建最里面的表，一次这样。
 我构思的创建方法adt模型是：
 ```
 第一层sql
 builder.create(...).constraint("name",EConstraintsPrimaryKey,nil).constraint("table",EConstraintsNone,{///内层
    /// 表中包含表
    第二层sql
    builder.create(...).constraint("name",EConstraintsNone,nil)
 }).constraint("table",EConstraintsNone,{
    /// 表中包含表
    第二层sql
    builder.create(...).constraint("name",EConstraintsNone,{///内层
        第三层sql
    })
 })
 ```
 */
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

EDEncodingType EDEncodeTheType(char const *value){
    /// 这里借鉴了https://github.com/ibireme/YYModel/blob/master/YYModel/YYClassInfo.m
    /// 但是这里没有用到的name里面的数据，也就是说，我不需要在一个16位的数字中不需要用高八位存name信息，我只需要用里面的低八位来存value信息
    if (!value) {
        return EDEncodeTypeUnknown;
    }
    size_t len = strlen(value);
    if (len == 0) {
        return EDEncodeTypeUnknown;
    }
    switch (*value) {
        case 'c':///char
            return EDEncodeTypeChar;
        case 'i':///int
            return EDEncodeTypeInt;
        case 's':///short
            return EDEncodeTypeShort;
        case 'l':/// long - int32_t
            return EDEncodeTypeInt32;
        case 'q':/// long long - int64_t
            return EDEncodeTypeInt64;
        case 'C':/// unsigned char
            return EDEncodeTypeUChar;
        case 'I':/// unsigned int
            return EDEncodeTypeUInt;
        case 'S':/// unsigned short
            return EDEncodeTypeUShort;
        case 'L':/// unsigned long
            return EDEncodeTypeUInt32;
        case 'Q':/// unsigned long long
            return EDEncodeTypeUInt64;
        case 'f':/// float
            return EDEncodeTypeFloat;
        case 'd':/// double
            return EDEncodeTypeDouble;
        case 'B':///Bool
            return EDEncodeTypeBool;
        case 'v':///Void
            return EDEncodeTypeVoid;
        case '*':
            return EDEncodeTypeChars;
        case '@': {
            if (len == 2 && *(value + 1) == '?')
                return EDEncodeTypeUnknown;
            else
                return EDEncodeTypeObject;
        }
        case '^':
            return EDEncodeTypePointer;
        case '{':
            return EDEncodeTypeStruct;
        default:return EDEncodeTypeUnknown;
    }
}

/// objc_property_t property_copyAttributeList组成一个对象
@interface EDPropertyInfo : NSObject

@property (nonatomic, assign ,readonly)objc_property_t property;
@property (nonatomic, strong, readonly)NSString *name;
@property (nonatomic, nullable, assign, readonly) Class clazz;
@property (nonatomic, assign, readonly)EDEncodingType encode_type;

@end

@implementation EDPropertyInfo
@synthesize property = _property,name = _name,clazz = _clazz,encode_type = _encode_type;

/// https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
- (instancetype)initPropertyInfoWith:(objc_property_t)property{
    if (!property) return nil;
    self = [super init];
    _property = property;
    const char *the_name = property_getName(property);
    if (the_name) {
        _name = [NSString stringWithCString:the_name encoding:NSUTF8StringEncoding];
    }
    unsigned int attribute_count = 0;
    objc_property_attribute_t *attributes = property_copyAttributeList(property, &attribute_count);
    for (int i = 0; i < attribute_count; i++) {
        NSString *name = [NSString stringWithCString:(attributes + i)->name encoding:NSUTF8StringEncoding];
        const char *value = (attributes + i)->value;
        EDEncodingType type = EDEncodeTheType(value);
        _encode_type = type;
        if ([name isEqualToString:@"T"] && value) {
            if (type == EDEncodeTypeObject) {/// 对象里面再包含了对象
                NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:value]];
                if (![scanner scanString:@"@\"" intoString:NULL]) continue;
                NSString *clsName = nil;
                if ([scanner scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&clsName]) {
                    if (clsName.length) _clazz = objc_getClass(clsName.UTF8String);
                }
            }
        }
    }
    free(attributes);
    return self;
}

@end

/**
 *
 * 这里解释一下为什么要用函数指针，增加这个函数的复杂度。因为在create，insert，等等根据模型来处理的操作都需要用到这些。然后我用函数的指针的方式，将具体的操作放到外面去，由每个具体场景具体处理
 * 为什么这里不直接传入一个函数，而是要传入一个函数指针呢？如果是函数的话逻辑就没有这么清晰，又要在这个函数里面加入一系列的判断语句。
 *
 */

/**
 *
 * param: property :对象的属性信息；
 * param: sql      : 拼接过的sql；
 * param: context  :上下文，实际上是传递self
 */
typedef void(*PropertyEncodeHandle)(void *property,const char *sql, void *context);

typedef void(*PropertyObjectEncodeHandle)(id data,NSString *table_name,void *property,const char *sql, void *context);
void c_base_property_encode(id data,NSString *table_name,void *context,stack_pointer *top, PropertyEncodeHandle text,PropertyEncodeHandle interger ,PropertyEncodeHandle floats ,PropertyEncodeHandle bools,PropertyObjectEncodeHandle objects){
    /// http://www.w3school.com.cn/json/json_syntax.asp
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([data class], &count);
    NSMutableString *create_table_sql = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@()",table_name];
    for (int i = 0; i < count; i++) {
        objc_property_t property = *(properties + i);
        EDPropertyInfo *data_property = [[EDPropertyInfo alloc] initPropertyInfoWith:property];
        void *c_property = (__bridge void *)data_property;
        switch (data_property.encode_type) {
            case EDEncodeTypeChar:
            case EDEncodeTypeUChar:
            case EDEncodeTypeChars:text(c_property,create_table_sql.UTF8String,context);break;/// char -- text
            case EDEncodeTypeInt:
            case EDEncodeTypeShort:
            case EDEncodeTypeInt32:
            case EDEncodeTypeInt64:
            case EDEncodeTypeUInt:
            case EDEncodeTypeUShort:
            case EDEncodeTypeUInt32:
            case EDEncodeTypeUInt64:interger(c_property,create_table_sql.UTF8String,context);break;/// integer -- INTEGER
            case EDEncodeTypeFloat:
            case EDEncodeTypeDouble:floats(c_property,create_table_sql.UTF8String,context);break;/// float -- REAL
            case EDEncodeTypeBool:bools(c_property,create_table_sql.UTF8String,context);break;/// bool -- NUMERIC
            case EDEncodeTypeObject:objects(data,table_name,c_property,create_table_sql.UTF8String,context);break;/// 数组、模型。到了这里就说明要创建新表了，就需要用到栈。
            default:
                break;
        }
    }
    char *c_sql = (char *)create_table_sql.UTF8String;
    c_base_end(c_sql);
    create_table_sql = [NSMutableString stringWithUTF8String:c_sql];
    stack_push(top, create_table_sql, table_name);
}

typedef enum e_SqlAppend{
    ESqlAppendAppend,/// 添加类型为添加列
    ESqlAppendConstraint///添加约束
}ESqlAppendType;

@interface EDSqlCreateBridge ()
@property (nonatomic, assign) ESqlAppendType e_append_type;
@end

@implementation EDSqlCreateBridge : EDSqlBridge
@synthesize table_name = _table_name;

#pragma mark - Private -
- (void)append_for_create:(NSString *)value1 aValue2:(NSString *)value2 theSql:(NSMutableString *)sql{
    NSString *colum_sql = [NSString stringWithFormat:@"%@ %@,",value1,value2];
    NSInteger index = self.sql_statements.length - 1;
    [sql insertString:colum_sql atIndex:index];
}

/**
- (void)property_encode:(id)data aTableName:(NSString *)table_name{
#warning TODO:FOR INSERT,DELETE,QUERY
    /// http://www.w3school.com.cn/json/json_syntax.asp
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([data class], &count);
    NSMutableString *create_table_sql = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@()",table_name];
    for (int i = 0; i < count; i++) {
        objc_property_t property = *(properties + i);
        EDPropertyInfo *data_property = [[EDPropertyInfo alloc] initPropertyInfoWith:property];
        switch (data_property.encode_type) {
            case EDEncodeTypeChar:
            case EDEncodeTypeUChar:
            case EDEncodeTypeChars:
            {/// char -- text
                [self append_for_create:data_property.name aValue2:@"TEXT" theSql:create_table_sql];
            }
                break;
            case EDEncodeTypeInt:
            case EDEncodeTypeShort:
            case EDEncodeTypeInt32:
            case EDEncodeTypeInt64:
            case EDEncodeTypeUInt:
            case EDEncodeTypeUShort:
            case EDEncodeTypeUInt32:
            case EDEncodeTypeUInt64:
            {/// integer -- INTEGER
                [self append_for_create:data_property.name aValue2:@"INTEGER" theSql:create_table_sql];
            }
                break;
            case EDEncodeTypeFloat:
            case EDEncodeTypeDouble:
            {/// float -- REAL
                [self append_for_create:data_property.name aValue2:@"REAL" theSql:create_table_sql];
            }
                break;
            case EDEncodeTypeBool:
            {/// bool -- NUMERIC
                [self append_for_create:data_property.name aValue2:@"NUMERIC" theSql:create_table_sql];
            }
                break;
            case EDEncodeTypeObject:/// 数组、模型。到了这里就说明要创建新表了，就需要用到栈。
            {
                if ([data_property.clazz isSubclassOfClass:[NSArray class]] ||
                    [data_property.clazz isSubclassOfClass:[NSMutableArray class]]){///json中的数组，拿第一个元素，也就成了处理对象。如果为空不操作
                    NSArray *array = [[data valueForKey:data_property.name] mutableCopy];
                    if (array && array.count > 0) {
                        [self property_encode:[array firstObject] aTableName:data_property.name];
                    }
                }else{/// json中的对象
                    [self property_encode:[data valueForKey:data_property.name] aTableName:data_property.name];
                }
            }
                break;
            default:
                break;
        }
    }
    char *c_sql = (char *)create_table_sql.UTF8String;
    c_base_end(c_sql);
    create_table_sql = [NSMutableString stringWithUTF8String:c_sql];
    stack_push(&top, create_table_sql, table_name);
}
*/

#pragma mark - Function Pointer For Create -
void sql_text(void *property,const char *sql, void *context){
    EDSqlCreateBridge *_self = (__bridge EDSqlCreateBridge *)(context);
    EDPropertyInfo *info = (__bridge EDPropertyInfo *)(property);
    [_self append_for_create:info.name aValue2:@"TEXT" theSql:[NSMutableString stringWithUTF8String:sql]];
}

void sql_interger(void *property,const char *sql, void *context){
    EDSqlCreateBridge *_self = (__bridge EDSqlCreateBridge *)(context);
    EDPropertyInfo *info = (__bridge EDPropertyInfo *)(property);
    [_self append_for_create:info.name aValue2:@"INTEGER" theSql:[NSMutableString stringWithUTF8String:sql]];
}

void sql_float(void *property,const char *sql, void *context){
    EDSqlCreateBridge *_self = (__bridge EDSqlCreateBridge *)(context);
    EDPropertyInfo *info = (__bridge EDPropertyInfo *)(property);
    [_self append_for_create:info.name aValue2:@"REAL" theSql:[NSMutableString stringWithUTF8String:sql]];
}

void sql_bool(void *property,const char *sql, void *context){
    EDSqlCreateBridge *_self = (__bridge EDSqlCreateBridge *)(context);
    EDPropertyInfo *info = (__bridge EDPropertyInfo *)(property);
    [_self append_for_create:info.name aValue2:@"NUMERIC" theSql:[NSMutableString stringWithUTF8String:sql]];
}

void sql_object(id data,NSString *table_name,void *property,const char *sql, void *context){
    EDSqlCreateBridge *_self = (__bridge EDSqlCreateBridge *)(context);
    EDPropertyInfo *info = (__bridge EDPropertyInfo *)(property);
    if ([info.clazz isSubclassOfClass:[NSArray class]] ||
        [info.clazz isSubclassOfClass:[NSMutableArray class]]){///json中的数组，拿第一个元素，也就成了处理对象。如果为空不操作
        NSArray *array = [[info valueForKey:info.name] mutableCopy];
        if (array && array.count > 0) {
            c_base_property_encode(data, table_name, context, &(_self->top), &sql_text, &sql_interger, &sql_float, &sql_bool, &sql_object);
        }
    }else{/// json中的对象
        c_base_property_encode(data, table_name, context, &(_self->top), &sql_text, &sql_interger, &sql_float, &sql_bool, &sql_object);
    }
}

#pragma mark - Public -
- (EDSqlCreateBridge *(^)(BOOL, id,...))create{
    self.sql_statements = nil;
    self.e_append_type = ESqlAppendAppend;
    EDSqlCreateBridge*(^method)(BOOL ifnotExists, id contents,...) = ^ EDSqlCreateBridge* (BOOL ifnotExists, id contents,...){
        if ([contents isKindOfClass:[NSString class]]) {/// 普通sql
            self->_table_name = [contents mutableCopy];
            self.ifnotExists = ifnotExists;
            NSString *create_table_sql = [NSString stringWithFormat:@"CREATE TABLE %@ %@()",NO == ifnotExists ? @"IF NOT EXISTS" : @"",contents];
            self.sql_statements = [create_table_sql mutableCopy];
        }else{
            NSString *table_name_arg;
            va_list args;
            va_start(args, contents);
            NSString *arg;
            if(contents){
                while((arg = va_arg(args, NSString *))){
                    table_name_arg = arg;
                }
            }
            va_end(args);
            c_base_property_encode(contents, table_name_arg ?: @"unkown_table", (__bridge void *)(self), &(self->top), &sql_text, &sql_interger, &sql_float, &sql_bool, &sql_object);
            ///[self property_encode:contents aTableName:table_name_arg ?: @"unkown_table"];
        }
        return self;
    };
    return method;
}

- (EDSqlCreateBridge *(^)(NSString *value1,NSString *value2))append{
    if (!self.sql_statements) {
        NSAssert(NO, @"Sql statement is empty, Please call \"create\" method before");
    }
    self.e_append_type = ESqlAppendAppend;
    EDSqlCreateBridge *(^method)(NSString *value1,NSString *value2) = ^EDSqlCreateBridge *(NSString *value1, NSString *value2){
        [self append_for_create:value1 aValue2:value2 theSql:self.sql_statements];
        return self;
    };
    return method;
}

#define MAX_CONSTRAINTS_SIZE 6
- (EDSqlCreateBridge *(^)(int constraint, NSString *others,...))constraint{
    
    return ^EDSqlCreateBridge *(int constraint, NSString *others,...){
        if (ESqlAppendConstraint == self.e_append_type) {/// 防止在约束后面连续添加约束
            return self;
        }
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
        NSInteger index = self.sql_statements.length - 2;
        [self.sql_statements insertString:sql_constraints atIndex:index];
        if (!others) {
            return self;
        }
        index = self.sql_statements.length - 2;
        [self.sql_statements insertString:[NSString stringWithFormat:@" %@",others] atIndex:index];
        va_list args;
        va_start(args, others);
        NSString *arg;
        if(others){
            while((arg = va_arg(args, NSString *))){
                index = self.sql_statements.length - 1;
                [self.sql_statements insertString:[NSString stringWithFormat:@" %@",arg] atIndex:index];
            }
        }
        va_end(args);
        self.e_append_type = ESqlAppendConstraint;
        return self;
    };
}

@end









typedef enum {
    EDInsertCallNone,EDInsertCallAppend,EDInsertCallAllIn,
} EDInsertCallType;

@interface EDSqlInsertBridge ()

@property (nonatomic ,assign)EDInsertCallType _called_type;

@end

@implementation EDSqlInsertBridge : EDSqlBridge

- (void)allin_for_insert:(NSArray *)contents{
    if (self._called_type == EDInsertCallAppend) {
        return ;
    }
    self._called_type = EDInsertCallAllIn;
    NSString *delete_regex = @"\\(\\)\\B\\s" ;
    NSRange range = [self.sql_statements rangeOfString:delete_regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        [self.sql_statements deleteCharactersInRange:range];
    }
    for (NSString *value in contents) {
        [self.sql_statements insertString:[NSString stringWithFormat:@"'%@',",value] atIndex:self.sql_statements.length - 1];
    }
}

- (void)append_for_insert:(NSString *)value1 aValue2:(NSString *)value2{
    if (self._called_type == EDInsertCallAllIn) {
        return ;
    }
    self._called_type = EDInsertCallAppend;
    NSString *regex = @"\\)\\s+" ;
    NSRange range = [self.sql_statements rangeOfString:regex options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        [self.sql_statements insertString:[NSString stringWithFormat:@"%@,",value1] atIndex:range.location];
    }
    [self.sql_statements insertString:[NSString stringWithFormat:@"'%@',",value2] atIndex:self.sql_statements.length - 1];
}

- (void)input_for_insert:(id)source_data{
    NSDictionary *replace_dic;
    if ([[source_data class] respondsToSelector:@selector(SystemKeywordsReplace)]) {
        replace_dic = [[source_data class] SystemKeywordsReplace];
    }
    Class clazz = [source_data class];
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(clazz, &count);///class_copyIvarList 成员变量
    for (unsigned int i = 0; i<count; i++) {/// 获取数据对应的属性名称
        NSString *property = [NSString stringWithUTF8String:property_getName(*(properties + i))];
        /// 过滤掉系统自动添加的元素
        if ([property isEqualToString:@"hash"]
            || [property isEqualToString:@"superclass"]
            || [property isEqualToString:@"description"]
            || [property isEqualToString:@"debugDescription"]) {
            continue;
        }
        NSString *value = [NSString stringWithFormat:@"%@",[source_data valueForKey:property]];
        NSString *value_utf8;
        if ([value respondsToSelector:@selector(stringByReplacingPercentEscapesUsingEncoding:)]) {
            value_utf8 = [NSMutableString stringWithString:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        if (replace_dic && [replace_dic.allKeys containsObject:property]) {/// 进行关键字替换
            property = [replace_dic objectForKey:property];
        }
        if (value_utf8) {/// 这里会存在，属性存在的key-value在数据库表中没有改字段。
            self.append(property,value_utf8);
        }
    }
    free(properties);
}


#pragma mark - Public -
- (EDSqlInsertBridge *(^)(NSString *))create{
    self._called_type = EDInsertCallNone;
    self.sql_statements = nil;
    EDSqlInsertBridge*(^method)(NSString *name) = ^ EDSqlInsertBridge* (NSString *name){
        NSString *create_table_sql = [NSString stringWithFormat:@"INSERT INTO %@ () VALUES ()",name];
        self.sql_statements = [create_table_sql mutableCopy];
        return self;
    };
    return method;
}

- (EDSqlInsertBridge *(^)(NSString *value1,NSString *value2))append{
    SQL_NULL;
    EDSqlInsertBridge *(^method)(NSString *value1,NSString *value2) = ^EDSqlInsertBridge *(NSString *value1, NSString *value2){
        [self append_for_insert:value1 aValue2:value2];
        return self;
    };
    return method;
}

- (EDSqlInsertBridge *(^)(NSArray *))allin {
    SQL_NULL;
    EDSqlInsertBridge *(^method)(NSArray *contents) = ^EDSqlInsertBridge *(NSArray *contents){
        [self allin_for_insert:contents];
        return self;
    };
    return method;
}

- (EDSqlInsertBridge *(^)(id))input {
    SQL_NULL;
    EDSqlInsertBridge *(^method)(id source_data) = ^EDSqlInsertBridge *(id source_data){
        [self input_for_insert:source_data];
        return self;
    };
    return method;
}

@end

@implementation EDSqlDeleteBridge : EDSqlBridge

@end

@implementation EDSqlUpdateBridge : EDSqlBridge

@end

@implementation EDSqlQueryBridge : EDSqlBridge

@end

@implementation NSObject (EDSqlSystemKeyword)

+ (NSDictionary *)SystemKeywordsReplace{
    return nil;
}

@end
