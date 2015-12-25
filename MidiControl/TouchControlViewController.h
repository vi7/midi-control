//
//  TouchControlViewController.h
//  MidiControl
//
//  Created by Vitaliy on 2/21/13.
//  Copyright (c) 2013 Vitaliy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TouchPadView.h"

@interface TouchControlViewController : UIViewController <TouchPadViewDelegate>

@property (retain, nonatomic) IBOutlet UIImageView *touchPadImage;
@property (retain, nonatomic) IBOutlet TouchPadView *touchPadView;
@property (retain, nonatomic) IBOutlet UILabel *xCCNumLabel;
@property (retain, nonatomic) IBOutlet UIStepper *xCCNumStepper;
@property (retain, nonatomic) IBOutlet UILabel *yCCNumLabel;
@property (retain, nonatomic) IBOutlet UIStepper *yCCNumStepper;

- (IBAction)changeModeBtnClicked:(UIButton *)sender;
- (IBAction)xCCNumChanged:(UIStepper *)sender;
- (IBAction)yCCNumChanged:(UIStepper *)sender;

@end
