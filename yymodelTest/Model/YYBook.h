//
//  YYBook.h
//  last1031
//
//  Created by JIE on 2017/1/24.
//  Copyright © 2017年 AppleYJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+YYModel.h"
#import <UIKit/UIKit.h>

@class YYAuthor;

//---------------------------------------------------------------------------
@interface YYAuthor : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSDate *birthday;
@end
//---------------------------------------------------------------------------
@interface User : NSObject
@property UInt64        uid;
@property NSDate        *created;
@property NSDate        *createdAt;
@property NSString      *bookname;

//自定义 map
@property NSString      *name;
@property NSInteger     page;
@property NSString      *desc;
@property NSString      *bookID;

@property (nonatomic, copy)     NSString    *whiteListTest;
@property (nonatomic, copy)     NSString    *blackListTest;

@property (nonatomic, strong)   YYAuthor    *author;
@property (nonatomic, strong)   NSMutableArray<YYAuthor *>    *authors;



@end
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
@interface YYUserSon : User

@property (nonatomic, copy)     NSString    *userSonString;

@end

//---------------------------------------------------------------------------
@interface YYShadow :NSObject <NSCoding, NSCopying>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CGSize size;
@end
//---------------------------------------------------------------------------
