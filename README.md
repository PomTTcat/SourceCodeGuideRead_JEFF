# YYModelGuideRead_JEFF
I add some notes to YYModel

  我最近在通读 YYModel 源码，在快速上手使用的时候，发现网上对 YYModel 的使用解释很不完善。哪怕是 YY大神自己的使用说明，我直接复制拿来用也发现有用不了。所以有了这篇文章！这篇文章只对我认为需要补充的说明的方法进行说明。简单用法不再赘述。(复制Json时不要把  ```//JSON```这种同学复制进去，会解析失败的。)
先对 YYModel的协议进行说明！
####1.自定义属性映射
```+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper;```
```
//自定义类的属性
@property NSString      *name;
@property NSInteger     page;
@property NSString      *desc;
@property NSString      *bookID;
```
```
//JSON
{
    "n":"Harry Pottery",
    "p": 256,
    "ext" : {
        "desc" : "A book written by J.K.Rowing."
    },
    "id" : 100010
}
```
```
//custom属性，让 json key 映射到 对象的属性。  该方法在自
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"name" : @"n",
             @"page" : @"p",
             @"desc" : @"ext.desc",                 //key.path
             @"bookID" : @[@"ID",@"id",@"book_id"]};
    //从 json 过来的key 可以是id，ID，book_id。例子中 key 为 id。
}
```
使用这个方法需要在自定义类里面重写该方法。

####2.自定义容器映射
假如你的对象里面有容器（set，array，dic），你可以指定类型中的对象类型，因为YYModel是不知道你容器中储存的类型的。在dic中，你指定的是它 value 的类型。
```+ ( NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;```
```
@interface YYAuthor : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSDate *birthday;
@end
@interface User : NSObject
@property UInt64        uid;
@property NSString      *bookname;
@property (nonatomic, strong)   NSMutableArray<YYAuthor *>    *authors;
@end
```
```
{
    "uid":123456,
    "bookname":"Harry",
    "authors":[
               {
               "birthday":"1991-07-31T08:00:00+0800",
               "name":"G.Y.J.jeff"
               },
               {
               "birthday":"1990-07-31T08:00:00+0800",
               "name":"Z.Q.Y,jhon"
               }
               ]
}
```
```
\\相当于泛型说明
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"authors" : [YYAuthor class]};
}
```

####3.根据字典返回类型
这个方法是可以根据字典里的 数据 来指定当前对象的类型。我对这个方法的理解，假如 Person 是父类，其子类是 Man,Woman。这个时候你可以根据 dic["sex"]中的 value，比如value为 NSString 的 Man，在重写的方法里 return Man.这个时候，你当前的字典转模型的实例就是 Man的实例对象。（此处的 dic就是网络获取的 Json转成的 Dict。
注：这就是多态。
```+ (nullable Class)modelCustomClassForDictionary:(NSDictionary*)dictionary;```
```
{
    "name":"Jeff",
    "age":"26",
    "sex":"Man",
    "wifeName":"ZQY"
}
```
```
//.h
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

//.m
+ (Class)modelCustomClassForDictionary:(NSDictionary*)dictionary {
    if (dictionary[@"sex"] != nil) {
        NSString *runClass = dictionary[@"sex"];
        return NSClassFromString(runClass);
    } else {
        return [self class];
    }
}```
```
    NSData *dataPerson = [self dataWithPath:@"person"];
    Person *person = [Person modelWithJSON:dataPerson];
    [person modelDescription];
```
这个时候你会发现，当前person的类实际上是 Man，而不是 Person。

####4.白名单，黑名单
```
+ (nullable NSArray<NSString *> *)modelPropertyBlacklist;							黑名单
+ (nullable NSArray<NSString *> *)modelPropertyWhitelist;							白名单
```
这两个比较简单。
黑名单，故名思议，黑名单中的属性不会参与字典转模型。
白名单使用比较极端，你用了之后，只有白名单中的属性会参与字典转模型，其他属性都不参与。不推荐使用。
```
//使用了黑名单，将来会剔除黑名单中的属性
+ (NSArray *)modelPropertyBlacklist {
    return @[@"blackListTest"];
}

//白名单使用比较极端，只有白名单中的可以通过。    正常情况使用黑名单即可。
+ (NSArray *)modelPropertyWhitelist {
    return @[@"name"];
}
```

