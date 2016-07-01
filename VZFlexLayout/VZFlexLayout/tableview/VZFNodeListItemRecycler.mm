//
//  VZFNodeListAdapter.m
//  VZFlexLayout
//
//  Created by moxin on 16/4/20.
//  Copyright © 2016年 Vizlab. All rights reserved.
//

#import "VZFNodeListItemRecycler.h"
#import "VZFSizeRange.h"
#import "VZFNode.h"
#import "VZFNodeSubClass.h"
#import "VZFRootScope.h"
#import "VZFNodeProvider.h"
#import "VZFLocker.h"
#import "VZFNodeMemoizer.h"
#import "VZFScopeManager.h"
#import "VZFNodeLayoutManager.h"
#include <objc/runtime.h>
#import "VZFUtils.h"
#import "VZFMacros.h"

@interface VZFWeakObjectWrapper : NSObject
@property(nonatomic,weak) id object;
@end

@implementation VZFWeakObjectWrapper
@end


const void* g_recycleId = &g_recycleId;
@implementation UIView(ListRecycleController)

- (void)setVz_recycler:(VZFNodeListItemRecycler *)vz_recycler{
    
    VZFWeakObjectWrapper* wrapper = [VZFWeakObjectWrapper new];
    wrapper.object = vz_recycler;
    objc_setAssociatedObject(self, &g_recycleId, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (VZFNodeListItemRecycler* )vz_recycler{
    
    VZFWeakObjectWrapper* wrapper = objc_getAssociatedObject(self, g_recycleId);
    return wrapper.object;
}

@end


struct VZFNodeListItemRecyclerState{

    __strong id item;
    NodeLayout layout;
    CGSize constrainedSize;
};

@interface VZFNodeListItemRecycler()<VZFStateListener>

@end

@implementation VZFNodeListItemRecycler{

    __weak UIView *_mountedView;
    NSSet *_mountedNodes;
    VZFNodeListItemRecyclerState _state;
    
    __weak id<VZFNodeProvider> _nodeProvider;
    __weak id<VZSizeRangeProvider> _sizeRangeProvider;
    
//    VZ::Mutex _lock; // protects _previousRoot and _pendingStateUpdates
//    VZFRootScope *_previousRoot;
//    NSDictionary* _stateFuncMap;
//    VZFNodeListRecycleState _state;
}

- (instancetype)initWithNodeProvider:(id<VZFNodeProvider>)nodeProvider
                   SizeRangeProvider:(id<VZSizeRangeProvider>)sizeProvider
{
    
    self = [super init];
    if (self) {
    
        _nodeProvider       = nodeProvider;
        _sizeRangeProvider  = sizeProvider;
//        _stateFuncMap       = @{};
        
        
    }
    return self;

}

- (void)dealloc{

    //VZFAssert([NSThread isMainThread], @"object must be dealloced on Main Thread");
    
    if (_mountedNodes) {
        
        for(VZFNode* node in _mountedNodes){
            VZ::Mounting::reset(node.mountedView);
        }
        
        [[VZFNodeLayoutManager sharedInstance] unmountNodes:_mountedNodes];
    }
    if (_mountedView) {
        _mountedView.vz_recycler = nil;
    }
}

- (void)calculate:(id)item constrainedSize:(CGSize)constrainedSize context:(id<NSObject>)context{

//    VZFRootScope* rootScope = _previousRoot?:[VZFRootScope rootScopeWithListener:self];
//    VZFBuildNodeResult result = [VZFScopeManager buildNodeWithFunction:^VZFNode *{
//        return [_nodeProvider nodeForItem:item context:context];
//    } RootScope:rootScope StateUpdateFuncs:_stateFuncMap];
//    
//    
    VZFNode* node = [_nodeProvider nodeForItem:item context:context];
    
    const VZ::NodeLayout layout = [node computeLayoutThatFits:constrainedSize];
    
    _state = {.item = item, .layout = layout, .constrainedSize = constrainedSize};
    
    
//    _previousRoot = result.scopeRoot; //potential crash here, can't figure out why, might be the threading problem
//    _stateFuncMap = @{};
    
//    return {
//        .item = item,
//        .context = context,
//        .constrainedSize = constrainedSize,
//        .layout = layout,
////        .rootScope = result.scopeRoot
//    };
    
    
}

- (void)updateState{
    
    [self calculate:_state.item constrainedSize:_state.constrainedSize context:self.indexPath];
    
    [self _mountedLayout];

}


- (void)attachToView:(UIView *)view{

    if(view.vz_recycler != self){
    
        [self detachFromView];
        [view.vz_recycler detachFromView];
        _mountedView = view;
        view.vz_recycler = self;
        
        NSLog(@"[%@]--->attach:<%ld,%p>",self.class,self.indexPath.row,view);
    }
    
    [self _mountedLayout];
 
}

- (void)detachFromView{
    
    if (_mountedView) {
        
        NSLog(@"[%@]--->detach:<%ld,%p>",self.class, self.indexPath.row, _mountedView);
    
        [[VZFNodeLayoutManager sharedInstance] unmountNodes:_mountedNodes];
        _mountedNodes = nil;
        _mountedView.vz_recycler = nil;
        _mountedView = nil;
    }
}

- (BOOL)isAttachedToView{

    return (_mountedView != nil);
}

//- (void)nodeScopeHandleWithIdentifier:(id)scopeId
//                       rootIdentifier:(id)rootScopeId
//                didReceiveStateUpdate:(id (^)(id))stateUpdate
//                           updateMode:(VZFActionUpdateMode)updateMode{
//
//    
//    NSMutableDictionary* mutableFuncs = [_stateFuncMap mutableCopy];
//    NSMutableArray* funclist = mutableFuncs[scopeId];
//    if (!funclist) {
//        funclist = [NSMutableArray new];
//    }
//    [funclist addObject:stateUpdate];
//    mutableFuncs[scopeId] = funclist;
//    _stateFuncMap = [mutableFuncs copy];
//    
//    //计算新的size
//    CGSize sz = [_sizeRangeProvider rangeSizeForBounds:_state.constrainedSize];
//    
//    [self _updateStateInternal:[self calculate:_state.item constrainedSize:sz context:_state.context] scopeId:scopeId];
//
//
//}

- (CGSize)resultSize{

    return (CGSize){
        (_state.layout.size.width + _state.layout.margin.left + _state.layout.margin.right),
        (_state.layout.size.height + _state.layout.margin.top + _state.layout.margin.bottom)
    };
}

- (id)item{

    return _state.item;
}

//- (VZFRootScope* )scopeRoot{
//    
//    return _state.rootScope;
//}

- (const VZ::NodeLayout& )nodeLayout{

    return _state.layout;
}


- (void)_mountedLayout{
    _mountedNodes = [[VZFNodeLayoutManager sharedInstance] layoutRootNode:_state.layout
                                                              InContainer:_mountedView
                                                        WithPreviousNodes:_mountedNodes
                                                             AndSuperNode:nil];
    
}


//- (void)_updateStateInternal:(const VZFNodeListRecycleState& )state scopeId:(id)scopeId{

//    BOOL sizeChanged = !CGSizeEqualToSize(_state.layout.size, state.layout.size);

//    [self updateState:state];
    
//    [self _mountedLayout];
    
//    if ([self.delegate respondsToSelector:@selector(nodeStateDidChanged:ShouldInvalidateToNewSize:)]) {
//        [self.delegate nodeStateDidChanged:scopeId ShouldInvalidateToNewSize:sizeChanged];
//    }
//}

@end



