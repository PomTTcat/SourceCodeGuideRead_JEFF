//
//  ViewController.m
//  SDWebImageGuideRead_Jeff
//
//  Created by JIE on 2018/10/30.
//  Copyright © 2018 Applejj. All rights reserved.
//

#import "ViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *jeImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *imageString = @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=252837708,616471489&fm=26&gp=0.jpg";
    
    [self.jeImageView sd_setImageWithURL:[NSURL URLWithString:imageString] placeholderImage:nil options:SDWebImageCacheMemoryOnly completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        NSLog(@"finish 1");
    }];
    // Do any additional setup after loading the view, typically from a nib.
}


@end
