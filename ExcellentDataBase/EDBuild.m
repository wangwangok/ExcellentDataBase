//
//  EDBuild.m
//  新成都范儿
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 dev@huaxi100.com. All rights reserved.
//

#import "EDBuild.h"

@implementation EDBuild

+ (void)make_database:(void(^)(EDSQLer *sqler))making{
    EDSQLer *sqler = [EDSQLer new];
    making(sqler);
}

@end
