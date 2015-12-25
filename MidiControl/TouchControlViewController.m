//
//  TouchControlViewController.m
//  MidiControl
//
//  Created by Vitaliy on 2/21/13.
//  Copyright (c) 2013 Vitaliy. All rights reserved.
//

#import "TouchControlViewController.h"
#import "MCDefines.h"
#import "PianoKbdViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface TouchControlViewController ()
{
    PianoKbdViewController *_pianoCont;
}

@end

@implementation TouchControlViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *viewBackImg = [UIImage imageNamed:@"back-tex.png"];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:viewBackImg]];
    
#pragma mark TouchPadImage layer manipulation
    
    [self.touchPadImage.layer setCornerRadius:7];
    
//==========================================
    
    self.touchPadView.delegate = self;
    
    _pianoCont = (PianoKbdViewController*)[self.navigationController.viewControllers objectAtIndex:0];
    
#pragma mark Load data from plists
    
    [self.xCCNumStepper setValue:_pianoCont.xCCNum];
    [self.yCCNumStepper setValue:_pianoCont.yCCNum];
    
//===================================================
    
#pragma mark Set labels text
    
    [self.xCCNumLabel setText:[NSString stringWithFormat:@"CC%d", (short)self.xCCNumStepper.value]];
    [self.yCCNumLabel setText:[NSString stringWithFormat:@"CC%d", (short)self.yCCNumStepper.value]];
    
// =============================================
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark TouchPadView delegate

- (void)touchPadView:(TouchPadView *)touchPadView touchedWithValueX:(short)valX
{
//    NSLog(@"Value X:%d\n", valX);
    unsigned char _msg[3];    
    
    [_pianoCont setXCCVal:valX];
    [_pianoCont createMidiMessage:_msg WithEvent:MCControlChange andNoteId:0];
    [_pianoCont sendMidiMessage:_msg WithSize:3];
    
}

- (void)touchPadView:(TouchPadView *)touchPadView touchedWithValueY:(short)valY
{
//    NSLog(@"Value Y:%d\n", valY);
    
    unsigned char _msg[3];
    
    [_pianoCont setYCCVal:valY];
    [_pianoCont createMidiMessage:_msg WithEvent:MCControlChange andNoteId:12];
    [_pianoCont sendMidiMessage:_msg WithSize:3];
    
}

//================================

#pragma mark IB Actions

- (IBAction)changeModeBtnClicked:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)xCCNumChanged:(UIStepper *)sender
{
    [self.xCCNumLabel setText:[NSString stringWithFormat:@"CC%d", (short)sender.value]];
    [_pianoCont setXCCNum:(short)sender.value];
}

- (IBAction)yCCNumChanged:(UIStepper *)sender
{
    [self.yCCNumLabel setText:[NSString stringWithFormat:@"CC%d", (short)sender.value]];
    [_pianoCont setYCCNum:(short)sender.value];
}

//======================================

- (void)viewDidUnload {
    
    [self setTouchPadView:nil];
    [self setXCCNumLabel:nil];
    [self setXCCNumStepper:nil];
    [self setYCCNumLabel:nil];
    [self setYCCNumStepper:nil];
    [self setTouchPadImage:nil];
    [super viewDidUnload];
}
- (void)dealloc {
    [_touchPadView release];
    [_xCCNumLabel release];
    [_xCCNumStepper release];
    [_yCCNumLabel release];
    [_yCCNumStepper release];
    [_touchPadImage release];
    [super dealloc];
}
@end
