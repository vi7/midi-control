//
//  AppDelegate.m
//  MidiControl
//
//  Created by Vitaliy on 1/30/13.
//  Copyright (c) 2013 Vitaliy. All rights reserved.
//

#import "AppDelegate.h"

#import "PianoKbdViewController.h"
#import "TouchControlViewController.h"

@interface AppDelegate ()
{
    PianoKbdViewController *_pianoCont;
}

- (void)saveData;

@end

@implementation AppDelegate

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.

    UINavigationController *navCont = [[[NSBundle mainBundle] loadNibNamed:@"MCNavigationController" owner:nil options:nil] objectAtIndex:0];
    
    self.window.rootViewController = navCont;
    [self.window makeKeyAndVisible];
    
    _pianoCont = [((UINavigationController*)self.window.rootViewController).viewControllers objectAtIndex:0];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [self saveData];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
//====== Create network socket when app became active ======
    
    if (![_pianoCont createSocket]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network error" message:@"Error creating socket" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }

//============================================================

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [self saveData];
}

- (void)saveData
{
    NSDictionary *mcDataDict = @{@"Oct1Num" : @((short)_pianoCont.oct1Stepper.value),
                                @"Oct1ChanNum" : @((short)_pianoCont.oct1ChanStepper.value),
                                @"Oct1VelVal" : @((short)_pianoCont.oct1VelSlider.value),
                                @"Oct2Num" : @((short)_pianoCont.oct2Stepper.value),
                                @"Oct2ChanNum" : @((short)_pianoCont.oct2ChanStepper.value),
                                @"Oct2VelVal" : @((short)_pianoCont.oct2VelSlider.value),
                                @"IPMidiPort" : @((short)[_pianoCont.portNumTextField.text intValue]),
                                @"XCCNum" : @(_pianoCont.xCCNum),
                                @"YCCNum" : @(_pianoCont.yCCNum)
                                };
    
    NSString *docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [docDirPath stringByAppendingPathComponent:@"MCData.plist"];
    
    [mcDataDict writeToFile:plistPath atomically:YES];
}

@end
