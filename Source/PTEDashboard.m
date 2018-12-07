//
//  PTEDashboard.m
//  LumberjackConsole
//
//  Created by Ernesto Rivera on 2012/12/17.
//  Copyright (c) 2013-2017 PTEz.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "PTEDashboard.h"
#import "PTEConsoleLogger.h"
#import <QuartzCore/QuartzCore.h>
#import <NBUCore/NBUCore.h>

#define kMinimumHeight 20.0

static PTEDashboard * _sharedDashboard;

@interface PTERootController : UIViewController
@property (nonatomic, strong) IBOutlet PTEConsoleTableView *tableView;
@end

@implementation PTERootController

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)prefersStatusBarHidden
{
    // Fixes missing status bar.
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView dataSource];
}

@end

@implementation PTEDashboard
{
    CGSize _screenSize;
    UIWindow * _keyWindow;
    UITableView * _consoleTableView;
    NSArray * _fullscreenOnlyViews;
}

+ (PTEDashboard *)sharedDashboard
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      CGRect frame = UIScreen.mainScreen.applicationFrame;
                      _sharedDashboard = [[self alloc] initWithFrame:frame];
                  });
    return _sharedDashboard;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.windowLevel = UIWindowLevelStatusBar + 1;
        
        _screenSize = [UIScreen mainScreen].applicationFrame.size;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
        {
            self.tintColor = [UIColor lightGrayColor];
        }
        
        // Load Storyboard
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LumberjackConsole" bundle:[NSBundle bundleForClass:[self class]]];
        PTERootController *vc = [storyboard instantiateInitialViewController];
        _consoleTableView = vc.tableView;
        self.rootViewController = vc;
			
        // Save references
        NSArray * subviews = self.rootViewController.view.subviews;
        _consoleTableView = subviews[0];
        _fullscreenOnlyViews = @[subviews[2], subviews[3], subviews[4]];
        
        // Add a pan gesture recognizer for the toggle button
        UIPanGestureRecognizer * panRecognizer = [[UIPanGestureRecognizer alloc]
                                                  initWithTarget:self
                                                  action:@selector(handlePanGesture:)];
        [subviews[1] addGestureRecognizer:panRecognizer];
        
        // Configure other window properties
//        self.layer.anchorPoint = CGPointZero;
//        self.windowLevel = UIWindowLevelStatusBar + 1;
//        self.frame = UIScreen.mainScreen.applicationFrame;
        
        // Listen to orientation changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleStatusBarOrientationChange:)
                                                         name:UIDeviceOrientationDidChangeNotification
                                                       object:nil];
    }
    return self;
}

- (void)dealloc
{
    // Stop observing
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)show
{
    self.hidden = NO;
    self.minimized = YES;
    [[_consoleTV logger] updateOrScheduleTableViewUpdateInConsoleQueue];
}

- (void)hide
{
    self.hidden = YES;
    self.minimized = YES;
}

- (void)handleStatusBarOrientationChange:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isMaximized) {
            [self setMaximized:YES];
        }
        else {
            [self setMinimized:YES];
        }
    });
}

- (IBAction)toggleFullscreen:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    [UIView animateWithDuration:0.2
                     animations:^
     {
         if (sender.selected)
         {
             self.maximized = YES;
         }
         else
         {
             self.minimized = YES;
         }
     }];
}

- (IBAction)toggleAdjustLevelsController:(id)sender
{
    // Not available?
    if (!NSClassFromString(@"PTEAdjustLevelsTableView"))
    {
        [[[UIAlertView alloc] initWithTitle:@"NBULog Required"
                                    message:@"NBULog is required to dynamically adjust log levels."
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        return;
    }
    
    // Hide adjust levels controller?
    if (self.rootViewController.presentedViewController)
    {
        [self.rootViewController dismissViewControllerAnimated:NO
                                                    completion:NULL];
    }
    // Present adjust levels controller
    else
    {
        UIViewController * controller = [self.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"adjustLevels"];
        [self.rootViewController presentViewController:controller
                                              animated:NO
                                            completion:NULL];
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    [self setWindowHeight:[gestureRecognizer locationInView:self].y];
}

- (BOOL)isMaximized
{
    return self.frame.size.height == _screenSize.height;
}

- (void)setMaximized:(BOOL)maximized
{
    [self setWindowHeight:_screenSize.height];
}

- (BOOL)isMinimized
{
    return self.frame.size.height == kMinimumHeight;
}

- (void)setMinimized:(BOOL)minimized
{
    [self setWindowHeight:kMinimumHeight];
}

- (void)setWindowHeight:(CGFloat)height
{
    
    _screenSize = [UIScreen mainScreen].applicationFrame.size;
    CGRect applicationFrame = [UIScreen mainScreen].applicationFrame;
    
    // Validate height
    height = MAX(kMinimumHeight, height);
    if (_screenSize.height - height < kMinimumHeight * 2.0)
    {
        // Snap to bottom
//        height = _screenSize.height-20;
    }
    
    if (height == kMinimumHeight) {
        CGRect tableFrame = _consoleTableView.superview.frame;
//        tableFrame.origin.x += 20.0;
        tableFrame.size.width -= 20.0;
        _consoleTableView.frame = tableFrame;
        self.frame = CGRectMake(applicationFrame.origin.x,
                                applicationFrame.origin.y,
                                _screenSize.width,
                                height);
        _consoleTableView.contentOffset = CGPointMake(0.0,
                                                      MAX(_consoleTableView.contentOffset.y,
                                                          _consoleTableView.tableHeaderView.bounds.size.height));
    }
    else {
        // MAXIMIZED
        _consoleTableView.userInteractionEnabled = YES;
        _consoleTableView.frame = _consoleTableView.superview.frame;
        self.frame = applicationFrame;
    }
    
    // Change keyWindow to enable keyboard input
    if (height == _screenSize.height)
    {
        // Maximized
        if (!_keyWindow)
        {
            _keyWindow = [UIApplication sharedApplication].keyWindow;
            [_keyWindow resignKeyWindow];
            [self makeKeyWindow];
            //            NSLog(@"+++ %@ -> %@", _keyWindow, [UIApplication sharedApplication].keyWindow);
        }
        
        // Show fullscreen-only views
        for (UIView * view in _fullscreenOnlyViews)
        {
            view.hidden = NO;
        }
    }
    else
    {
        // Minimized
        if (_keyWindow)
        {
            [_keyWindow makeKeyWindow];
            _keyWindow = nil;
            //            NSLog(@"+++ %@ <-", [UIApplication sharedApplication].keyWindow);
        }
        
        // Hide fullscreen-only views
        for (UIView * view in _fullscreenOnlyViews)
        {
            view.hidden = YES;
        }
    }
}

@end

