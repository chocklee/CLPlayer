//
//  ViewController.m
//  CLPlayer
//
//  Created by chocklee on 2016/9/29.
//  Copyright © 2016年 北京超信. All rights reserved.
//

#import "ViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "CLPlayView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *playView;

@property (nonatomic, strong) CLPlayView *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _player = [CLPlayView clPlayView];
    _player.frame = self.playView.bounds;
    _player.urlString =
    @"http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8";
//    [[NSBundle mainBundle] pathForResource:@"login_video" ofType:@"mp4"];
    [self.playView addSubview:_player];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_player shutdown];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
