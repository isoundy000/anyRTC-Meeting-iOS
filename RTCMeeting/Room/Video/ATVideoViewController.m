//
//  ATVideoViewController.m
//  RTCMeeting
//
//  Created by jh on 2017/10/13.
//  Copyright © 2017年 jh. All rights reserved.
//

#import "ATVideoViewController.h"

@interface ATVideoViewController ()<RTMeetKitDelegate,AnyRTCUserShareBlockDelegate>

//房间名
@property (weak, nonatomic) IBOutlet UIButton *topicButton;
//连接提示
@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;

@property (nonatomic, strong)RTMeetKit *meetKit;
//配置信息
@property (nonatomic, strong)RTMeetOption *option;
//本地显示窗口
@property (nonatomic, strong)UIView *showView;

@property (nonatomic, strong)NSMutableArray *videoArr;

@property (nonatomic, copy)NSString *anyRTCId;
@end

@implementation ATVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hidesKeyControl)];
    [self.view addGestureRecognizer:tap];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.allowRotation = YES;
    [self.view insertSubview:self.showView atIndex:0];
    
    self.anyRTCId = [NSString stringWithFormat:@"anymeeting1000%ld",(long)self.typeMode];
    
    self.topicButton.userInteractionEnabled = NO;
    self.topicButton.layer.mask = [ATCommon getMaskLayer:self.topicButton.bounds byRoundingCorners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:20];
    
    [self itializationMeetKit];
}

- (void)itializationMeetKit{
    //实例化会议对象
    self.meetKit = [[RTMeetKit alloc] initWithDelegate:self andOption:self.option];
    //白板
    self.meetKit.delegate = self;
    
    //本地视频采集窗口
    [self.meetKit setLocalVideoCapturer:self.showView];
    
    NSDictionary *customDict = [NSDictionary dictionaryWithObjectsAndKeys:self.userName,@"nickName",nil];
    NSString *customStr = [ATCommon fromDicToJSONStr:customDict];
    
    //加入会议
    [self.meetKit joinRTC:self.anyRTCId andUserId:[ATCommon randomString:6] andUserData:customStr];
}

#pragma mark - RTMeetKitDelegate
- (void)onRTCJoinMeetOK:(NSString*)strAnyRTCId{
    //加入会议成功的回调
    self.tipsLabel.text = @"RTC会议连接成功...";
}

- (void)onRTCJoinMeetFailed:(NSString*)strAnyRTCId withCode:(int)nCode{
    //加入会议室失败的回调
    [XHToast showCenterWithText:@"加入会议失败"];
}

- (void)onRTCLeaveMeet:(int)nCode{
    //离开会议的回调
    self.tipsLabel.text = @"RTC会议连接失败...";
    if (nCode == 100) {
        [XHToast showCenterWithText:@"网络异常"];
    }
}

-(void)onRTCOpenVideoRender:(NSString*)strRTCPeerId withRTCPubId:(NSString *)strRTCPubId withUserId:(NSString*)strUserId withUserData:(NSString*)strUserData{
    //其他与会者视频接通回调(音视频)
    NSDictionary *dict = [ATCommon fromJsonStr:strUserData];
    UIView *videoView = [self getVideoViewWithRTCPeerId:strRTCPubId withNickName:[dict objectForKey:@"nickName"]];
    [self.view insertSubview:videoView atIndex:99];
    [self.videoArr addObject:videoView];

    [self.meetKit setRTCVideoRender:strRTCPubId andRender:videoView];
}

-(void)onRTCCloseVideoRender:(NSString*)strRTCPeerId withRTCPubId:(NSString *)strRTCPubId withUserId:(NSString*)strUserId{
    @synchronized (self.videoArr){
        //其他会议者离开的回调（音视频）
        for (NSInteger i = 0; i < self.videoArr.count; i++) {
            ATVideoView *videoView = self.videoArr[i];
            if ([videoView.pubId isEqualToString:strRTCPubId]) {
                if (videoView.tag == 1000) {
                    self.showView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
                    self.showView.tag = 1000;
                    [self.view insertSubview:self.showView atIndex:0];
                }
                [self.videoArr removeObjectAtIndex:i];
                [videoView removeFromSuperview];
                //刷新位置
                [self layoutVideoView];
                break;
            }
        }
    }
}

- (void)onRTCAVStatus:(NSString*)strRTCPeerId withAudio:(BOOL)bAudio withVideo:(BOOL)bVideo{
    //其他与会者对音视频的操作的回调（比如对方关闭了音频，对方关闭了视频）
    for (ATVideoView *videoView in self.videoArr) {
        if ([videoView.pubId isEqualToString:strRTCPeerId]) {
            if (!bAudio && !bVideo) {
                [XHToast showCenterWithText:@"对方音视频关闭"];
                return;
            }
            //...操作
        }
    }
}

