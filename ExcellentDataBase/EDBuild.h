//
//  EDBuild.h
//  新成都范儿
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 dev@huaxi100.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDSQLer.h"

@interface EDBuild : NSObject

+ (void)make_database:(void(^)(EDSQLer *sqler))making;

@end
