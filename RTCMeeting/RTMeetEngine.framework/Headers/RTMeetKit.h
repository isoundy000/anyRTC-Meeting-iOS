//
//  RTMeetKit.h
//  RTMeetEngine
//
//  Created by EricTao on 16/11/10.
//  Copyright © 2016年 EricTao. All rights reserved.
//

#ifndef RTMeetKit_h
#define RTMeetKit_h

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "RTMeetKitDelegate.h"
#import "RTCCommon.h"
#import "AnyRTCUserShareBlockDelegate.h"
#import "RTMeetOption.h"

@interface RTMeetKit : NSObject {
    
}

/**
 实例化会议对象

 @param delegate RTC相关回调代理
 @return 会议对象
 */
- (instancetype)initWithDelegate:(id<RTMeetKitDelegate>)delegate andOption:(RTMeetOption *)option;

#pragma mark Common function
/**
 设置本地音频是否传输
 
 @param bEnable 打开或关闭本地音频
 说明：yes为传输音频,no为不传输音频，默认传输
 */
- (void)setLocalAudioEnable:(bool)bEnable;

/**
 设置本地视频是否传输
 
 @param bEnable 打开或关闭本地视频
 说明：yes为传输视频，no为不传输视频，默认视频传输
 */
- (void)setLocalVideoEnable:(bool)bEnable;

/**
 切换前后摄像头
 说明:切换本地前后摄像头。
 */
- (void)switchCamera;

/**
 设置扬声器开关

 @param bOn YES:打开扬声器，NO:关闭扬声器
 说明：扬声器默认打开
 */
- (void)setSpeakerOn:(bool)bOn;

/**
 设置音频检测
 
 @param bOn 是否开启音频检测
 说明：默认打开
 */
- (void)setAudioActiveCheck:(bool)bOn;

/**
 设置本地视频采集窗口
 
 @param render 视频显示对象
 @param bFront 是否用前置摄像头
 说明：该方法用于本地视频采集。
 */
#if TARGET_OS_IPHONE
- (void)setLocalVideoCapturer:(UIView*)render;
#else
- (void)setLocalVideoCapturer:(NSView*) render;
#endif

#pragma mark RTC function for line
/**
 加入会议

 @param strAnyRTCId strAnyRTCId 会议号（可以在AnyRTC 平台获得，也可以根据自己平台，分配唯一的一个ID号）
 @param strUserId 播在开发者自己平台的id，可选
 @param strUserData 播在开发者自己平台的相关信息（昵称，头像等），可选。(限制512字节)
 @return 加入会议成功或者失败
 */
- (BOOL)joinRTC:(NSString*)strAnyRTCId andUserId:(NSString*)strUserId andUserData:(NSString*)strUserData;

/**
 离开会议室
 说明：相当于析构函数
 */
- (void)leaveRTC;
/**
 设置显示其他端视频窗口
 
 @param strRTCPubId RTC服务生成流的ID (用于标识与会者发布的流)；
 @param render 对方视频的窗口，本地设置；
 说明：该方法用于与会者接通后，与会者视频接通回调中（OnRTCOpenVideoRender）使用。
 */
#if TARGET_OS_IPHONE
- (void)setRTCVideoRender:(NSString*)strRTCPubId andRender:(UIView*)render;
#else
- (void)setRTCVideoRender:(NSString*)strRTCPubId andRender:(NSView*)render;
#endif

#pragma mark - 消息
/**
 发送消息
 
 @param strUserName 用户昵称(最大256字节)，不能为空，否则发送失败；
 @param strUserHeaderUrl 用户头像(最大512字节)，可选
 @param strContent 消息内容(最大1024字节)不能为空，否则发送失败；
 @return YES/NO 发送成功/发送失败
 说明：默认普通消息。以上参数均会出现在参会者的消息回调方法中，如果加入RTC（joinRTC）没有设置strUserid，发送失败。
 */

- (BOOL)sendUserMessage:(NSString*)strUserName andUserHeader:(NSString*)strUserHeaderUrl andContent:(NSString*)strContent;

#pragma mark - 白板功能模块

/**
 设置共享回调
 */
@property (nonatomic, weak)id<AnyRTCUserShareBlockDelegate>delegate;

/**
 判断是否可以共享

 @param nType 共享类型
 说明：类型，自己平台设定，比如1:为白板，２:为文档
 */
- (void)canShareUser:(int)nType;
/**
 打开共享信息

 @param strShearInfo 共享相关信息(限制512字节)
 说明：打开白板成功与失败，参考onRTCSetWhiteBoardEnableResult 回调方法
 */
- (void)openUserShareInfo:(NSString *)strShearInfo;

/**
 关闭共享
 */
- (void)closeUserShare;
@end

#endif /* RTMeetKit_h */
