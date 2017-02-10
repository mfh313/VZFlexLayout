//
//  VZFBlankNodeBackingView.h
//  VZFlexLayout-Example
//
//  Created by heling on 2017/1/22.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VZFNodeBackingViewInterface.h"
#import "VZFBankNodeRenderer.h"
#import "VZFBackingViewProtocol.h"

@interface VZFBlankNodeBackingView : UIView<VZFNodeBackingViewInterface, VZFBackingViewProtocol>

@property(nonatomic,strong) VZFBankNodeRenderer* blankRenderer;

@end