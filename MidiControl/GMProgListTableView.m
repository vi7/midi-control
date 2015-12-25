//
//  GMProgListTableView.m
//  MidiControl
//
//  Created by Vitaliy on 3/3/13.
//  Copyright (c) 2013 Vitaliy. All rights reserved.
//

#import "GMProgListTableView.h"

@implementation GMProgListTableView

//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
//    }
//    return self;
//}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _popped = NO;
        [self setScrollEnabled:NO];
    }
    return self;
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
