//
//  PianoKbdViewController.h
//  MidiControl
//
//  Created by Vitaliy on 1/30/13.
//  Copyright (c) 2013 Vitaliy. All rights reserved.
//

#import <UIKit/UIKit.h>
//#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
//#include <time.h>
//#include <string.h>
//#include <stdio.h>
//#include <stdlib.h>

typedef NS_ENUM(NSUInteger, MCMidiEvent) {
    MCNoteOff,
    MCNoteOn,
    MCControlChange,
    MCProgChange,
    MCPitchControl
};

@class GMProgListTableView;

@interface PianoKbdViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) short xCCNum;
@property (assign, nonatomic) short yCCNum;
@property (assign, nonatomic) short xCCVal;
@property (assign, nonatomic) short yCCVal;
@property (retain, nonatomic) IBOutlet UIView *kbdView;
@property (retain, nonatomic) IBOutlet UIView *settsView;
@property (retain, nonatomic) IBOutlet UILabel *oct1NumLabel;
@property (retain, nonatomic) IBOutlet UILabel *oct2NumLabel;
@property (retain, nonatomic) IBOutlet UIStepper *oct1Stepper;
@property (retain, nonatomic) IBOutlet UIStepper *oct2Stepper;
@property (retain, nonatomic) IBOutlet UILabel *oct1ChanLabel;
@property (retain, nonatomic) IBOutlet UILabel *oct2ChanLabel;
@property (retain, nonatomic) IBOutlet UIStepper *oct1ChanStepper;
@property (retain, nonatomic) IBOutlet UIStepper *oct2ChanStepper;
@property (retain, nonatomic) IBOutlet UILabel *oct1VelValLabel;
@property (retain, nonatomic) IBOutlet UILabel *oct2VelValLabel;
@property (retain, nonatomic) IBOutlet UISlider *oct1VelSlider;
@property (retain, nonatomic) IBOutlet UISlider *oct2VelSlider;
@property (retain, nonatomic) IBOutlet UITextField *oct2PitchSliderBack;
@property (retain, nonatomic) IBOutlet UILabel *oct2PitchLabel;
@property (retain, nonatomic) IBOutlet UISlider *oct1PitchSlider;
@property (retain, nonatomic) IBOutlet UISlider *oct2PitchSlider;
@property (retain, nonatomic) IBOutlet UIButton *settsBtn;
@property (retain, nonatomic) IBOutlet UITextField *portNumTextField;
@property (retain, nonatomic) IBOutlet UIToolbar *numPadBar;
@property (retain, nonatomic) IBOutlet UITableViewCell *gmProgListCell;
@property (retain, nonatomic) IBOutlet UILabel *oct2GMProgLabel;
@property (retain, nonatomic) IBOutlet GMProgListTableView *oct1GMProgListTable;
@property (retain, nonatomic) IBOutlet GMProgListTableView *oct2GMProgListTable;
@property (retain, nonatomic) IBOutlet UIButton *defPortBtn;

- (void)sendMidiMessage:(StringPtr)msg WithSize:(size_t)msgSz;
- (BOOL)createSocket;
- (void)createMidiMessage:(StringPtr)msg WithEvent:(MCMidiEvent)midiEvent andNoteId:(NSUInteger)noteId;
- (IBAction)octNumChanged:(UIStepper *)sender;
- (IBAction)oct1ChanNumChanged:(UIStepper *)sender;
- (IBAction)oct2ChanNumChanged:(UIStepper *)sender;
- (IBAction)octVelChanged:(UISlider *)sender;
- (IBAction)pitchChanged:(UISlider *)sender;
- (IBAction)pitchReleased:(UISlider *)sender;
- (IBAction)changeModeBtnPressed:(UIButton *)sender;
- (IBAction)settsBtnPressed:(UIButton *)sender;
- (IBAction)numPadCancelPressed:(UIBarButtonItem *)sender;
- (IBAction)numPadSavePressed:(UIBarButtonItem *)sender;
- (IBAction)defPortBtnPressed:(UIButton *)sender;
- (IBAction)allNoteOffBtnPressed:(UIButton *)sender;

@end
