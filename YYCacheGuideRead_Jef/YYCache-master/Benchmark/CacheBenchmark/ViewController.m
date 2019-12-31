//
//  ViewController.m
//  CacheBenchmarkJJ
//
//  Created by ibireme on 2017/6/29.
//  Copyright © 2017年 ibireme. All rights reserved.
//

#import "ViewController.h"
#include "Benchmark.h"
#import "YYCache.h"
#import "PINCache.h"
#import "YYThreadSafeDictionary.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [BenchmarkJJ BenchmarkJJ];
    //    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
#define RANDOMLY true
    
    [ViewController memoryCacheBenchmarkJJ];
    
//    [ViewController diskCacheWriteSmallDataBenchmarkJJ];
//
//    [ViewController diskCacheWriteLargeDataBenchmarkJJ];
//
//    [ViewController diskCacheReadSmallDataBenchmarkJJ:RANDOMLY];
//
//    [ViewController diskCacheReadLargeDataBenchmarkJJ:RANDOMLY];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (void)memoryCacheBenchmarkJJ {
    YYMemoryCache *yy = [YYMemoryCache new];
    
    NSMutableArray *keys = [NSMutableArray new];
    NSMutableArray *values = [NSMutableArray new];
    int count = 200000;
    for (int i = 0; i < count; i++) {
        NSObject *key;
        key = @(i); // avoid string compare
        //key = @(i).description; // it will slow down NSCache...
        //key = [NSUUID UUID].UUIDString;
        NSData *value = [NSData dataWithBytes:&i length:sizeof(int)];
        [keys addObject:key];
        [values addObject:value];
    }
    
    for (int i = 0; i < count; i++) {
        [yy setObject:values[i] forKey:keys[i]];
    }
    
    NSLog(@"%s",__func__);
}

