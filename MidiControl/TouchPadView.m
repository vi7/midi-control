//
//  TouchPadView.m
//  MidiControl
//
//  Created by Vitaliy on 3/7/13.
//  Copyright (c) 2013 Vitaliy. All rights reserved.
//

#import "TouchPadView.h"
#import "MCDefines.h"

@implementation TouchPadView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPnt = [touch locationInView:self];
    
//    NSLog(@"beginX: %d", (short)(touchPnt.x*POINT2VAL));
//    NSLog(@"beginY: %d", (short)(-(touchPnt.y*POINT2VAL-127)));
    
    [self.delegate touchPadView:self touchedWithValueX:(short)(touchPnt.x*POINT2VAL)];
    [self.delegate touchPadView:self touchedWithValueY:(short)(-(touchPnt.y*POINT2VAL-127))];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint prevTouchPnt;
    CGPoint curTouchPnt = [touch locationInView:self];
    short prevValX, prevValY, curValX, curValY;
    
    if ([self pointInside:curTouchPnt withEvent:event]) {
        prevTouchPnt = [touch previousLocationInView:self];
        prevValX = (short)(prevTouchPnt.x*POINT2VAL);
        prevValY = (short)(-(prevTouchPnt.y*POINT2VAL-127));
        curValX = (short)(curTouchPnt.x*POINT2VAL);
        curValY = (short)(-(curTouchPnt.y*POINT2VAL-127));
        if (curValX != prevValX) {
//            NSLog(@"moved: %d", (short)prevTouchPnt.x);
            [self.delegate touchPadView:self touchedWithValueX:curValX];
            
        }
        if (curValY != prevValY) {
            [self.delegate touchPadView:self touchedWithValueY:curValY];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.delegate touchPadView:self touchedWithValueX:0];
    [self.delegate touchPadView:self touchedWithValueY:0];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
