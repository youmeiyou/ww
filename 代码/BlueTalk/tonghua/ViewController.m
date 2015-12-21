//
//  ViewController.m
//  tonghua
//
//  Created by gjh on 15/12/19.
//  Copyright © 2015年 gjh. All rights reserved.
//
 /*
  MCNearbyServiceAssistant 可以接受数据，并处理用户请求链接的响应。会弹出默认的提示框，并处理链接
  MCNeerbyServiceAdvertiser 可以接受数据，并处理用户请求链接的响应，但是这个类有回调，告知有用户要与你的设备链接，可以自定义提示框，以及链接处理
  MCNearByServiceBrowser 用户搜索附近用户，并且可以对搜索到到用户发出邀请，加入某个会话中
  MCPeerID 这是用户信息
  MCSeesion启动和管理会话中的交流，发送数据。
  
  */
#import "ViewController.h"
#import "NSObject+HUD.h"
#import "Message.h"
#define kReceiveCell @"ReceiveCell"
#define kSendCell @"SenderCell"
#define kServiceType @"MyserviceType"
@import MultipeerConnectivity;

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,MCNearbyServiceAdvertiserDelegate,MCSessionDelegate,MCBrowserViewControllerDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomC;
@property (weak, nonatomic) IBOutlet UITextField *textField;
// 用于广播自己，让别人可以发现你，并且链接
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) MCNearbyServiceAdvertiser *advertiser;
// 当前用户的信息，本机用户信息
@property (nonatomic,strong) MCPeerID *peerID;
//对方信息
@property (nonatomic,copy) MCPeerID *otherPeerID;
//会话：信息的传递
@property (nonatomic,strong) MCSession *session;
//搜索附近到蓝牙用户
@property (nonatomic,strong) MCNearbyServiceBrowser *browser;
//搜索附近蓝牙用户的界面，视图控制器
@property (nonatomic,strong) MCBrowserViewController *browserVC;
@property (nonatomic,strong) NSMutableArray *messageList;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
}
#pragma  广播自己，让别人发现自己
- (MCNearbyServiceAdvertiser *) advertiser{
    if (!_advertiser) {
        _advertiser = [[MCNearbyServiceAdvertiser alloc]initWithPeer:self.peerID discoveryInfo:nil serviceType:kServiceType];
        _advertiser.delegate = self;
        
    }
    return _advertiser;
}
#pragma 创建自身的信息
- (MCPeerID *)peerID{
    if (!_peerID) {
        _peerID = [[MCPeerID alloc]initWithDisplayName:@"～～guo"];
    }
    return _peerID;
}
//当别人请求链接时，触发
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nonnull))invitationHandler{
    NSLog(@"didRecieveInvitation");
    NSString *message = [NSString stringWithFormat:@"收到了来自 %@ 的邀请",peerID.displayName];
    
    [self showAlert:message];
    
    //传YES 代表同意邀请，使用session对象来保存这个邀请
    invitationHandler(YES,self.session);
}
#pragma 会话
- (MCSession *)session{
    //参数2 加密
    if (!_session) {
        _session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
        _session.delegate = self;
    }
    return _session;
}
#pragma 会话协议
//会话状态发生改变。正在链接
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"didchange");
    switch (state) {
        case MCSessionStateConnected:
            [self showAlert:@"已连接"];
            self.title = peerID.displayName;
            break;
        case MCSessionStateConnecting:
            [self showAlert:@"正在连接"];
            self.title = @"正在连接";
            break;
        case MCSessionStateNotConnected:
            [self showAlert:@"已断开"];
            self.title = @"已断开";
        default:
            break;
    }
}
//收到数据
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSLog(@"didRecievedata");
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceiveData%@%@",peerID.displayName,str);
    Message *message = [Message new];
    message.fromMe = NO;
    message.content = str;
    [self.messageList addObject:message];
    [[NSOperationQueue mainQueue]addOperationWithBlock:^{
       
        [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.messageList.count -1 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        
         
    }];
}
//会话连接时
- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler{
    NSLog(@"certificate");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
    
    [UIAlertView bk_showAlertViewWithTitle:peerID.displayName message:@"是否接受此人邀请？" cancelButtonTitle:@"拒绝" otherButtonTitles:@"接受" handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            certificateHandler(YES);
            self.otherPeerID = peerID;
            [_browserVC dismissViewControllerAnimated:YES completion:nil];
        }else{
            certificateHandler(NO);
        }
    }];
    }];
    
}



#pragma 点击操作
- (IBAction)showSelf:(id)sender {
    [self.advertiser startAdvertisingPeer];
    
}
- (IBAction)searhDevice:(id)sender {
    _browserVC = [[MCBrowserViewController alloc]initWithServiceType:kServiceType session:self.session];
    _browserVC.delegate = self;
    [self presentViewController:_browserVC animated:YES completion:nil];
}
#pragma brower协议
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
   [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendText:(id)sender {
     [self.view endEditing:YES];
    
    if (_textField.text.length == 0) {
        [self showAlert:@"内容为空"];
        return;
    }
    NSData *data = [_textField.text dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    [self.session sendData:data toPeers:@[_otherPeerID] withMode:MCSessionSendDataReliable error:&error];
    if (error) {
        NSLog(@"error: %@",error);
    }else{
        NSLog(@"发送成功");
        Message *message = [Message new];
        message.fromMe = YES;
        message.content = _textField.text;
        [self.messageList addObject:message];
        _textField.text = @"";
        
        [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.messageList.count -1 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        
        
    }
}
#pragma 键盘
- (void)keyboardWillShow:(NSNotification *)noti{
    CGFloat height = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    NSTimeInterval duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions option = [noti.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    [UIView animateWithDuration:duration delay:0 options:option animations:^{
        _bottomC.constant = height;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}
- (void)keyboardWillHide:(NSNotification *)noti{
    
    NSTimeInterval duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions option = [noti.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    [UIView animateWithDuration:duration delay:0 options:option animations:^{
        _bottomC.constant = 0;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}
#pragma 生命 周期
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
}
#pragma tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messageList.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *indentify = kReceiveCell;
    Message *message = self.messageList[indexPath.row];
    if (message.fromMe) {
        indentify = kSendCell;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:indentify];
    UILabel *contentlb = (UILabel *)[cell.contentView viewWithTag:100];
    contentlb.text = message.content;
    contentlb.layer.cornerRadius = 6;
    contentlb.layer.masksToBounds = YES;
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

- (NSMutableArray *)messageList {
	if(_messageList == nil) {
		_messageList = [[NSMutableArray alloc] init];
	}
	return _messageList;
}

@end
