//
//  VZFRenderer.m
//  VZFlexLayout-Example
//
//  Created by heling on 2017/1/22.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "VZFRenderer.h"

@interface VZFRenderer()
{
    __weak VZFRenderer *_superRenderer;
    NSMutableArray<__kindof VZFRenderer *> *_subRenderers;
}

@end

@implementation VZFRenderer

//can not override by sub class
- (void)drawInContext:(CGContextRef)context bounds:(CGRect)bounds {
    CGContextSaveGState(context);
        
    UIBezierPath *borderPath = [self borderPathForBounds:bounds cornerRadius:self.cornerRadius];
    
    if (self.clip) {
        CGContextBeginPath(context);
        CGContextAddPath(context, borderPath.CGPath);
        CGContextClip(context);
    }

    //background should be clipped no matter if clip is YES or NO, so use border path to fill
    [self drawBackgroundColor:context path:borderPath];
    [self drawContentInContext:context bounds:bounds];
    [self drawBorder:context path:borderPath];
    
    CGContextRestoreGState(context);

}

- (void)drawBackgroundColor:(CGContextRef)context path:(UIBezierPath *)path {
    if (!self.backgroundColor) {
        return;
    }
    
    
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextBeginPath(context);
    CGContextAddPath(context, path.CGPath);
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
}

- (void)drawBorder:(CGContextRef)context path:(UIBezierPath *)borderPath {
    if (self.borderWidth <= 0
        || !self.borderColor
        || !borderPath) {
        return;
    }
    
    CGContextSaveGState(context);
    
    CGContextBeginPath(context);
    CGContextAddPath(context, borderPath.CGPath);
    CGContextClip(context);//clip and cealr current path
    CGContextAddPath(context, borderPath.CGPath);

    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    //we have set bounds as the clip path.So we set 2 times line width, and clip 1 time width lefting 1 time width;
    CGContextSetLineWidth(context, self.borderWidth * 2);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextRestoreGState(context);

}


- (void)drawBorder:(CGContextRef)context bounds:(CGRect)bounds {
    if (self.borderWidth <= 0 || !self.borderColor) {
        return;
    }
    
    CGContextSaveGState(context);
    
    if (self.cornerRadius > 0) {
        CGFloat cornerRadius = self.cornerRadius;
        CGFloat halfHeight = bounds.size.height * 0.5;
        CGFloat halfWidth = bounds.size.width * 0.5;
        
        CGFloat xAngle = 0;
        if (cornerRadius > halfWidth) {
            xAngle = asin((cornerRadius - halfWidth) / cornerRadius);
        }
        
        CGFloat yAngle = 0;
        if (cornerRadius > halfHeight) {
            yAngle = asin((cornerRadius  - halfHeight) / cornerRadius);
        }
        
        
        CGContextBeginPath(context); //begin an empty path
        
        /*
         If the current path already contains a subpath, this method adds a line connecting the current point to the starting point of the arc. If the current path is empty, his method creates a new subpath whose starting point is the starting point of the arc. The ending point of the arc becomes the new current point of the path.
         */
        //left top corner
        CGContextAddArc(context, cornerRadius, cornerRadius, cornerRadius, M_PI + yAngle, M_PI_2 * 3 - xAngle, NO);
        
        //left right corner
        CGContextAddArc(context, bounds.size.width - cornerRadius, cornerRadius, cornerRadius, - M_PI_2 + xAngle, - yAngle, NO);
        
        //right bottom corner
        CGContextAddArc(context, bounds.size.width - cornerRadius, bounds.size.height - cornerRadius, cornerRadius, 0 + yAngle, M_PI_2 - xAngle, NO);
        
        //left bottom corner
        CGContextAddArc(context, cornerRadius, bounds.size.height - cornerRadius, cornerRadius, M_PI_2 + xAngle, M_PI - yAngle, NO);
        CGContextClosePath(context);
        
        CGPathRef path = CGContextCopyPath(context);//store path
        CGContextClip(context);//clip and clear path
        CGContextAddPath(context, path);//recover path
        
    } else {
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:bounds];
        [path addClip];
        CGContextAddPath(context, path.CGPath);
    };
    
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    //we have set bounds as the clip path.So we set 2 times line width, and clip 1 time width lefting 1 time width;
    CGContextSetLineWidth(context, self.borderWidth * 2);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextRestoreGState(context);
}

- (UIBezierPath *)borderPathForBounds:(CGRect)bounds cornerRadius:(CGFloat)cornerRadius {
    if (cornerRadius > 0) {
        //about corner
        //http://stackoverflow.com/questions/22453095/why-does-applying-a-bezierpathwithroundedrect-mask-yield-a-different-result-from
        //http://www.mani.de/backstage/?p=483
        return [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:cornerRadius];
    } else {
        return [UIBezierPath bezierPathWithRect:bounds];
    }
}


