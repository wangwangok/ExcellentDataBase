//
//  ExcellentDataBaseTests.m
//  ExcellentDataBaseTests
//
//  Created by 王望 on 2017/5/10.
//  Copyright © 2017年 wangwangok. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ExcellentDataBaseTests : XCTestCase

@end

@implementation ExcellentDataBaseTests

- (void)setUp {
    [super setUp];
//    [EDBuild make_database:^(EDSQLer *sqler) {
//        
//        EDSqlBridge *bridge = sqler.create(@"table",YES).append(@"cloumn1",@"int").constraint(EConstraintsNotNull|EConstraintsPrimaryKey, nil).append(@"cloumn2",@"int").constraint(EConstraintsNotNull|EConstraintsCheck,@"(Id_P>0)",nil).append(@"cloumn3",@"int").constraint(EConstraintsNone,nil);
//        NSLog(@"%@",bridge.sql_statements);
//    }];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
