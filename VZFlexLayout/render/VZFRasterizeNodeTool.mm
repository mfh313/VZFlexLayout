//
//  VZFRasterizeNodeTool.m
//  VZFlexLayout
//
//  Created by heling on 2017/2/10.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "VZFRasterizeNodeTool.h"
#import "VZFAsyncConfig.h"
#import "VZFImageNode.h"
#import "VZFButtonNode.h"
#import "VZFTextNode.h"
#import "VZFImageNodeRenderer.h"
#import "VZFTextNodeRenderer.h"
#import "VZFTextNodeSpecs.h"
#import "VZFImageNodeSpecs.h"
#import "VZFNodeInternal.h"
#import "VZFlexNode.h"
#import "VZFStackNode.h"
#import "VZFBlankNodeRenderer.h"
#import "VZFButtonNodeRenderer.h"
#import "VZFButtonNodeSpecs.h"

@implementation VZFRasterizeNodeTool

+(VZFRenderer *)getRenderer4RasterizedNode:(VZFNode *)node size:(CGSize)size {
    //判断光栅化开关
    if (!VZFUseRasterize) {
        return nil;
    }
    
    NodeSpecs specs = node.specs;
    if (specs.gesture ||
        specs.highlightBackgroundColor ||
        specs.borderWidth > 0 ||
        specs.clip ||
        specs.alpha < 1 ||
        specs.tag > 0 ||
        specs.applicator ||
        specs.unapplicator ||
        (specs.isAccessibilityElement != VZF_BOOL_UNDEFINED && specs.isAccessibilityElement) ||
        specs.accessibilityLabel) {
        return nil;
    }
    
    if (!node.viewClass.hasView()) {
        return nil;
    }
        
    if ([node isKindOfClass:[VZFImageNode class]])
    {
        return [self getImageRenderer:((VZFImageNode* )node).imageSpecs node:node];
    }
    else if ([node isKindOfClass:[VZFTextNode class]])
    {
        return [self getTextRenderer:((VZFTextNode* )node).textSpecs node:node size:size];
    }
    else if([node  isKindOfClass:[VZFStackNode class]]){
        return [self getBlankRenderer:node];
    }
    //button需要独立处理事件 需要view不做光栅化处理
    
    return nil;
}

+(VZFRenderer *)getNormalRender:(VZFNode *)node{
    VZFRenderer *renderer = [VZFBlankNodeRenderer new];
    [self setRenderer:renderer specs:node.specs];
    return renderer;
}

+(VZFTextNodeRenderer *)getTextRenderer:(const TextNodeSpecs& )textNodeSpecs node:(VZFTextNode* )node size:(CGSize)size{
    VZFTextNodeRenderer *renderer = node.renderer;
    UIEdgeInsets edgeInsets = node.flexNode.resultPadding;
    renderer.maxWidth = size.width - edgeInsets.left - edgeInsets.right;
    [self setRenderer:renderer specs:node.specs];
    return renderer;
}

+(VZFBlankNodeRenderer *)getBlankRenderer:(VZFStackNode *)node{
    VZFBlankNodeRenderer *renderer = [VZFBlankNodeRenderer new];
    [self setRenderer:renderer specs:node.specs];
    return renderer;
}

+(VZFImageNodeRenderer *)getImageRenderer:(const ImageNodeSpecs& )imageSpec node:(VZFImageNode* )node{
    NSDictionary *ctx = [imageSpec.context isKindOfClass:[NSDictionary class]] ? (NSDictionary *)imageSpec.context : @{} ;
    int animateCount = [ctx[@"animate-count"] intValue]?:0;
    
    if (animateCount > 1 || imageSpec.imageUrl.length > 0) {
        return nil;
    }
    
    VZFImageNodeRenderer *renderer = [VZFImageNodeRenderer new];
    renderer.animateCount = animateCount;
    renderer.scale = VZ::Helper::screenScale();
    renderer.contentMode = imageSpec.contentMode;
    renderer.image = imageSpec.image;
    [self setRenderer:renderer specs:node.specs];
    return renderer;
}



+(void)setRenderer:(VZFRenderer *)renderer specs:(const NodeSpecs&)vs{
    renderer.backgroundColor = vs.backgroundColor;
    renderer.borderWidth = vs.borderWidth;
    renderer.borderColor = vs.borderColor;
    renderer.customCorner = vzfRoundedCorner(vs.cornerRadius);
    renderer.clip = vs.clip;
}

@end
