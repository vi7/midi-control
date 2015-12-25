//
//  PianoKbdViewController.m
//  MidiControl
//
//  Created by Vitaliy on 1/30/13.
//  Copyright (c) 2013 Vitaliy. All rights reserved.
//

#import "PianoKbdViewController.h"
#import "NoteKeyView.h"
#import "TouchControlViewController.h"
#import "GMProgListTableView.h"
#import "MCDefines.h"
#import <QuartzCore/QuartzCore.h>

@interface PianoKbdViewController ()
{
    struct sockaddr_in _addr;
    int _sock;
    short _prevPortNum;
    BOOL _displayingSettsView;
}

@property (retain, nonatomic) NSArray *gmProgList;

- (void)notePressedInView:(NoteKeyView*)view;
- (void)noteReleasedInView:(NoteKeyView*)view;
- (void)changeOct2ControlsStateWithAnimationDuration:(NSTimeInterval)time;
- (void)showSettsView:(BOOL)val;
- (void)popupGMProgTableView:(GMProgListTableView*)tableView;

@end

@implementation PianoKbdViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _displayingSettsView = NO;
    
    [self.portNumTextField setText:[NSString stringWithFormat:@"%d", IPMIDI_PORT]];
    
    UIImage *thumbNormImg = [UIImage imageNamed:@"slideknob-tex.png"];
    UIImage *thumbHltdImg = [UIImage imageNamed:@"slideknob-hltd-tex.png"];
    UIImage *viewBackImg = [UIImage imageNamed:@"back-tex.png"];
    
    for (UISlider *slider in self.view.subviews) {
        if ([slider isMemberOfClass:[UISlider class]]) {
            [slider setThumbImage:thumbNormImg forState:UIControlStateNormal];
            [slider setThumbImage:thumbHltdImg forState:UIControlStateHighlighted];
        }
    }
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:viewBackImg]];
    [self.settsView setBackgroundColor:[UIColor colorWithPatternImage:viewBackImg]];
    
    
