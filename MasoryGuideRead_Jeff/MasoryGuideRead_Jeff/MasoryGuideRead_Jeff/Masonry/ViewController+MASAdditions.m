//
//  UIViewController+MASAdditions.m
//  Masonry
//
//  Created by Craig Siemens on 2015-06-23.
//
//

#import "ViewController+MASAdditions.h"

#ifdef MAS_VIEW_CONTROLLER

@implementation MAS_VIEW_CONTROLLER (MASAdditions)

//self.topLayoutGuide   https://blog.kyleduo.com/2014/10/22/ios_learning_autolayout_toplayoutguide/
/*
 一个独立的ViewController
 状态栏可见      topLayoutGuide表示状态栏 底部
 状态栏不可见     ViewController的上边缘
 
 如果导航栏（Navigation Bar）可见，topLayoutGuide表示导航栏的底部。
 如果状态栏可见，topLayoutGuide表示状态栏的底部。
 如果都不可见，表示ViewController的上边缘。
 
 viewDidLoad                               topLayoutGuide = 0
 viewWillAppear，viewWillLayoutSubview 之后 topLayoutGuide = 20；
 
 topLayoutGuide默认是.bottom的。 如果设置成.top那就不管怎样都是控制器的顶端。
 
 */
- (MASViewAttribute *)mas_topLayoutGuide {
    return [[MASViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}
- (MASViewAttribute *)mas_topLayoutGuideTop {
    return [[MASViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (MASViewAttribute *)mas_topLayoutGuideBottom {
    return [[MASViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}

- (MASViewAttribute *)mas_bottomLayoutGuide {
    return [[MASViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (MASViewAttribute *)mas_bottomLayoutGuideTop {
    return [[MASViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (MASViewAttribute *)mas_bottomLayoutGuideBottom {
    return [[MASViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}



@end

#endif
