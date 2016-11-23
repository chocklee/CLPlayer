//
//  CLPlayView.h
//  CLPlayer
//
//  Created by chocklee on 2016/9/30.
//  Copyright © 2016年 北京超信. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLPlayView : UIView

/*视频url*/
@property (nonatomic, copy) NSString *urlString;

/*初始化方法*/
+ (instancetype)clPlayView;

/*播放*/
- (void)play;

/*暂停*/
- (void)pause;

/*准备播放:调用播放方法前，必须调用*/
- (void)prepareToPlay;

/*停止播放*/
- (void)stop;

/*是否正在播放*/
- (BOOL)isPlaying;

/*关闭:关闭播放器，释放内存*/
- (void)shutdown;

@end
