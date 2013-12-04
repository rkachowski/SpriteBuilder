/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2011 Viktor Lidholt
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "cocos2d.h"
@class AppDelegate;
@class CCBTemplateNode;
@class RulersLayer;
@class GuidesLayer;
@class NotesLayer;

enum {
    kCCBParticleTypeExplosion = 0,
    kCCBParticleTypeFire,
    kCCBParticleTypeFireworks,
    kCCBParticleTypeFlower,
    kCCBParticleTypeGalaxy,
    kCCBParticleTypeMeteor,
    kCCBParticleTypeRain,
    kCCBParticleTypeSmoke,
    kCCBParticleTypeSnow,
    kCCBParticleTypeSpiral,
    kCCBParticleTypeSun
};

typedef enum {
    kCCBTransformHandleNone = 0,
    kCCBTransformHandleDownInside,
    kCCBTransformHandleMove,
    kCCBTransformHandleScale,
    kCCBTransformHandleRotate,
    kCCBTransformHandleAnchorPoint,
    kCCBTransformHandleSkew,
} CCBTransformHandle;

typedef enum {
    kCCBToolAnchor      = (1 << 0),
    kCCBToolScale       =(1 << 1),
    kCCBToolGrab        =(1 << 2),
    kCCBToolSkew        =(1 << 3),
    kCCBToolRotate      =(1 << 4),
    kCCBToolSelection   =(1 << 5),
    kCCBToolMax         =(1 << 6)
}CCBTool;

@interface CocosScene : CCNode
{
    CCLayerColor* bgLayer;
    CCLayerColor* stageBgLayer;
    CCNode* contentLayer;
    CCNode* selectionLayer;
    CCNode* physicsLayer;
    CCNode* borderLayer;
    RulersLayer* rulerLayer;
    GuidesLayer* guideLayer;
    NotesLayer* notesLayer;
    CCNode* rootNode;
    CCRenderTexture* renderedScene;
    AppDelegate* appDelegate;
    CGSize winSize;
    
    NSTrackingArea* trackingArea;
    
    // Mouse handling
    BOOL mouseInside;
    CGPoint mousePos;
    CGPoint mouseDownPos;
    float transformStartRotation;
    float transformStartScaleX;
    float transformStartScaleY;
    CCNode* transformScalingNode;
    float transformStartSkewX;
    float transformStartSkewY;
    
    int currentMouseTransform;
    BOOL isMouseTransforming;
    BOOL isPanning;
    CGPoint scrollOffset;
    CGPoint panningStartScrollOffset;
    
    // Origin position in screen coordinates
    CGPoint origin;
    
    // Selection
    NSMutableArray* nodesAtSelectionPt;
    int currentNodeAtSelectionPtIdx;
    
    CCLayerColor* borderBottom;
    CCLayerColor* borderTop;
    CCLayerColor* borderLeft;
    CCLayerColor* borderRight;
    CCSprite* borderDevice;
    
    int stageBorderType;
    float stageZoom;
    
    CCBTool currentTool;
    CGPoint skewSegmentOrientation;
    int     skewSegment;
    CGPoint cornerOrientation;//which way is the corner facing.
    int     cornerIndex;//Which corner of the object are we rotating?
}

@property (nonatomic,assign) CCNode* rootNode;
@property (nonatomic,readonly) BOOL isMouseTransforming;
@property (nonatomic,assign) CGPoint scrollOffset;

@property (nonatomic,assign) CCBTool currentTool;

@property (nonatomic,readonly) GuidesLayer* guideLayer;
@property (nonatomic,readonly) RulersLayer* rulerLayer;
@property (nonatomic,readonly) NotesLayer* notesLayer;

// Used to creat the scene
+(id) sceneWithAppDelegate:(AppDelegate*)app;

// Used to retrieve the shared instance
+ (CocosScene*) cocosScene;

-(id) initWithAppDelegate:(AppDelegate*)app;

- (void) forceRedraw;

- (void) scrollWheel:(NSEvent *)theEvent;

- (void) setStageSize: (CGSize) size centeredOrigin:(BOOL)centeredOrigin;
- (CGSize) stageSize;
- (BOOL) centeredOrigin;
- (void) setStageBorder:(int)type;
- (int) stageBorder;

- (void) setStageZoom:(float) zoom;
- (float) stageZoom;

- (void) replaceRootNodeWith:(CCNode*)node;

- (void) updateSelection;
- (void) selectBehind;

// Event handling forwarded by view
- (void)mouseMoved:(NSEvent *)event;
- (void)mouseEntered:(NSEvent *)event;
- (void)mouseExited:(NSEvent *)event;
- (void)cursorUpdate:(NSEvent *)event;

- (void) savePreviewToFile:(NSString*)path;

// Converts to document coordinates from view coordinates
- (CGPoint) convertToDocSpace:(CGPoint)viewPt;
// Converst to view coordinates from document coordinates
- (CGPoint) convertToViewSpace:(CGPoint)docPt;

@end