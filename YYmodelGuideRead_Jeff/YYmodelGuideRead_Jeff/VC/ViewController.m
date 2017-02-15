//
//  ViewController.m
//  yymodelTest
//
//  Created by JIE on 2017/2/11.
//  Copyright © 2017年 AppleYJ. All rights reserved.
//

#import "ViewController.h"
#import "ViewController2.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor yellowColor];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.navigationController pushViewController:[ViewController2 new] animated:YES];
}


@end
