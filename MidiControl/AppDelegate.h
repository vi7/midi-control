//
//  AppDelegate.h
//  MidiControl
//
//  Created by Vitaliy on 1/30/13.
//  Copyright (c) 2013 Vitaliy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PianoKbdViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) PianoKbdViewController *viewController;

@end
