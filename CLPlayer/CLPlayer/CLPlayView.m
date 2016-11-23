//
//  CLPlayView.m
//  CLPlayer
//
//  Created by chocklee on 2016/9/30.
//  Copyright © 2016年 北京超信. All rights reserved.
//

#import "CLPlayView.h"
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface CLPlayView ()

@property (nonatomic, strong) id<IJKMediaPlayback> player;
@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UIButton *bigPlayButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UISlider *slider;
// 当前播放时间
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
// 剩余播放时间
@property (weak, nonatomic) IBOutlet UILabel *remainingTimeLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (assign, nonatomic) BOOL isMediaSliderBeingDragged;

@end

@implementation CLPlayView

- (void)dealloc {
    [self removeNotification];
}

#pragma mark - init
// 初始化方法
+ (instancetype)clPlayView {
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] firstObject];
}

- (void)awakeFromNib {
    // 修改slider滑块的图片
    [self.slider setThumbImage:[UIImage imageNamed:@"circle"] forState:UIControlStateNormal];
    [self refreshMediaControl];
}

#pragma mark - public
- (void)play {
    [_player play];
}

- (void)pause {
    [_player pause];
}

- (void)prepareToPlay {
    [_player prepareToPlay];
}

- (void)stop {
    [_player stop];
}

- (BOOL)isPlaying {
    return [_player isPlaying];
}

- (void)shutdown {
    [_player shutdown];
}

#pragma mark - private
- (IBAction)bigPlayButtonAction:(UIButton *)sender {
    [self changePlayStatus];
}

- (IBAction)playButtonAction:(UIButton *)sender {
    [self changePlayStatus];
}

- (IBAction)didSliderTouchDown:(id)sender {
    _isMediaSliderBeingDragged = YES;
}
- (IBAction)didSliderTouchCancel:(id)sender {
    _isMediaSliderBeingDragged = NO;
}
- (IBAction)didSliderTouchUpOutside:(id)sender {
    _isMediaSliderBeingDragged = NO;
}
- (IBAction)didSliderTouchUpInside:(id)sender {
    _player.currentPlaybackTime = self.slider.value;
    _isMediaSliderBeingDragged = NO;
}
- (IBAction)didSliderValueChanged:(id)sender {
    [self refreshMediaControl];
}

// 改变播放状态
- (void)changePlayStatus {
    if ([_player isPlaying]) {
        [_player pause];
    } else {
        [_player play];
    }
    [_bigPlayButton setHidden:![_player isPlaying]];
    _playButton.selected = [_player isPlaying];
}

// 刷新播放器控件
- (void)refreshMediaControl {
    NSTimeInterval duration = _player.duration;
    NSInteger intDuration = duration + 0.5;
    if (intDuration > 0) {
        self.slider.maximumValue = duration;
        self.remainingTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
    } else {
        self.slider.maximumValue = 1.0f;
        self.remainingTimeLabel.text = @"--:--";
    }
    
    // position
    NSTimeInterval position;
    if (_isMediaSliderBeingDragged) {
        position = self.slider.value;
    } else {
        position = _player.currentPlaybackTime;
    }
    NSInteger intPosition = position + 0.5;
    if (intDuration > 0) {
        self.slider.value = position;
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intPosition / 60), (int)(intPosition % 60)];
    } else {
        self.slider.value = 0.0f;
        self.currentTimeLabel.text = @"--:--";
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
}

#pragma mark - setter
- (void)setUrlString:(NSString *)urlString {
    if (_urlString != urlString) {
        _urlString = urlString;
        
        // 设置Log信息打印
        [IJKFFMoviePlayerController setLogReport:YES];
        // 设置Log等级
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
        // 检查当前FFmpeg版本是否匹配
        [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
        // IJKFFOptions 是对视频的配置信息
        IJKFFOptions *options = [IJKFFOptions optionsByDefault];
        
        // 配置player
        _player = [[IJKFFMoviePlayerController alloc] initWithContentURLString:_urlString withOptions:options];
        _player.view.frame = self.bounds;
        _player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // 缩放模式
        _player.scalingMode = IJKMPMovieScalingModeAspectFill;
        // 设置是否自动播放
        _player.shouldAutoplay = YES;
        // 设置后台暂停
        [_player setPauseInBackground:YES];
        [self insertSubview:_player.view atIndex:0];
        
        [_player prepareToPlay];
        
        if ([_player shouldAutoplay]) {
            // 按钮的状态
            [_bigPlayButton setHidden:YES];
            _playButton.enabled = NO;
            // 转动小菊花
            _activityIndicatorView.hidden = NO;
            [_activityIndicatorView startAnimating];
        } else {
            // 按钮的状态
            [_bigPlayButton setHidden:NO];
            _playButton.selected = YES;
            // 转动小菊花
            _activityIndicatorView.hidden = YES;
        }
        // 设置监听
        [self addNotifications];
    }
}

#pragma mark - notification func
- (void)loadStateDidChange:(NSNotification *)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"---------------------加载状态改变通知: IJKMovieLoadStatePlayThroughOK(加载成功): %d\n",(int)loadState);
        _playButton.enabled = YES;
        [_activityIndicatorView stopAnimating];
        _activityIndicatorView.hidden = YES;
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"---------------------加载状态改变通知: IJKMPMovieLoadStateStalled(加载停滞): %d\n", (int)loadState);
    } else {
        NSLog(@"---------------------加载状态改变通知: 其他状态: %d\n", (int)loadState);
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification *)notification {
    NSLog(@"---------------------准备播放状态改变通知\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification *)notification {
    switch (_player.playbackState) {
            
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"---------------------播放状态改变通知 %d: stoped(播放结束)", (int)_player.playbackState);
            [_bigPlayButton setHidden:NO];
            _playButton.selected = YES;
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"---------------------播放状态改变通知 %d: playing(播放中)", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"---------------------播放状态改变通知 %d: paused(播放暂停)", (int)_player.playbackState);
            [_bigPlayButton setHidden:NO];
            _playButton.selected = YES;
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"---------------------播放状态改变通知 %d: interrupted(播放中断)", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"---------------------播放状态改变通知 %d: seeking", (int)_player.playbackState);
            _activityIndicatorView.hidden = NO;
            [_activityIndicatorView startAnimating];
            break;
        }
        default: {
            NSLog(@"---------------------播放状态改变通知 %d: 其他状态", (int)_player.playbackState);
            break;
        }
    }
}

- (void)moviePlayBackFinish:(NSNotification *)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded: {
            NSLog(@"---------------------播放结束状态通知: IJKMPMovieFinishReasonPlaybackEnded(播放结束): %d\n", reason);
            break;
        }
        case IJKMPMovieFinishReasonUserExited: {
            NSLog(@"---------------------播放结束状态通知: IJKMPMovieFinishReasonUserExited(用户退出): %d\n", reason);
            break;
        }
        case IJKMPMovieFinishReasonPlaybackError: {
            NSLog(@"---------------------播放结束状态通知: IJKMPMovieFinishReasonPlaybackError(播放出错): %d\n", reason);
            break;
        }
        default: {
            NSLog(@"---------------------播放结束状态通知: 其他原因: %d\n", reason);
            break;
        }
    }
}

#pragma mark - add Notification
- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
}
#pragma mark - remove Notification
- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
}


@end
