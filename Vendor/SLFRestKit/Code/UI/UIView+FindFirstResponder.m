//
//  UIView+FindFirstResponder.m
//  RestKit
//
//  Created by Blake Watters on 8/29/11.
//  Copyright (c) 2011 RestKit.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "UIView+FindFirstResponder.h"


@implementation UIView (FindFirstResponder)

- (UIView*)findFirstResponder {
    if (self.isFirstResponder) {
        return self;
    }

    for (UIView* subView in self.subviews) {
        UIView* firstResponder = [subView findFirstResponder];
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    return nil;
}

@end