-(void)onRTCAudioActive:(NSString*)strRTCPeerId withUserId:(NSString *)strUserId withShowTime:(int)nTime{
    //RTC音频检测

}


-(void)onRTCViewChanged:(UIView*)videoView didChangeVideoSize:(CGSize)size{
    //视频窗口大小改变
    @synchronized (self.videoArr) {
        if (videoView == self.showView){
            self.scale = size.width/size.height;
        }
        
        for (ATVideoView *atVideoView in self.videoArr) {
            if (videoView == atVideoView) {
                atVideoView.videoSize = size;
                [self layoutVideoView];
                break;
            }
        }
        [self layoutVideoView];
    }
}

- (void)onRTCUserMessage:(NSString*)strUserId withUserName:(NSString*)strUserName withUserHeader:(NSString*)strUserHeaderUrl withContent:(NSString*)strContent{
    //收到消息回调
    
}

#pragma mark - AnyRTCWriteBlockDelegate
- (void)onRTCCanUseShareEnableResult:(BOOL)scuess{
    //判断是否可以开启共享
}

- (void)onRTCUserShareOpen:(NSString*)strUserShareInfo withUserId:(NSString *)strUserId withUserData:(NSString*)strUserData{
    //共享开启
}

- (void)OnRTCUserShareClose{
    //共享关闭

}

#pragma mark - 刷新显示视图
- (UIView *)getVideoViewWithRTCPeerId:(NSString*)peerId withNickName:(NSString *)nameStr{
    ATVideoView *videoView = [ATVideoView loadVideoView];
    videoView.frame = CGRectZero;
    videoView.nameLabel.text = nameStr;
    videoView.pubId = peerId;
    
    WEAKSELF;
    videoView.videoBlock = ^(NSString *peerId) {
        UIView *displayView = [weakSelf.view viewWithTag:1000];
        
        CGFloat videoY = weakSelf.view.frame.size.height - 100;
        
        CGFloat videoW = CGRectGetWidth(weakSelf.view.frame)/4;
        
        //相同的点击事件(切换回去)
        if ([displayView isKindOfClass:[ATVideoView class]]) {
            ATVideoView *video = (ATVideoView *)displayView;
            
            CGFloat videoH = videoW  * video.videoSize.height/video.videoSize.width;
        
            if ([video.pubId isEqualToString:peerId]) {
                
                displayView.frame = CGRectMake(weakSelf.showView.frame.origin.x, videoY - videoH, videoW, videoH);
                video.tag = 0;
                weakSelf.showView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
                weakSelf.showView.tag = 1000;
                [weakSelf.view insertSubview:displayView atIndex:99];
                [weakSelf.view insertSubview:weakSelf.showView atIndex:0];
                return ;
            }
        }
        
      //切换视图
        for (NSInteger i = 0; i < weakSelf.videoArr.count; i++) {
            ATVideoView *videoView = weakSelf.videoArr[i];
            if ([videoView.pubId isEqualToString:peerId]) {
                if (displayView == weakSelf.showView) {
                    displayView.frame = CGRectMake(videoView.frame.origin.x, videoY - videoW/weakSelf.scale, videoW, videoW/weakSelf.scale);
                } else {
                    CGFloat videoH = videoW * videoView.videoSize.height/videoView.videoSize.width;
                    displayView.frame = CGRectMake(videoView.frame.origin.x, videoY -videoH, videoW, videoH);
                }
                
                if (videoView.videoSize.width > videoView.videoSize.height) {
                    videoView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH * videoView.videoSize.height/videoView.videoSize.width);
                } else {
                    videoView.frame = CGRectMake(0, 0, SCREEN_HEIGHT * videoView.videoSize.width/videoView.videoSize.height, SCREEN_HEIGHT);
                }
                videoView.center = weakSelf.view.center;
                videoView.tag = 1000;
                displayView.tag = 0;
                [weakSelf.view insertSubview:displayView atIndex:99];
                [weakSelf.view insertSubview:videoView atIndex:0];
                break;
            }
        }
    };
    return videoView;
}

