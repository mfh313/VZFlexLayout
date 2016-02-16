//
//  VZFNodeInternal.h
//  VZFlexLayout
//
//  Created by moxin on 16/2/4.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#ifndef VZFNodeInternal_h
#define VZFNodeInternal_h

#import "VZFNode.h"
#import "VZFNodeLayout.h"

@class VZFlexNode;
@interface VZFNode()

@property(nonatomic,strong,readonly)VZFlexNode* flexNode;

- (VZFNodeLayout)computeLayoutThatFits:(CGSize)sz;

@end
#endif /* VZFNodeInternal_h */
