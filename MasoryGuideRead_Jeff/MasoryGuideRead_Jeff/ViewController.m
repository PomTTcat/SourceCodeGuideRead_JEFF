//
//  ViewController.m
//  MasoryResearch
//
//  Created by JIE on 2017/2/17.
//  Copyright © 2017年 AppleYJ. All rights reserved.
//
#define MAS_SHORTHAND
#define MAS_SHORTHAND_GLOBALS

#import "ViewController.h"
#import "Masonry.h"

@interface ViewController ()

@property (nonatomic, strong) UIView *vB; //view blue    height:30
@property (nonatomic, strong) UIView *vY; //view yellow  height:30
@property (nonatomic, strong) UIView *vR; //view red     height:30
@property (nonatomic, strong) UIView *vG; //view green   height:100

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, weak)   MASConstraint    *cB;
@property (nonatomic, weak)   MASConstraint    *cY;
@property (nonatomic, weak)   MASConstraint    *cR;
@property (nonatomic, weak)   MASConstraint    *cG;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self systemLayout];
    [self priorityTest];
//    [self setupView];
//    [self closestCommonSuperviewTest];
}

//父控件不一致布局测试
- (void)closestCommonSuperviewTest{
    UIView *redBigView = [UIView new];
    redBigView.backgroundColor = [UIColor redColor];
    [self.view addSubview:redBigView];
    UIEdgeInsets ins = UIEdgeInsetsMake(50, 50, 50, 50);
    [redBigView makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view).offset(ins);
    }];
    
    
    UIView *yellowView = [UIView new];
    yellowView.backgroundColor = [UIColor yellowColor];
    [redBigView addSubview:yellowView];
    UIEdgeInsets ins2 = UIEdgeInsetsMake(50, 50, 150, 50);
    [yellowView makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(redBigView).offset(ins2);
    }];
    
    UIView *grayView = [UIView new];
    grayView.backgroundColor = [UIColor grayColor];
    [yellowView addSubview:grayView];
    UIEdgeInsets ins3 = UIEdgeInsetsMake(20, 20, 20, 20);
    [grayView makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(yellowView).offset(ins3);
    }];
    
    UIView *testV = [UIView new];
    testV.backgroundColor = [UIColor blueColor];
    [redBigView addSubview:testV];
    [testV makeConstraints:^(MASConstraintMaker *make) {
        //test different fatherView
        //        make.top.equalTo(grayView.bottom).offset(15);
        //        make.left.equalTo(yellowView).offset(15);
        //        make.right.equalTo(yellowView).offset(-15);
        //        make.bottom.equalTo(redBigView).offset(-50);
        
        make.topMargin.leftMargin.equalTo(10);
        make.rightMargin.bottomMargin.equalTo(-10);
    }];
    
    
}

//系统 layout 布局参考
- (void)systemLayout{
    UIView *superview = self.view;
    
    UIView *view1 = [[UIView alloc] init];
    view1.translatesAutoresizingMaskIntoConstraints = NO;
    view1.backgroundColor = [UIColor greenColor];
    [superview addSubview:view1];
    
    UIView *view2 = [[UIView alloc] init];
    view2.translatesAutoresizingMaskIntoConstraints = NO;
    view2.backgroundColor = [UIColor blueColor];
    [superview addSubview:view2];
    
    UIEdgeInsets padding = UIEdgeInsetsMake(10, 10, 10, 10);
    
    NSLayoutConstraint *forDescription = nil;
    [superview addConstraints:@[
                                
                                //view1 constraints
                                forDescription = [NSLayoutConstraint constraintWithItem:view1
                                                                              attribute:NSLayoutAttributeTop
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:superview
                                                                              attribute:NSLayoutAttributeTop
                                                                             multiplier:1.0
                                                                               constant:padding.top],
                                
                                [NSLayoutConstraint constraintWithItem:view1
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:superview
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1.0
                                                              constant:padding.left],
                                
                                [NSLayoutConstraint constraintWithItem:view1
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:superview
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0
                                                              constant:-padding.bottom],
                                
                                [NSLayoutConstraint constraintWithItem:view1
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:view2
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                              constant:-padding.right],
                                
                                [NSLayoutConstraint constraintWithItem:view1
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:view2
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1
                                                              constant:0],
                                
                                
                                //view2 constraints
                                [NSLayoutConstraint constraintWithItem:view2
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:superview
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1.0
                                                              constant:padding.top],
                                
                                [NSLayoutConstraint constraintWithItem:view2
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:view1
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:padding.left],
                                
                                [NSLayoutConstraint constraintWithItem:view2
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:superview
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0
                                                              constant:-padding.bottom],
                                
                                [NSLayoutConstraint constraintWithItem:view2
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:superview
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:-padding.right],
                                ]];
    
    [forDescription description];
}