#pragma mark Load data from plists
    
    NSString *docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *mcDataPath = [docDirPath stringByAppendingPathComponent:@"MCData.plist"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:mcDataPath]) {
        mcDataPath = [[NSBundle mainBundle] pathForResource:@"MCData" ofType:@"plist"];
    }
    
    NSDictionary *mcDataDict = [NSDictionary dictionaryWithContentsOfFile:mcDataPath];
    
    if (mcDataDict) {
        [self.oct1Stepper setValue:[[mcDataDict objectForKey:@"Oct1Num"] shortValue]];
        [self.oct2Stepper setValue:[[mcDataDict objectForKey:@"Oct2Num"] shortValue]];
        [self.oct1ChanStepper setValue:[[mcDataDict objectForKey:@"Oct1ChanNum"] shortValue]];
        [self.oct2ChanStepper setValue:[[mcDataDict objectForKey:@"Oct2ChanNum"] shortValue]];
        [self.oct1VelSlider setValue:[[mcDataDict objectForKey:@"Oct1VelVal"] shortValue]];
        [self.oct2VelSlider setValue:[[mcDataDict objectForKey:@"Oct2VelVal"] shortValue]];
        short ipMidiPort = [[mcDataDict objectForKey:@"IPMidiPort"] shortValue];
        [self.portNumTextField setText:[NSString stringWithFormat:@"%d", ipMidiPort]];
        [self setXCCNum:[[mcDataDict objectForKey:@"XCCNum"] shortValue]];
        [self setYCCNum:[[mcDataDict objectForKey:@"YCCNum"] shortValue]];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Read error" message:@"Error reading app data, setting default values" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
    NSString *gmProgPath = [[NSBundle mainBundle] pathForResource:@"GMProgram" ofType:@"plist"];
    [self setGmProgList:[NSArray arrayWithContentsOfFile:gmProgPath]];

// ===================================================

#pragma mark Set labels text
    
    [self.oct1NumLabel setText:[NSString stringWithFormat:@"octave: %d", (short)self.oct1Stepper.value]];
    [self.oct2NumLabel setText:[NSString stringWithFormat:@"octave: %d", (short)self.oct2Stepper.value]];
    [self.oct1ChanLabel setText:[NSString stringWithFormat:@"channel: %d", (short)self.oct1ChanStepper.value]];
    [self.oct2ChanLabel setText:[NSString stringWithFormat:@"channel: %d", (short)self.oct2ChanStepper.value]];
    [self.oct1VelValLabel setText:[NSString stringWithFormat:@"%d", (short)self.oct1VelSlider.value]];
    [self.oct2VelValLabel setText:[NSString stringWithFormat:@"%d", (short)self.oct2VelSlider.value]];

// =============================================
    
    [self changeOct2ControlsStateWithAnimationDuration:0];
    [self.portNumTextField setInputAccessoryView:self.numPadBar];
    [self.portNumTextField setRightView:self.defPortBtn];
    [self.portNumTextField setRightViewMode:UITextFieldViewModeAlways];
    
#pragma mark GMProgListTables layer manipulation
    
    CALayer *oct1TableLayer = [self.oct1GMProgListTable layer];
    CALayer *oct2TableLayer = [self.oct2GMProgListTable layer];
    [oct1TableLayer setCornerRadius:5];
    [oct1TableLayer setBorderWidth:3];
    [oct1TableLayer setBorderColor:[UIColor lightGrayColor].CGColor];
    
    [oct2TableLayer setCornerRadius:5];
    [oct2TableLayer setBorderWidth:3];
    [oct2TableLayer setBorderColor:[UIColor lightGrayColor].CGColor];

//==============================================
    
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

#pragma mark Piano keyboard touches handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPnt = [touch locationInView:self.kbdView];
    NoteKeyView *view = (NoteKeyView*)[self.kbdView hitTest:touchPnt withEvent:event];

    [self notePressedInView:view];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];    
    CGPoint prevTouchPnt = [touch previousLocationInView:self.kbdView];
    CGPoint curTouchPnt = [touch locationInView:self.kbdView];
    NoteKeyView *prevView = (NoteKeyView*)[self.kbdView hitTest:prevTouchPnt withEvent:event];
    NoteKeyView *curView = (NoteKeyView*)[self.kbdView hitTest:curTouchPnt withEvent:event];
    
    if (curView!=prevView) {
        [self notePressedInView:curView];
        [self noteReleasedInView:prevView];
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint prevTouchPnt = [touch previousLocationInView:self.kbdView];
    CGPoint curTouchPnt = [touch locationInView:self.kbdView];
    NoteKeyView *prevView = (NoteKeyView*)[self.kbdView hitTest:prevTouchPnt withEvent:event];
    NoteKeyView *curView = (NoteKeyView*)[self.kbdView hitTest:curTouchPnt withEvent:event];
    
    [self noteReleasedInView:prevView];
    [self noteReleasedInView:curView];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (void)notePressedInView:(NoteKeyView *)view
{
    unsigned char _msg[3];
    
    if ([view isMemberOfClass:[NoteKeyView class]]) {
        [self createMidiMessage:_msg WithEvent:MCNoteOn andNoteId:view.tag];
        [self sendMidiMessage:_msg WithSize:3];
        [view setPressed:YES];
        [view setBackgroundColor:[UIColor blueColor]];
    }
}

- (void)noteReleasedInView:(NoteKeyView *)view
{
    unsigned char _msg[3];
    
    if ([view isMemberOfClass:[NoteKeyView class]] && view.pressed) {
        [self createMidiMessage:_msg WithEvent:MCNoteOff andNoteId:view.tag];
        [self sendMidiMessage:_msg WithSize:3];
        //        NSLog(@"touch ended in viewtag %d", view.tag);
        [view setPressed:NO];
        [view setBackgroundColor:[UIColor clearColor]];
    }
}

// =============================================================

#pragma mark Networking methods

- (void)sendMidiMessage:(StringPtr)msg WithSize:(size_t)msgSz
{
//    size_t msgSz = sizeof(msg)-1;
//    printf("%x:%x:%x\n", msg[0], msg[1], msg[2]);
    
    if (sendto(_sock,msg,msgSz,0,(struct sockaddr *) &_addr,sizeof(_addr)) == -1) {
//        perror("sendto");
//        exit(1);
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network error" message:@"Error sending MIDI data" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
//        [alert release];
        return;
    }
//    free(msg);
}

- (BOOL)createSocket
{
    BOOL retVal = YES;
    
    /* create what looks like an ordinary UDP socket */
    if ((_sock=socket(AF_INET,SOCK_DGRAM,IPPROTO_IP)) < 0) {
        //        perror("socket");
        //        exit(1);
        retVal = NO;
    }
    
    /* set up destination address */
    memset(&_addr,0,sizeof(_addr));
    _addr.sin_family=AF_INET;
    _addr.sin_addr.s_addr=inet_addr(IPMIDI_GROUP);
    _addr.sin_port=htons((short)[self.portNumTextField.text intValue]);
    
    return retVal;
}

// ================================================

- (void)createMidiMessage:(StringPtr)msg WithEvent:(MCMidiEvent)midiEvent andNoteId:(NSUInteger)noteId
{
    switch (midiEvent) {
        case MCNoteOff:
            if (noteId<12) {
                msg[0] = NOTE_OFF_MSG + (unsigned char)self.oct1ChanStepper.value-1;
                msg[1] = noteId + (unsigned char)self.oct1Stepper.value*12;
                msg[2] = (unsigned char)self.oct1VelSlider.value;
            } else {
                msg[0] = NOTE_OFF_MSG + (unsigned char)self.oct2ChanStepper.value-1;
                msg[1] = noteId-12 + (unsigned char)self.oct2Stepper.value*12;
                msg[2] = (unsigned char)self.oct2VelSlider.value;
            }
            break;
        case MCNoteOn:
            if (noteId<12) {
                msg[0] = NOTE_ON_MSG + (unsigned char)self.oct1ChanStepper.value-1;
                msg[1] = noteId + (unsigned char)self.oct1Stepper.value*12;
                msg[2] = (unsigned char)self.oct1VelSlider.value;
            } else {
                msg[0] = NOTE_ON_MSG + (unsigned char)self.oct2ChanStepper.value-1;
                msg[1] = noteId-12 + (unsigned char)self.oct2Stepper.value*12;
                msg[2] = (unsigned char)self.oct2VelSlider.value;
            }
            break;
        case MCControlChange:
            if (noteId<12) {
                msg[0] = CC_MSG + (unsigned char)self.oct1ChanStepper.value-1;
                msg[1] = self.xCCNum;
                msg[2] = self.xCCVal;
            } else {
                msg[0] = CC_MSG + (unsigned char)self.oct1ChanStepper.value-1;
                msg[1] = self.yCCNum;
                msg[2] = self.yCCVal;
            }
            break;
        case MCProgChange:
            if (noteId<12) {
                msg[0] = PROGRAM_MSG + (unsigned char)self.oct1ChanStepper.value-1;
                msg[1] = (short)[self.oct1GMProgListTable indexPathForSelectedRow].row;
            } else {
                msg[0] = PROGRAM_MSG + (unsigned char)self.oct2ChanStepper.value-1;
                msg[1] = (short)[self.oct2GMProgListTable indexPathForSelectedRow].row;
            }
            break;
        case MCPitchControl:
            if (noteId<12) {
                msg[0] = PITCH_MSG + (unsigned char)self.oct1ChanStepper.value-1;
                msg[1] = (short)self.oct1PitchSlider.value & 0x007F; //bitmasking 0-6bits from pitch value LSB
                msg[2] = (short)self.oct1PitchSlider.value >> 8;
            } else {
                msg[0] = PITCH_MSG + (unsigned char)self.oct2ChanStepper.value-1;
                msg[1] = (short)self.oct2PitchSlider.value & 0x007F; //bitmasking 0-6bits from pitch value LSB
                msg[2] = (short)self.oct2PitchSlider.value >> 8;
            }
            break;
        default:
            break;
    }
}

- (void)changeOct2ControlsStateWithAnimationDuration:(NSTimeInterval)time
{
    if (self.oct1ChanStepper.value == self.oct2ChanStepper.value) {
        [self.oct2GMProgListTable setUserInteractionEnabled:NO];
        NSIndexPath *oct1ProgIndPath = [self.oct1GMProgListTable indexPathForSelectedRow];
        [self.oct2GMProgListTable selectRowAtIndexPath:oct1ProgIndPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [UIView animateWithDuration:time animations:^{
                                                        [self.oct2GMProgListTable setAlpha:0.4];
                                                        [self.oct2GMProgLabel setAlpha:0.4];
                                                    }];
        [self.oct2PitchSlider setUserInteractionEnabled:NO];
        [self.oct2PitchSlider setAlpha:0.4];
        [self.oct2PitchLabel setAlpha:0.4];
        [self.oct2PitchSliderBack setAlpha:0.4];
    } else {
        [self.oct2GMProgListTable setUserInteractionEnabled:YES];
        [UIView animateWithDuration:time animations:^{
                                                        [self.oct2GMProgListTable setAlpha:1];
                                                        [self.oct2GMProgLabel setAlpha:1];
                                                    }];
        [self.oct2PitchSlider setUserInteractionEnabled:YES];
        [self.oct2PitchSlider setAlpha:1];
        [self.oct2PitchLabel setAlpha:1];
        [self.oct2PitchSliderBack setAlpha:1];
    }
}

#pragma mark PortNum textfield delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _prevPortNum = [textField.text intValue];
}

// restricting textfield text to valid port numbers

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL retVal = YES;
    
    if ([newText intValue] < 0 || [newText intValue] > USHRT_MAX) {
        [self.portNumTextField setText:[NSString stringWithFormat:@"%d",IPMIDI_PORT]];
        retVal = NO;
    }
    
    return retVal;
}