- (void)layoutVideoView{
    //四人会议模式
    CGFloat videoW = CGRectGetWidth(self.view.frame)/4;
    
    CGFloat videoY = self.view.frame.size.height - 100;
    
    CGFloat videoX = CGRectGetMidX(self.view.frame) - (videoW/2) * self.videoArr.count;
    
    if (SCREEN_WIDTH < SCREEN_HEIGHT) {//竖屏
        if (self.showView.tag == 1000) {
            self.showView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            self.showView.center = self.view.center;
        } else {
            ATVideoView *videoView = [self.view viewWithTag:1000];
            if (videoView.videoSize.width > videoView.videoSize.height) {
                videoView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH * videoView.videoSize.height / videoView.videoSize.width);
            } else {
                videoView.frame = CGRectMake(0, 0, SCREEN_HEIGHT * videoView.videoSize.width / videoView.videoSize.height, SCREEN_HEIGHT);
            }
            videoView.center = self.view.center;
        }
    } else {//横屏
        if (self.showView.tag == 1000){
            self.showView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            self.showView.center = self.view.center;
        } else {
            ATVideoView *videoView = [self.view viewWithTag:1000];
            if (videoView.videoSize.width > videoView.videoSize.height) {
                videoView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH * videoView.videoSize.height / videoView.videoSize.width);
            } else {
                videoView.frame = CGRectMake(0, 0, SCREEN_HEIGHT * videoView.videoSize.width / videoView.videoSize.height, SCREEN_HEIGHT);
            }
            videoView.center = self.view.center;
        }
    }
    
    for (NSInteger i = 0; i < self.videoArr.count; i++) {
        ATVideoView *videoView = [self.videoArr objectAtIndex:i];
        
        if (videoView.videoSize.height !=0 && videoView.videoSize.width != 0) {
            if (videoView.tag == 1000) {
                self.showView.frame = CGRectMake(videoX, videoY - videoW / self.scale, videoW, videoW / self.scale);
            } else {
                CGFloat videoH = videoW * videoView.videoSize.height/videoView.videoSize.width;
                videoView.frame = CGRectMake(videoX, videoY - videoH, videoW, videoH);
            }
            videoX += videoW;
        }
    }
}

#pragma mark - event
- (IBAction)doSomethingEvents:(UIButton *)sender {
    sender.selected = !sender.selected;
    switch (sender.tag) {
        case 100:
            //翻转摄像头
            [self.meetKit switchCamera];
            [self.meetKit sendUserMessage:@"1" andUserHeader:@"1" andContent:@"1"];
            break;
        case 101:
            //音频
            [self.meetKit setLocalAudioEnable:!sender.selected];
            //[self.meetKit closeWhiteBoard];
            break;
        case 102:
            //挂断
            [self.meetKit leaveRTC];
        {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            appDelegate.allowRotation = NO;
            [self dismissViewControllerAnimated:YES completion:nil];
        }
            break;
        case 103:
            //视频
            [self.meetKit setLocalVideoEnable:!sender.selected];
            //[self.meetKit openWhiteBoard:@""];
            break;
        default:
            break;
    }
}

- (void)hidesKeyControl{
    if (self.showView.tag == 1000) {
        return;
    }
    ATVideoView *displayView = [self.view viewWithTag:1000];
    CGFloat videoY = self.view.frame.size.height - 100;
    
    CGFloat videoW = CGRectGetWidth(self.view.frame)/4;
    
    CGFloat videoH = videoW  * displayView.videoSize.height/displayView.videoSize.width;
    
    displayView.frame = CGRectMake(self.showView.frame.origin.x, videoY - videoH, videoW, videoH);
    
    self.showView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.showView.tag = 1000;
    displayView.tag = 0;
    
    [self.view insertSubview:self.showView atIndex:0];
    [self.view insertSubview:displayView atIndex:99];
}

#pragma mark - other
- (BOOL)shouldAutorotate{
    [super shouldAutorotate];
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self layoutVideoView];
    }];
}

- (UIView *)showView{
    if (!_showView) {
        _showView = [[UIView alloc]init];
        _showView.tag = 1000;
    }
    return _showView;
}

- (NSMutableArray *)videoArr{
    if (!_videoArr) {
        _videoArr = [NSMutableArray array];
    }
    return _videoArr;
}

- (RTMeetOption *)option{
    if(!_option){
        _option = [RTMeetOption defaultOption];
        //设置显示模式
        _option.videoLayOut = RTC_V_1X3;
        //设置视频方向
        _option.videoScreenOrientation = RTMPC_SCRN_Auto;
        //视频质量
        switch (self.typeMode) {
                case RTCMeeting_360P:
                [self.topicButton setTitle:@"四人会议室 - 360P" forState:UIControlStateNormal];
                _option.videoMode = RTCMeet_Videos_Low;
                break;
                case RTCMeeting_720P:
                [self.topicButton setTitle:@"四人会议室 - 720P" forState:UIControlStateNormal];
                _option.videoMode = RTCMeet_Videos_QHD;
                break;
                case RTCMeeting_1080P:
                [self.topicButton setTitle:@"四人会议室 - 1080P" forState:UIControlStateNormal];
                _option.videoMode = RTCMeet_Videos_HD;
                break;
            default:
                break;
        }
    }
    return _option;
}

@end
