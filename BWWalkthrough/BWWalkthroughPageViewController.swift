/*
The MIT License (MIT)
Copyright (c) 2015 Yari D'areglia @bitwaker
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

//
//  BWWalkthroughPageViewController.swift
//  BWWalkthrough
//
//  Created by Yari D'areglia on 17/09/14.
//  Copyright (c) 2014 Yari D'areglia. All rights reserved.
//

import UIKit

/// The type of animation the walkthrough page is performing.
enum WalkthroughAnimationType {
    /// A standard, linear animation
    case linear
    /// A curved animation
    case curve
    /// A zoom animation
    case zoom
    /// An in out animation.
    case inOut
    
    /**
        Allows for initialisation of a `WalkthroughAnimationType` from a `String`. Supported strings (case insensitive):
        
        - "Linear"
        - "Curve"
        - "Zoom"
        - "InOut"
    
        :param: string      A string describing the desired animation type.
        
        :returns:           A `WalkthroughAnimationType` matching the given string, or just a `Linear` animation if the string is unsupported.
     */
    static func fromString(_ string: String) -> WalkthroughAnimationType {
        switch(string.lowercased()) {
        case "linear":
            return .linear
            
        case "curve":
            return .curve
            
        case "zoom":
            return .zoom
            
        case "inout":
            return .inOut
            
        default:
            return .linear
        }
    }
}

//	MARK: Walkthrough Page View Controller Class

/**
    **BWWalkthroughPageViewController**

    This is a `UIViewController` which adopts the `BWWalkthroughPage` protocol and allows for a default implementation of page behaviour
    for use in the `BWWalkthroughViewController`.

    Unless you have a specific reason not to, you should subclass this view controller if you want it to be a part of the `BWWalkthroughViewController`.
    If you do have a specific reason, feel free to simply adopt the `BWWalkthroughPage` protocol.
*/
class BWWalkthroughPageViewController: UIViewController, BWWalkthroughPage {
    
    //	MARK: Properties - Animation
    
    ///  The speed of the animation.
    @IBInspectable var animationSpeed = CGPoint(x: 0.0, y: 0.0);
    /// The variance in speed of the animation.
    @IBInspectable var animationSpeedVariance = CGPoint(x: 0.0, y: 0.0)
    /// The type of the animation.
    @IBInspectable var animationType = "Linear"
    /// Whether or not to animate the alpha value of the page.
    @IBInspectable var animateAlpha = false
    
    //	MARK: Properties
    
    /// The delegate which allows for comunication back up to the walkthrough view controller.
    var delegate: WalkthroughPageDelegate?
    /// Speeds of the animation applied to our subviews, mapped to each subview.
    fileprivate var subviewSpeeds = [CGPoint]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.masksToBounds = true
        
        //  for each view we increase the animation speed appropriately and store it as a speed for that layer
        subviewSpeeds = view.subviews.map { _ in
            self.animationSpeed.x += self.animationSpeedVariance.x
            self.animationSpeed.y += self.animationSpeedVariance.y
            return self.animationSpeed
        }
        
    }
    
    // MARK: BWWalkthroughPage Functions
    
    func walkthroughDidScroll(_ position: CGFloat, offset: CGFloat) {
        
        for index in 0..<subviewSpeeds.count {
            
            //  perform transition / scale / rotate animations
            switch WalkthroughAnimationType.fromString(animationType) {
                
            case WalkthroughAnimationType.linear:
                animationLinear(index, offset)
                
            case WalkthroughAnimationType.zoom:
                animationZoom(index, offset)
                
            case WalkthroughAnimationType.curve:
                animationCurve(index, offset)
                
            case WalkthroughAnimationType.inOut:
                animationInOut(index, offset)
            }
            
            //  animate alpha
            if(animateAlpha) {
                animationAlpha(index, offset)
            }
        }
    }
    
    
    //  MARK: Animations (WIP)
    
    /**
        Animate alpha of subviews based on the current offset of the walkthrough.
        
        :param: index       The index of the view to animate.
        :param  offset      The current offset of the walkthrough.
     */
    private func animationAlpha(_ index: Int, _ offset: CGFloat) {
        var offset = offset
        for subview in view.subviews {
            
            //  if the offset is more than 1, we knock it down
            if (offset > 1.0) {
                offset = 1.0 + (1.0 - offset)
            }
            
            subview.alpha = (offset)
        }
    }
    
    fileprivate func animationCurve(_ index:Int, _ offset:CGFloat) {
        var transform = CATransform3DIdentity
        let x:CGFloat = (1.0 - offset) * 10
        transform = CATransform3DTranslate(transform, (pow(x,3) - (x * 25)) * subviewSpeeds[index].x, (pow(x,3) - (x * 20)) * subviewSpeeds[index].y, 0 )
        view.subviews[index].layer.transform = transform
    }
    
    fileprivate func animationZoom(_ index:Int, _ offset:CGFloat){
        var transform = CATransform3DIdentity
        
        var tmpOffset = offset
        if(tmpOffset > 1.0){
            tmpOffset = 1.0 + (1.0 - tmpOffset)
        }
        let scale:CGFloat = (1.0 - tmpOffset)
        transform = CATransform3DScale(transform, 1 - scale , 1 - scale, 1.0)
        view.subviews[index].layer.transform = transform
    }
    
    fileprivate func animationLinear(_ index:Int, _ offset:CGFloat){
        var transform = CATransform3DIdentity
        let mx:CGFloat = (1.0 - offset) * 100
        transform = CATransform3DTranslate(transform, mx * subviewSpeeds[index].x, mx * subviewSpeeds[index].y, 0 )
        view.subviews[index].layer.transform = transform
    }
    
    fileprivate func animationInOut(_ index:Int, _ offset:CGFloat){
        var transform = CATransform3DIdentity
        var x:CGFloat = (1.0 - offset) * 20
        
        var tmpOffset = offset
        if(tmpOffset > 1.0){
            tmpOffset = 1.0 + (1.0 - tmpOffset)
        }
        transform = CATransform3DTranslate(transform, (1.0 - tmpOffset) * subviewSpeeds[index].x * 100, (1.0 - tmpOffset) * subviewSpeeds[index].y * 100, 0)
        view.subviews[index].layer.transform = transform
        
    }
    
}