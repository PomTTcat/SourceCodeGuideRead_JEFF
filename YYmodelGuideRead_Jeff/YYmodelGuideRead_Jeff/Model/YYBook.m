//
//  YYBook.m
//  last1031
//
//  Created by JIE on 2017/1/24.
//  Copyright © 2017年 AppleYJ. All rights reserved.
//

#import "YYBook.h"

//---------------------------------------------------------------------------
@implementation YYAuthor

@end
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
@implementation User

//使用了黑名单，将来会剔除黑名单中的属性
+ (NSArray *)modelPropertyBlacklist {
    return @[@"blackListTest"];
}

//白名单使用比较极端，只有白名单中的可以通过。    正常情况使用黑马单即可。
//+ (NSArray *)modelPropertyWhitelist {
//    return @[@"name"];
//}

//----------start       把 json 中的timestamp转换成createdAt      此处只执行一次。
// 当 JSON 转为 Model 完成后，该方法会被调用。
// 你可以在这里对数据进行校验，如果校验不通过，可以返回 NO，则该 Model 会被忽略。NO则返回 nil。
// 你也可以在这里做一些自动转换不能完成的工作。
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    NSNumber *timestamp = dic[@"timestamp"];
    if (![timestamp isKindOfClass:[NSNumber class]]) return NO;
    _createdAt = [NSDate dateWithTimeIntervalSince1970:timestamp.floatValue];
    return YES;
}

//此处在字典中会多一个 timestamp = 1445534592;
// 当 Model 转为 JSON 完成后，该方法会被调用。
// 你可以在这里对数据进行校验，如果校验不通过，可以返回 NO，则该 Model 会被忽略。
// 你也可以在这里做一些自动转换不能完成的工作。
- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic {
    if (!_createdAt) return NO;
    dic[@"timestamp"] = @(_createdAt.timeIntervalSince1970);
    return YES;
}
//----------end

//custom属性，让 json key 映射到 对象的属性。
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"name" : @"n",
             @"page" : @"p",
             @"desc" : @"ext.desc",                 //key.path
             @"bookID" : @[@"ID",@"id",@"book_id"]};//id，ID，book_id都可以。
}

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"authors" : [YYAuthor class]};
}

+ (Class)modelCustomClassForDictionary:(NSDictionary*)dictionary {
    if (dictionary[@"runtimeClass"] != nil) {
        NSString *runClass = dictionary[@"runtimeClass"];
        return NSClassFromString(runClass);
    } else {
        return [self class];
    }
}

- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic{
    if ([dic[@"goChange"] isEqualToString:@"YES"]) {
        return dic;
    }
    return nil;
}



@end

@implementation YYUserSon



@end
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
@implementation YYShadow
- (void)encodeWithCoder:(NSCoder *)aCoder { [self modelEncodeWithCoder:aCoder]; }
- (id)initWithCoder:(NSCoder *)aDecoder { self = [super init]; return [self modelInitWithCoder:aDecoder]; }
- (id)copyWithZone:(NSZone *)zone { return [self modelCopy]; }
- (NSUInteger)hash { return [self modelHash]; }
- (BOOL)isEqual:(id)object { return [self modelIsEqual:object]; }
- (NSString *)description { return [self modelDescription]; }
@end


//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
