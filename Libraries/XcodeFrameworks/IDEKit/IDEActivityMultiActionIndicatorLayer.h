/*
 *     Generated by class-dump 3.3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2011 by Steve Nygard.
 */

#import "DVTClickableLayer.h"

@class CATextLayer;

@interface IDEActivityMultiActionIndicatorLayer : DVTClickableLayer
{
    CATextLayer *_textLayer;
    long long _count;
}

+ (id)defaultActionForKey:(id)arg1;
- (id)accessibilityAttributeNames;
- (id)accessibilityAttributeValue:(id)arg1;
- (id)attributedStringValue;
@property long long count; // @synthesize count=_count;
- (id)init;
- (void)layerShouldShowClickedState;
- (void)layerShouldShowUnclickedState;
- (void)layoutSublayers;
- (void)setBounds:(struct CGRect)arg1;
- (void)sizeToFit;
- (id)textAttributes;

@end
