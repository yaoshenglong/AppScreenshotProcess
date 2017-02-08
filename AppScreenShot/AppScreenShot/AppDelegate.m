//
//  AppDelegate.m
//  AppScreenShot
//
//  Created by 姚胜龙 on 17/2/8.
//  Copyright © 2017年 姚胜龙. All rights reserved.
//

#import "AppDelegate.h"
#import "CustomIOSAlertView.h"

#define kColor(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

@interface AppDelegate () {
    CustomIOSAlertView *_popAlertView;
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //用户截屏操作
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidTakeScreenshot:)
                                                 name:UIApplicationUserDidTakeScreenshotNotification object:nil];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - privite methods
- (void)userDidTakeScreenshot:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    //人为截屏, 模拟用户截屏行为, 获取所截图片 避免用户连续截屏
    for (UIView *view in self.window.subviews) {
        if ([view isKindOfClass:[CustomIOSAlertView class]]) {
            return;
        }
    }
    UIImage *image = [self imageWithScreenshot];
    _popAlertView = [[CustomIOSAlertView alloc] init];
    [_popAlertView setContainerView:[self createViews:image]];
    [_popAlertView setButtonTitles:[NSMutableArray arrayWithObjects:@"保存",@"分享", nil]];
    [_popAlertView setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
        if (buttonIndex ==0) {
            //在保存图片的时候可以打上自定义的水印
            NSLog(@"保存");
            UIImage *saveImg = [weakSelf waterMarkForImage:image withMarkName:@"markInfo"];
            [weakSelf saveImageAlbum:saveImg];
        }
        if (buttonIndex == 1) {
            NSLog(@"分享");
        }
        [alertView close];
    }];
    [_popAlertView setUseMotionEffects:YES];
    [_popAlertView show];
}

- (UIView *)createViews:(UIImage *)image{

    CGFloat bgViewW = 270.0;
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bgViewW, 310)];
    bgView.layer.cornerRadius = 2.0;
    bgView.layer.masksToBounds = YES;

    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, 35, bgViewW, 275)];
    backView.backgroundColor = kColor(250, 250, 250, 1);
    backView.layer.borderWidth = 0.5;
    backView.layer.borderColor = kColor(0, 0, 0, .1).CGColor;
    [bgView addSubview:backView];
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(73, 35, 128, 229)];
    imageView.image = image;
    [backView addSubview:imageView];

    UIButton *cancleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancleButton.frame = CGRectMake(270-35, 0, 35, 35);
    [cancleButton setBackgroundImage:[UIImage imageNamed:@"shot_close_icon"]
                            forState:UIControlStateNormal];
    [cancleButton addTarget:self action:@selector(alertDismiss) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:cancleButton];
    return bgView;
}

- (void)alertDismiss{
    [_popAlertView close];
}

//截屏操作
- (NSData *)dataWithScreenshotInPNGFormat
{
    CGSize imageSize = CGSizeZero;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        imageSize = [UIScreen  mainScreen].bounds.size;
    }
    else {
        imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height,  [UIScreen mainScreen].bounds.size.width);
    }

    UIGraphicsBeginImageContextWithOptions(imageSize,  NO,  0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {

        CGContextSaveGState(context);

        CGContextTranslateCTM(context, window.center.x, window.center.y);

        CGContextConcatCTM(context, window.transform);

        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);

        if (orientation == UIInterfaceOrientationLandscapeLeft)
        {
            CGContextRotateCTM(context, M_PI_2);
            CGContextTranslateCTM(context, 0, -imageSize.width);
        }
        else if (orientation == UIInterfaceOrientationLandscapeRight)
        {
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -imageSize.height, 0);
        }
        else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
        }
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
        {
            [window  drawViewHierarchyInRect:window.bounds  afterScreenUpdates:YES];
        }
        else
        {
            [window.layer renderInContext:context];
        }
        CGContextRestoreGState(context);
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return  UIImagePNGRepresentation(image);
}


- (UIImage *)imageWithScreenshot
{
    NSData *imageData = [self dataWithScreenshotInPNGFormat];
    return [UIImage imageWithData:imageData];
}

//给截图打上logo或者水印标志
- (UIImage *)waterMarkForImage:(UIImage *)shotImg
                  withMarkName:(NSString *)markName
{
    UIImage *bimage = [UIImage imageNamed:@"codeImage"];
    CGFloat width = shotImg.size.width;
    CGFloat height = shotImg.size.height;
    CGFloat codeImgRedio = 220/375.0f;//拼接图片的高/宽的比例 用来适配屏幕
    UIGraphicsBeginImageContext(CGSizeMake(width, width * codeImgRedio + height));

    [shotImg drawInRect:CGRectMake(0.0, 0.0, width, height)];
    [bimage drawInRect:CGRectMake(0.0, height, width, width * codeImgRedio)];

    NSDictionary *attr = @{
                           NSFontAttributeName: [UIFont boldSystemFontOfSize:10],  //设置字体
                           NSForegroundColorAttributeName :[UIColor orangeColor]  //设置字体颜色
                           };
    [markName drawAtPoint:CGPointMake(0, height + width * codeImgRedio - 20) withAttributes:attr];
    //得到最终的图
    UIImage *finalImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImg;
}

#pragma mark - 保存图片到相册
- (void)saveImageAlbum:(UIImage *)image
{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
         NSLog(@"保存失败！ error = %@", error);
    }
    else {
         NSLog(@"保存成功！ image = %@, contextInfo = %@", image, contextInfo);
    }
}

@end
