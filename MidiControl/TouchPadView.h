//
//  TouchPadView.h
//  MidiControl
//
//  Created by Vitaliy on 3/7/13.
//  Copyright (c) 2013 Vitaliy. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TouchPadViewDelegate;

@interface TouchPadView : UIView

@property (assign, nonatomic) id <TouchPadViewDelegate> delegate;

@end

@protocol TouchPadViewDelegate <NSObject>

- (void)touchPadView:(TouchPadView*)touchPadView touchedWithValueX:(short)valX;
- (void)touchPadView:(TouchPadView*)touchPadView touchedWithValueY:(short)valY;

@end