+ (void)diskCacheWriteSmallDataBenchmarkJJ {
    NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) firstObject];
    basePath = [basePath stringByAppendingPathComponent:@"FileCacheBenchmarkJJSmall"];
    
    YYKVStorage *yykvFile = [[YYKVStorage alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yykvFile"] type:YYKVStorageTypeFile];
    YYKVStorage *yykvSQLite = [[YYKVStorage alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yykvSQLite"] type:YYKVStorageTypeSQLite];
    YYDiskCache *yy = [[YYDiskCache alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yy"]];
    
    int count = 1000;
    NSMutableArray *keys = [NSMutableArray new];
    NSMutableArray *values = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        NSString *key = @(i).description;
        NSNumber *value = @(i);
        [keys addObject:key];
        [values addObject:value];
    }
    
    
    
    for (int i = 0; i < count; i++) {
        [yykvFile saveItemWithKey:keys[i] value:[NSKeyedArchiver archivedDataWithRootObject:values[i]] filename:keys[i] extendedData:nil];
    }
    
    for (int i = 0; i < count; i++) {
        [yykvSQLite saveItemWithKey:keys[i] value:[NSKeyedArchiver archivedDataWithRootObject:values[i]]];
    }
    
    
    for (int i = 0; i < count; i++) {
        [yy setObject:values[i] forKey:keys[i]];
    }
}

+ (void)diskCacheWriteLargeDataBenchmarkJJ {
    NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) firstObject];
    basePath = [basePath stringByAppendingPathComponent:@"FileCacheBenchmarkJJLarge"];
    
    YYKVStorage *yykvFile = [[YYKVStorage alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yykvFile"] type:YYKVStorageTypeFile];
    YYKVStorage *yykvSQLite = [[YYKVStorage alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yykvSQLite"] type:YYKVStorageTypeSQLite];
    YYDiskCache *yy = [[YYDiskCache alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yy"]];
    yy.customArchiveBlock = ^(id object) {return object;};
    yy.customUnarchiveBlock = ^(NSData *object) {return object;};
    
    
    int count = 1000;
    NSMutableArray *keys = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        NSString *key = @(i).description;
        [keys addObject:key];
    }
    NSMutableData *dataValue = [NSMutableData new]; // 32KB
    for (int i = 0; i < 100 * 1024; i++) {
        // 1 byte = 8 bits | 64bit = 8 byte。
        [dataValue appendBytes:&i length:1];
    }
    
    for (int i = 0; i < count; i++) {
        [yykvFile saveItemWithKey:keys[i] value:dataValue filename:keys[i] extendedData:nil];
    }
    
    for (int i = 0; i < count; i++) {
        [yykvSQLite saveItemWithKey:keys[i] value:dataValue];
    }
    
    for (int i = 0; i < count; i++) {
        [yy setObject:dataValue forKey:keys[i]];
    }
    
}

+ (void)diskCacheReadSmallDataBenchmarkJJ:(BOOL)randomly {
    NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) firstObject];
    basePath = [basePath stringByAppendingPathComponent:@"FileCacheBenchmarkJJSmall"];
    
    YYKVStorage *yykvFile = [[YYKVStorage alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yykvFile"] type:YYKVStorageTypeFile];
    YYKVStorage *yykvSQLite = [[YYKVStorage alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yykvSQLite"] type:YYKVStorageTypeSQLite];
    YYDiskCache *yy = [[YYDiskCache alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yy"]];
    PINDiskCache *pin = [[PINDiskCache alloc] initWithName:@"pin" rootPath:[basePath stringByAppendingPathComponent:@"pin"]];
    
    int count = 1000;
    NSMutableArray *keys = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        NSString *key = @(i).description;
        [keys addObject:key];
    }
    if (randomly) {
        for (NSUInteger i = keys.count; i > 1; i--) {
            [keys exchangeObjectAtIndex:(i - 1) withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
        }
    }
    
    
    for (int i = 0; i < count; i++) {
        YYKVStorageItem *item = [yykvFile getItemForKey:keys[i]];
        NSNumber *value = [NSKeyedUnarchiver unarchiveObjectWithData:item.value];
        if (!value) printf("error!");
    }
    
    for (int i = 0; i < count; i++) {
        YYKVStorageItem *item = [yykvSQLite getItemForKey:keys[i]];
        NSNumber *value = [NSKeyedUnarchiver unarchiveObjectWithData:item.value];
        if (!value) printf("error!");
    }
    
    for (int i = 0; i < count; i++) {
        NSNumber *value = (id)[yy objectForKey:keys[i]];
        if (!value) printf("error!");
    }
    
    
}


+ (void)diskCacheReadLargeDataBenchmarkJJ:(BOOL)randomly {
    NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) firstObject];
    basePath = [basePath stringByAppendingPathComponent:@"FileCacheBenchmarkJJLarge"];
    
    YYKVStorage *yykvFile = [[YYKVStorage alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yykvFile"] type:YYKVStorageTypeFile];
    YYKVStorage *yykvSQLite = [[YYKVStorage alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yykvSQLite"] type:YYKVStorageTypeSQLite];
    YYDiskCache *yy = [[YYDiskCache alloc] initWithPath:[basePath stringByAppendingPathComponent:@"yy"]];
    yy.customArchiveBlock = ^(id object) {return object;};
    yy.customUnarchiveBlock = ^(NSData *object) {return object;};
    PINDiskCache *pin = [[PINDiskCache alloc] initWithName:@"pin" rootPath:[basePath stringByAppendingPathComponent:@"pin"]];
    
    int count = 1000;
    NSMutableArray *keys = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        NSString *key = @(i).description;
        [keys addObject:key];
    }
    if (randomly) {
        for (NSUInteger i = keys.count; i > 1; i--) {
            [keys exchangeObjectAtIndex:(i - 1) withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
        }
    }
    
    
    for (int i = 0; i < count; i++) {
        YYKVStorageItem *item = [yykvFile getItemForKey:keys[i]];
        NSData *value = item.value;
        if (!value) printf("error!");
    }
    
    for (int i = 0; i < count; i++) {
        YYKVStorageItem *item = [yykvSQLite getItemForKey:keys[i]];
        NSData *value = item.value;
        if (!value) printf("error!");
    }
    
    for (int i = 0; i < count; i++) {
        NSData *value = (id)[yy objectForKey:keys[i]];
        if (!value) printf("error!");
    }
}

@end
