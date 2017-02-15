//
//  Person.m
//  yymodelTest
//
//  Created by JIE on 2017/2/15.
//  Copyright © 2017年 AppleYJ. All rights reserved.
//

#import "Person.h"

@implementation Person
+ (Class)modelCustomClassForDictionary:(NSDictionary*)dictionary {
    if (dictionary[@"sex"] != nil) {
        NSString *runClass = dictionary[@"sex"];
        return NSClassFromString(runClass);
    } else {
        return [self class];
    }
}

//测试modelCustomWillTransformFromDictionary，再开启
//- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic{
//    if ([dic[@"sex"] isEqualToString:@"Man"]) {
//        return nil;
//    }
//    return dic;
//}

@end

@implementation Man
@end

@implementation Woman
@end
