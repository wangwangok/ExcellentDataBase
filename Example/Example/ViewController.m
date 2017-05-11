//
//  ViewController.m
//  Example
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import "ViewController.h"
#import <ExcellentDataBase/ExcellentDataBase.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [EDBuild make_database:^(EDSQLer *sqler) {
        
        EDSqlBridge *bridge = sqler.create(@"table",YES).append(@"cloumn1",@"int").constraint(EConstraintsNotNull|EConstraintsPrimaryKey, nil).append(@"cloumn2",@"int").constraint(EConstraintsNotNull|EConstraintsCheck,@"(Id_P>0)",nil).append(@"cloumn3",@"int").constraint(EConstraintsNone,nil);
        NSLog(@"%@",bridge.sql_statements);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
