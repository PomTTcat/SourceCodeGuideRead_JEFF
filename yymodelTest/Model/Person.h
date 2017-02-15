//
//  Person.h
//  yymodelTest
//
//  Created by JIE on 2017/2/15.
//  Copyright © 2017年 AppleYJ. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Person : NSObject
@property (nonatomic, copy)     NSString        *name;
@property (nonatomic, assign)   NSUInteger      age;
@end

@interface Man : Person
@property (nonatomic, copy)     NSString        *wifeName;
@end

@interface Woman : Person
@property (nonatomic, copy)     NSString        *husbandName;
@end
