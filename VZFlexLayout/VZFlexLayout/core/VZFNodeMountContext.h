//
//  VZFNodeMountContext.h
//  VZFlexLayout
//
//  Created by moxin on 16/2/8.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VZFUtils.h"
#import "VZFNodeViewManager.h"

namespace VZ
{
    namespace UIKit
    {
        
        struct MountContext{
        
            //类方法
            static MountContext RootContext(UIView* v){
            
                Mounting::mountingRootView(v);
                
                return MountContext([[VZFNodeViewManager alloc]initWithView:v],{0,0},{});
                
            };
            
            //每个context关联一个view manager
            VZFNodeViewManager* viewManager;
//            std::shared_ptr<VZFNodeViewManager> viewManager;
            
            //view manager关联view的原点，子view根据这个点计算位置
            CGPoint position;
            
            //view据root view的边距
            UIEdgeInsets rootLayoutInsect;
            
            MountContext rootOffset(const CGPoint p, const CGSize parentSize, const CGSize childSize) const{
                
                const UIEdgeInsets rootLayout = transformToRootLayout(rootLayoutInsect,p,parentSize,childSize);
                return MountContext(viewManager,position + p, rootLayout);
            };
            
            MountContext childContextForSubview(UIView *subview) const {
              
                Mounting::mountingChildView(subview, viewManager.managedView);
                return MountContext([[ VZFNodeViewManager alloc ] initWithView:subview] , {0,0}, rootLayoutInsect);
            };
            
        private:
            
            MountContext(VZFNodeViewManager* m, const CGPoint p, const UIEdgeInsets l)
            : viewManager(m), position(p), rootLayoutInsect(l) {}
            
            /**
             *  将自己的坐标transform为root node的坐标
             *
             *  @param parentLayoutInsect 父容器edgeInsects
             *  @param offset             自己相对于父容器的offset
             *  @param parentSize         父容器的大小
             *  @param childSize          自己的大小
             *
             *  @return 自己相对于root容器的大小
             */
            static UIEdgeInsets transformToRootLayout(const UIEdgeInsets parentLayoutInsect,
                                                      const CGPoint offset,
                                                      const CGSize parentSize,
                                                      const CGSize childSize){
                return {
                    .left   = parentLayoutInsect.left + offset.x,
                    .top    = parentLayoutInsect.top + offset.y,
                    .right  = parentLayoutInsect.right + (parentSize.width - childSize.width) - offset.x,
                    .bottom = parentLayoutInsect.bottom + (parentSize.height - childSize.height) - offset.y,
                };
            };
        
        };
        

        struct MountResult{
            
            BOOL hasChildren;
            VZ::UIKit::MountContext childContext;
            
        };
    }
}

typedef VZ::UIKit::MountResult VZFMountResult;