// ========================================================

- (void)showSettsView:(BOOL)val
{
    
    if (val) {
        [UIView animateWithDuration:0.35
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self.settsView setFrame:CGRectMake(0, 0, 480, 150)];
                             [self.settsBtn setCenter:CGPointMake(self.settsBtn.center.x, self.settsBtn.center.y+116)];
                             [self.settsBtn setTransform:CGAffineTransformMakeRotation(M_PI)];
                         }
                         completion:nil];
    } else {
        [UIView animateWithDuration:0.35
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self.settsView setFrame:CGRectMake(0, -150, 480, 150)];
                             [self.settsBtn setCenter:CGPointMake(self.settsBtn.center.x, self.settsBtn.center.y-116)];
                             [self.settsBtn setTransform:CGAffineTransformIdentity];
                         }
                         completion:nil];
    }
    
    _displayingSettsView = val;
}

#pragma mark General MIDI programs list tableview datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.gmProgList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProgNameCell"];
    
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"GMProgListCell" owner:self options:nil];
        cell = self.gmProgListCell;
        [self setGmProgListCell:nil];
    }
    
    if (![tableView indexPathForSelectedRow]) {
        NSIndexPath *selectionIndPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [tableView selectRowAtIndexPath:selectionIndPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
    
    if ([tableView indexPathForSelectedRow].row == indexPath.row) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    [cell.textLabel setText:[self.gmProgList objectAtIndex:indexPath.row]];
    
    return cell;
}

// =============================================================================

#pragma mark General MIDI programs list tableview delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    short tag = tableView.tag;
    BOOL popped = ((GMProgListTableView*)tableView).popped;
    
    if (!popped) {
        
        [self popupGMProgTableView:(GMProgListTableView*)tableView];
        [(GMProgListTableView*)tableView setPopped:!popped];
        [tableView setScrollEnabled:!popped];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    
    } else {
        
        unsigned char _msg[2];
        [self createMidiMessage:_msg WithEvent:MCProgChange andNoteId:12*tag];
        [self sendMidiMessage:_msg WithSize:2];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [(GMProgListTableView*)tableView setPopped:!popped];
        [tableView setScrollEnabled:!popped];
        [UIView animateWithDuration:0.3 animations:^{
            tableView.frame = CGRectMake(8+242*tag, 56, 170, 34);
        }];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
    
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setAccessoryType:UITableViewCellAccessoryNone];
}