- (void)drawContentInContext:(CGContextRef)context bounds:(CGRect)bounds {
    //overrided by sub class
}



#pragma mark - VZFRendererHierarchy

- (nullable VZFRenderer *)superRenderer {
    return _superRenderer;
}

- (nullable NSArray<__kindof VZFRenderer *> *)subRenderers {
    return [_subRenderers copy];
}

- (void)removeFromSuperRenderer {
    [_superRenderer removeSubRenderer:self];
}

//private
- (void)removeSubRenderer:(VZFRenderer *)subRenderer {
    if (![subRenderer isKindOfClass:[VZFRenderer class]]) {
        return;
    }
    [_subRenderers removeObject:subRenderer];
}

- (void)insertSubRenderer:(VZFRenderer *)renderer atIndex:(NSInteger)index {
    if (![renderer isKindOfClass:[VZFRenderer class]]) {
        return;
    }
    
    if (index < 0 || index > _subRenderers.count){
        return;
    }
    
    if (!_subRenderers) {
        _subRenderers = [NSMutableArray array];
    }
    
    if (renderer->_superRenderer && renderer->_superRenderer != self) {
        [renderer removeFromSuperRenderer];
    }
    
    [_subRenderers insertObject:renderer atIndex:index];
    renderer->_superRenderer = self;

}

- (void)exchangeSubRendererAtIndex:(NSInteger)index1 withSubRendererAtIndex:(NSInteger)index2 {
    if (index1 < 0 || index1 > _subRenderers.count
        || index2 < 0 || index2 > _subRenderers.count){
        return;
    }
    
    if (!_subRenderers) {
        _subRenderers = [NSMutableArray array];
    }
    
    [_subRenderers exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (void)addSubRenderer:(VZFRenderer *)renderer {
    if (![renderer isKindOfClass:[VZFRenderer class]]
        || [_subRenderers containsObject:renderer]) {
        return;
    }
    
    if (!_subRenderers) {
        _subRenderers = [NSMutableArray array];
    }
    
    if (renderer->_superRenderer && renderer->_superRenderer != self) {
        [renderer removeFromSuperRenderer];
    }
    
    [_subRenderers addObject:renderer];
    renderer->_superRenderer = self;
}

- (void)insertSubRenderer:(VZFRenderer *)renderer belowSubRenderer:(VZFRenderer *)siblingSubRenderer {
    [self insertSubRenderer:renderer nearSubRenderer:siblingSubRenderer isAbove:NO];
}

- (void)insertSubRenderer:(VZFRenderer *)renderer aboveSubRenderer:(VZFRenderer *)siblingSubRenderer {
    [self insertSubRenderer:renderer nearSubRenderer:siblingSubRenderer isAbove:YES];
}


- (void)insertSubRenderer:(VZFRenderer *)renderer nearSubRenderer:(VZFRenderer *)siblingSubRenderer isAbove:(BOOL)isAbove {
    if (![renderer isKindOfClass:[VZFRenderer class]]
        || ![siblingSubRenderer isKindOfClass:[VZFRenderer class]]
        || [_subRenderers containsObject:renderer]) {
        return;
    }
    
    NSUInteger idx = [_subRenderers indexOfObject:siblingSubRenderer];
    
    if (idx == NSNotFound || idx >= [_subRenderers count]) {
        return;
    }
    
    if (renderer->_superRenderer && renderer->_superRenderer != self) {
        [renderer removeFromSuperRenderer];
    }
    
    [_subRenderers insertObject:renderer atIndex:idx + (isAbove ? 1 : 0)];
    renderer->_superRenderer = self;
}


- (void)bringSubRendererToFront:(VZFRenderer *)renderer {
    if (![renderer isKindOfClass:[VZFRenderer class]]
        || ![_subRenderers containsObject:renderer]) {
        return;
    }
    
    [_subRenderers removeObject:renderer];
    [_subRenderers addObject:renderer];
    renderer->_superRenderer = self;
}

- (void)sendSubRendererToBack:(VZFRenderer *)renderer {
    if (![renderer isKindOfClass:[VZFRenderer class]]
        || ![_subRenderers containsObject:renderer]) {
        return;
    }
    
    [_subRenderers removeObject:renderer];
    [_subRenderers insertObject:renderer atIndex:0];
    renderer->_superRenderer = self;
}

- (BOOL)isDescendantOfRenderer:(VZFRenderer *)renderer {
    if (![renderer isKindOfClass:[VZFRenderer class]]) {
        return NO;
    }
    
    if (renderer == self) {
        return YES;
    }
    
    for (VZFRenderer *subRender in _subRenderers) {
        if ([renderer isDescendantOfRenderer:subRender]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)removeAllSubRenderers {
    [_subRenderers removeAllObjects];
}


@end