//普通布局
- (void)setupView{
    UIView *baseV = [UIView new];
    baseV.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:baseV];
    [baseV makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view).offset(UIEdgeInsetsZero);
    }];
    
    UIView *greenView = UIView.new;
    greenView.backgroundColor = UIColor.greenColor;
    greenView.layer.borderColor = UIColor.blackColor.CGColor;
    greenView.layer.borderWidth = 2;
    [baseV addSubview:greenView];
    
    
    UIView *redView = UIView.new;
    redView.backgroundColor = UIColor.redColor;
    redView.layer.borderColor = UIColor.blackColor.CGColor;
    redView.layer.borderWidth = 2;
    
    [self.view addSubview:redView];
    
    UIView *blueView = UIView.new;
    blueView.backgroundColor = UIColor.blueColor;
    blueView.layer.borderColor = UIColor.blackColor.CGColor;
    blueView.layer.borderWidth = 2;
    
    [self.view addSubview:blueView];
    
    UIView *superview = self.view;
    int padding = 10;
    
    //if you want to use Masonry without the mas_ prefix
    //define MAS_SHORTHAND before importing Masonry.h see Masonry iOS Examples-Prefix.pch
    [greenView makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(redView);
        make.bottom.equalTo(blueView.top).offset(-padding).key(@"haha");
        
        make.group(^(){
            make.top.greaterThanOrEqualTo(superview.top).offset(padding);
            make.left.equalTo(superview.left).offset(padding);
            make.right.equalTo(redView.left).offset(-padding);
        });
        
        make.height.equalTo(blueView.height);
        
    }];
    //   UILayoutPriority pro = [greenView contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal];
    
    //with is semantic and option
    [redView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(superview.mas_top).with.offset(padding); //with with
        make.left.equalTo(greenView.mas_right).offset(padding); //without with
        make.bottom.equalTo(blueView.mas_top).offset(-padding);
        make.right.equalTo(superview.mas_right).offset(-padding);
        make.width.equalTo(greenView.mas_width);
        
        make.height.equalTo(@[greenView, blueView]); //can pass array of views
    }];
    
    [blueView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(greenView.mas_bottom).offset(padding);
        make.left.equalTo(superview.mas_left).offset(padding);
        make.bottom.equalTo(superview.mas_bottom).offset(-padding);
        make.right.equalTo(superview.mas_right).offset(-padding);
        make.height.equalTo(@[greenView.mas_height, redView.mas_height]); //can pass array of attributes
    }];
    
    
}

//配合 touchesBegan 的一个测试。priorityTest函数代码拷贝自网上。仅仅测试用！
- (void)priorityTest{
    
    self.contentView = [UIView new];
    _contentView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_contentView];
    
    [_contentView makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view).offset(UIEdgeInsetsZero);
    }];
    
    CGFloat spacing = 20.0f;
    
    self.vB = [UIView new];
    [self.contentView addSubview:self.vB];
    [self.vB mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.contentView).insets(UIEdgeInsetsMake(spacing,spacing,0,0));
        make.width.equalTo(@60);
        make.height.equalTo(@30).priorityLow();
    }];
    self.vB.backgroundColor = [UIColor blueColor];
    
    
    self.vY = [UIView new];
    [self.contentView addSubview:self.vY];
    [self.vY mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.vB.mas_right).offset(spacing);
        make.right.top.equalTo(self.contentView).insets(UIEdgeInsetsMake(spacing,0,0,spacing));
        make.height.equalTo(@30).priorityLow();
    }];
    self.vY.backgroundColor = [UIColor yellowColor];
    
    self.vR = [UIView new];
    [self.contentView addSubview:self.vR];
    [self.vR mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vB.mas_bottom).offset(spacing);
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0,spacing,0,spacing));
        make.height.equalTo(@30);
    }];
    self.vR.backgroundColor = [UIColor redColor];
    
    self.vG = [UIView new];
    [self.contentView addSubview:self.vG];
    [self.vG mas_makeConstraints:^(MASConstraintMaker *make) {
        self.cG = make.top.equalTo(self.vR.mas_bottom).offset(spacing);
        make.top.equalTo(self.vB.mas_bottom).offset(spacing).priorityLow(),
        make.left.right.equalTo(self.contentView).insets(UIEdgeInsetsMake(0,spacing,0,spacing));
        make.height.equalTo(@100).priorityLow();
    }];
    self.vG.backgroundColor = [UIColor greenColor];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    
    if (!self.vR.hidden) {
        self.vR.hidden = YES;
        [self.cG deactivate];
    } else {
        self.vR.hidden = NO;
        [self.vG mas_updateConstraints:^(MASConstraintMaker *make) {
            self.cG = make.top.equalTo(self.vR.mas_bottom).offset(20);
        }];
    }
}

@end




