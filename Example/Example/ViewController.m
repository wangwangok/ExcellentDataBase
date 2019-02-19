//
//  ViewController.m
//  Example
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import "ViewController.h"
//#import <FMDB/FMDB.h>
#import <ExcellentDataBase/ExcellentDataBase.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    EDBuild *builder = [EDBuild new];
//    builder.make_database(@"database",^(EDSqlBridge *sqler){
//        sqler.create(@"news",YES).append(@"id",@"int").constraint(EConstraintsPrimaryKey,nil).append(@"title",@"varchar(255)").constraint(EConstraintsNotNull,nil);
//    }).insert(^(EDSqlBridge *sqler){
//        sqler.create(@"news",YES).append(@"id",@"101").append(@"title",@"Changan Street");
//    }).catchException(^(NSArray<NSError *> *errors){
//        NSLog(@"%@",errors);
//    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