// ===========================================================================

- (void)popupGMProgTableView:(GMProgListTableView *)tableView
{
    short tag = tableView.tag;
    
    [UIView animateWithDuration:0.28 animations:^{
        tableView.frame = CGRectMake(8+242*tag, 0, 170, 150);
    }];
    
    CAKeyframeAnimation *popupAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    CATransform3D transf1 = CATransform3DMakeScale(1, 1.1, 1);
    CATransform3D transf2 = CATransform3DMakeScale(1, 0.97, 1);
    CATransform3D transf3 = CATransform3DMakeScale(1, 1, 1);
    
    NSArray *transfValues = @[[NSValue valueWithCATransform3D:transf1],[NSValue valueWithCATransform3D:transf2],[NSValue valueWithCATransform3D:transf3]];
    
    [popupAnim setValues:transfValues];
    
    CFTimeInterval localLayerTime = [tableView.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    
    [popupAnim setBeginTime:localLayerTime+0.27];
    [popupAnim setDuration:0.3];
    
    [tableView.layer addAnimation:popupAnim forKey:@"popupTransform"];
}

#pragma mark IB Actions

- (IBAction)octNumChanged:(UIStepper *)sender
{
    NSString *labelText = [NSString stringWithFormat:@"octave: %d", (short)sender.value];
    NSString *keyPath = [NSString stringWithFormat:@"oct%dNumLabel.text", sender.tag+1];
    
    [self setValue:labelText forKeyPath:keyPath];
    
    // ============== Disabling note keys with >127 note codes ==============
    
    if ((int)sender.value == 10) {
        for (NoteKeyView *view in self.kbdView.subviews)
        {
            if (view.tag>(7+12*sender.tag) && view.tag<(12+12*sender.tag)) {
                [view setUserInteractionEnabled:NO];
            }
        }
    } else {
        for (NoteKeyView *view in self.kbdView.subviews)
        {
            if (view.tag>(7+12*sender.tag) && view.tag<(12+12*sender.tag)) {
                [view setUserInteractionEnabled:YES];
            }
        }
    }
    
    // ======================================================================

}

- (IBAction)oct1ChanNumChanged:(UIStepper *)sender
{
    unsigned char _msg[3];
    NSIndexPath *prog0IndPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self.oct1ChanLabel setText:[NSString stringWithFormat:@"channel: %d", (short)sender.value]];
    
    // ============== Set pitch and program for selected MIDI channel ==============
    
    [self createMidiMessage:_msg WithEvent:MCPitchControl andNoteId:0];
    [self sendMidiMessage:_msg WithSize:3];
    [self.oct1GMProgListTable selectRowAtIndexPath:prog0IndPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    [self createMidiMessage:_msg WithEvent:MCProgChange andNoteId:0];
    [self sendMidiMessage:_msg WithSize:2];
    // =============================================================================
    
    [self changeOct2ControlsStateWithAnimationDuration:0.4];
}

- (IBAction)oct2ChanNumChanged:(UIStepper *)sender
{
    unsigned char _msg[3];
    NSIndexPath *prog0IndPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self.oct2ChanLabel setText:[NSString stringWithFormat:@"channel: %d", (short)sender.value]];
    
    // ============== Set pitch and program for selected MIDI channel ==============    
    
    [self createMidiMessage:_msg WithEvent:MCPitchControl andNoteId:12];
    [self sendMidiMessage:_msg WithSize:3];
    [self.oct2GMProgListTable selectRowAtIndexPath:prog0IndPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    [self createMidiMessage:_msg WithEvent:MCProgChange andNoteId:12];
    [self sendMidiMessage:_msg WithSize:2];
    // ===============================================================================
    
    [self changeOct2ControlsStateWithAnimationDuration:0.4];
}

- (IBAction)octVelChanged:(UISlider *)sender
{
    NSString *labelText = [NSString stringWithFormat:@"%d", (short)sender.value];
    NSString *keyPath = [NSString stringWithFormat:@"oct%dVelValLabel.text", sender.tag];
    
    [self setValue:labelText forKeyPath:keyPath];
}

- (IBAction)pitchChanged:(UISlider *)sender
{
    unsigned char _msg[3];
    
    [self createMidiMessage:_msg WithEvent:MCPitchControl andNoteId:sender.tag];
    [self sendMidiMessage:_msg WithSize:3];
}

- (IBAction)pitchReleased:(UISlider *)sender
{
    unsigned char _msg[3];
    
    [sender setValue:16384 animated:YES];
    [self createMidiMessage:_msg WithEvent:MCPitchControl andNoteId:sender.tag];
    [self sendMidiMessage:_msg WithSize:3];
}

- (IBAction)changeModeBtnPressed:(UIButton *)sender
{
    TouchControlViewController *touchCont = [[TouchControlViewController alloc] initWithNibName:@"TouchControlViewController" bundle:nil];
    [self.navigationController pushViewController:touchCont animated:YES];
    [touchCont release];
}

- (IBAction)settsBtnPressed:(UIButton *)sender
{
    [self showSettsView:!_displayingSettsView];
}

- (IBAction)numPadCancelPressed:(UIBarButtonItem *)sender
{
    [self.portNumTextField setText:[NSString stringWithFormat:@"%d", _prevPortNum]];
    [self.portNumTextField resignFirstResponder];
}

- (IBAction)numPadSavePressed:(UIBarButtonItem *)sender
{
    _addr.sin_port=htons((short)[self.portNumTextField.text intValue]);
    [self.portNumTextField resignFirstResponder];
}

- (IBAction)defPortBtnPressed:(UIButton *)sender
{
    [self.portNumTextField setText:[NSString stringWithFormat:@"%d", IPMIDI_PORT]];
    _addr.sin_port=htons((short)[self.portNumTextField.text intValue]);
}

- (IBAction)allNoteOffBtnPressed:(UIButton *)sender
{
    unsigned char _msg[3];
    short prevXCCNum = self.xCCNum;
    [self setXCCNum:123];
    [self setXCCVal:0];
    
    [self createMidiMessage:_msg WithEvent:MCControlChange andNoteId:0];
    [self sendMidiMessage:_msg WithSize:3];
    
    [self setXCCNum:prevXCCNum];
}

//=====================================================

- (void)dealloc {
    [_gmProgList release];
    [_kbdView release];
    [_oct1NumLabel release];
    [_oct2NumLabel release];
    [_oct1Stepper release];
    [_oct2Stepper release];
    [_oct1ChanStepper release];
    [_oct2ChanStepper release];
    [_oct1ChanLabel release];
    [_oct2ChanLabel release];
    [_oct1VelValLabel release];
    [_oct2VelValLabel release];
    [_oct1VelSlider release];
    [_oct2VelSlider release];
    [_oct1PitchSlider release];
    [_oct2PitchSlider release];
    [_oct2PitchLabel release];
    [_settsView release];
    [_settsBtn release];
    [_portNumTextField release];
    [_numPadBar release];
    [_gmProgListCell release];
    [_oct1GMProgListTable release];
    [_oct2GMProgListTable release];
    [_oct2GMProgLabel release];
    [_defPortBtn release];
    [_oct2PitchSliderBack release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setKbdView:nil];
    [self setOct1NumLabel:nil];
    [self setOct2NumLabel:nil];
    [self setOct1Stepper:nil];
    [self setOct2Stepper:nil];
    [self setOct1ChanStepper:nil];
    [self setOct2ChanStepper:nil];
    [self setOct1ChanLabel:nil];
    [self setOct2ChanLabel:nil];
    [self setOct1VelValLabel:nil];
    [self setOct2VelValLabel:nil];
    [self setOct1VelSlider:nil];
    [self setOct2VelSlider:nil];
    [self setOct1PitchSlider:nil];
    [self setOct2PitchSlider:nil];
    [self setOct2PitchLabel:nil];
    [self setSettsView:nil];
    [self setSettsBtn:nil];
    [self setPortNumTextField:nil];
    [self setNumPadBar:nil];
    [self setGmProgListCell:nil];
    [self setOct1GMProgListTable:nil];
    [self setOct2GMProgListTable:nil];
    [self setOct2GMProgLabel:nil];
    [self setDefPortBtn:nil];
    [self setOct2PitchSliderBack:nil];
    [super viewDidUnload];
}

@end
