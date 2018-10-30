//
//  ViewController2.m
//  yymodelTest
//
//  Created by JIE on 2017/2/11.
//  Copyright © 2017年 AppleYJ. All rights reserved.
//

#import "ViewController2.h"
#import "NSObject+YYModel.h"
#import "YYBook.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "Person.h"

@interface ViewController2 ()

@end

@implementation ViewController2

- (void)nameHa:(NSString *)here{
    NSString *str = [NSString stringWithFormat:@"---123---%@",here];
    NSLog(@"str = %@",str);
}

//until here
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];

    
    //test Part
    //--------------------------------------
    NSData *dataTest = [self dataWithPath:@"content"];
    User *userTest = [User modelWithJSON:dataTest];

    NSLog(@"i = %@",[userTest modelDescription]);
    //--------------------------------------
//    //json -> model     model ->(nsobject , nsstring ,date)
//    NSData *data = [self dataWithPath:@"content"];
//    User *user = [User modelWithJSON:data];
//    NSDictionary *jsonUser = [user modelToJSONObject];
//    NSLog(@"jsonUser = %@",jsonUser);
//
//    NSData *dataArr = [self dataWithPath:@"arrayTest"];
//    NSArray *arrT = [NSArray modelArrayWithClass:[YYAuthor class] json:dataArr];
//    NSLog(@"arrT = %@",arrT);
//
//    NSData *dataDict = [self dataWithPath:@"dicTest"];
//    NSDictionary *dicT = [NSDictionary modelDictionaryWithClass:[YYAuthor class] json:dataDict];
//    NSLog(@"dicT = %@",dicT);
//    //dicT[@"user3"]的value中（ key = user3, value = nil ）
//
//    NSData *dataPerson = [self dataWithPath:@"person"];
//    Person *person = [Person modelWithJSON:dataPerson];
//    [person modelDescription];
    
//    ((void (*)(id, SEL, id))(void *) objc_msgSend)(self,@selector(nameHa:),@"xixix");
}

- (NSData *)dataWithPath:(NSString *)path{
    NSString *pathIn = [[NSBundle mainBundle] pathForResource:path ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:pathIn];
    return data;
}

//字符串末尾研究
- (void)someTest{
    char name[7] = "123456";
    char na2[4];
    na2[3] = '\0';      //na2[4]总共有4个字节(一个字节8位)，最后一位置'\0',能赋值的实际上只有3位。（len-1）普通拷贝会拷贝后续的字节。
    //    memcpy(na2, name + 2, 4);   //na2	char [4]	"3456123456"
    //    memcpy(na2, name + 2, 3);   //na2	char [4]	"345\x01123456" 会把溢出的也拷贝过来
    memcpy(na2, name + 2, 3);   //na2	char [4]	"3456123456"
    
    char str1[] = "1234gyj";
}

@end