####5.更改字典信息
该方法发生在字典转模型之前。 最后对网络字典做一次处理。
```- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic;```
```
\\原来json
{
    "name":"Jeff",
    "age":"26",
    "sex":"Man",
    "wifeName":"ZQY"
}
\\更改后
{
}
```
```
- (NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic{
    if ([dic[@"sex"] isEqualToString:@"Man"]) {
        return nil;//这里简单演示下，直接返回 nil。相当于不接受男性信息。
    }
    return dic;//女性则不影响字典转模型。
}
```
####6.字典转模型补充
```- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;	```
```
@interface User : NSObject
@property UInt64        uid;
@property NSDate        *created;
@property NSDate        *createdAt;
@property NSString      *bookname;
@end
```
```
{
    "uid":123456,
    "bookname":"Harry",
    "created":"1965-07-31T00:00:00+0000",
    "timestamp" : 1445534567
}
```
字典转模型结束后createdAt属性应该是空的，因为```timestamp``` 和 ```createdAt``` 不一样。但你在这里赋值，手动把```timestamp```的属性赋值给```_createdAt```.这个有点类似第一点的 自定义属性映射（本篇文章第一条）。
注：此处如果 return NO,dic->model将失败。
```
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    NSNumber *timestamp = dic[@"timestamp"];
    if (![timestamp isKindOfClass:[NSNumber class]]) return NO;
    _createdAt = [NSDate dateWithTimeIntervalSince1970:timestamp.floatValue];
    return YES;
}
```

####7.模型转字典补充
```- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic;```
这个方法和第6条是相对应的关系。这里是model->json 的补充。
假如自己model 中有_createdAt，那 model 转到 json 中的```timestamp```会被赋值。
```
- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic {
    if (!_createdAt) return NO;
    dic[@"timestamp"] = @(_createdAt.timeIntervalSince1970);
    return YES;
}
```
注：此处如果 return NO,model->dict将失败。

####8.字典用法和数组的用法
```
+ (nullable NSArray *)modelArrayWithClass:(Class)cls json:(id)json;
+ (nullable NSDictionary *)modelDictionaryWithClass:(Class)cls json:(id)json;
```
```
 [{"birthday":"1991-07-31T08:00:00+0800",
  "name":"G.Y.J.jeff"},
  {"birthday":"1990-07-31T08:00:00+0800",
  "name":"Z.Q.Y,jhon"}]
```
```
@class YYAuthor;
@interface YYAuthor : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSDate *birthday;
@end
```
```
    NSData *dataArr = [self dataWithPath:@"arrayTest"];
    NSArray *arrT = [NSArray modelArrayWithClass:[YYAuthor class] json:dataArr];
    NSLog(@"arrT = %@",arrT);
```
```+ (NSDictionary *)modelDictionaryWithClass:(Class)cls json:(id)json;```
这个方法的意思是只会在对字典的 value 用cls去解析。无法解析key：{key:value(cls)}，这种嵌套的解析无法进行。只会解析第一层的。
```
{"user1": {
    "birthday":"1990-07-31T08:00:00+0800",
    "name":"1Z.Q.Y,jhon"
},"user2":{
    "birthday":"1990-07-31T08:00:00+0800",
    "name":"2Z.Q.Y,jhon"
},"user3":{"user4":{
    "birthday":"1990-07-31T08:00:00+0800",
    "name":"3Z.Q.Y,jhon"
}}}
```
```
    NSData *dataDict = [self dataWithPath:@"dicTest"];
    NSDictionary *dicT = [NSDictionary modelDictionaryWithClass:[YYAuthor class] json:dataDict];
    NSLog(@"dicT = %@",dicT);
```
如果对使用方法还略有不懂，可以下载我的 github 上的工程。里面都是经过测试的。


下面的源码是我在读 YYModel 时添加的大量备注，和 YYModel 的简单使用介绍。
源码地址 :
https://github.com/PomTTcat/YYModelGuideRead_JEFF

这篇文章没讲 model->json，因为那个太简单了。平时使用重点是json->model。
最后的最后，哪里不明白可以一起交流技术！🙂
