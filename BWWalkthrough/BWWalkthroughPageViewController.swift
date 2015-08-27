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
    case Linear
    /// A curved animation
    case Curve
    /// A zoom animation
    case Zoom
    /// An in out animation.
    case InOut
    
    /**
        Allows for initialisation of a `WalkthroughAnimationType` from a `String`. Supported strings (case insensitive):
        
        - "Linear"
        - "Curve"
        - "Zoom"
        - "InOut"
    
        :param: string      A string describing the desired animation type.
        
        :returns:           A `WalkthroughAnimationType` matching the given string, or just a `Linear` animation if the string is unsupported.
     */
    static func fromString(string: String) -> WalkthroughAnimationType {
        switch(string.lowercaseString) {
        case "linear":
            return .Linear
            
        case "curve":
            return .Curve
            
        case "zoom":
            return .Zoom
            
        case "inout":
            return .InOut
            
        default:
            return .Linear
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
    var delegate: WalkthroughPageDelegate?
    
    private var subsWeights = [CGPoint]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.masksToBounds = true
        
        for v in view.subviews{
            animationSpeed.x += animationSpeedVariance.x
            animationSpeed.y += animationSpeedVariance.y
            subsWeights.append(animationSpeed)
        }
        
    }
    
    // MARK: BWWalkthroughPage Functions
    
    func walkthroughDidScroll(position: CGFloat, offset: CGFloat) {
        
        for index in 0..<subsWeights.count {
            
            //  perform transition / scale / rotate animations
            switch WalkthroughAnimationType.fromString(animationType) {
                
            case WalkthroughAnimationType.Linear:
                animationLinear(index, offset)
                
            case WalkthroughAnimationType.Zoom:
                animationZoom(index, offset)
                
            case WalkthroughAnimationType.Curve:
                animationCurve(index, offset)
                
            case WalkthroughAnimationType.InOut:
                animationInOut(index, offset)
            }
            
            //  animate alpha
            if(animateAlpha) {
                animationAlpha(index, offset)
            }
        }
    }
    
    
    // MARK: Animations (WIP)
    
    private func animationAlpha(index:Int, var _ offset:CGFloat) {
        let cView = view.subviews[index] as! UIView
        
        if(offset > 1.0){
            offset = 1.0 + (1.0 - offset)
        }
        cView.alpha = (offset)
    }
    
    private func animationCurve(index:Int, _ offset:CGFloat){
        var transform = CATransform3DIdentity
        var x:CGFloat = (1.0 - offset) * 10
        transform = CATransform3DTranslate(transform, (pow(x,3) - (x * 25)) * subsWeights[index].x, (pow(x,3) - (x * 20)) * subsWeights[index].y, 0 )
        view.subviews[index].layer.transform = transform
    }
    
    private func animationZoom(index:Int, _ offset:CGFloat){
        var transform = CATransform3DIdentity
        
        var tmpOffset = offset
        if(tmpOffset > 1.0){
            tmpOffset = 1.0 + (1.0 - tmpOffset)
        }
        var scale:CGFloat = (1.0 - tmpOffset)
        transform = CATransform3DScale(transform, 1 - scale , 1 - scale, 1.0)
        view.subviews[index].layer.transform = transform
    }
    
    private func animationLinear(index:Int, _ offset:CGFloat){
        var transform = CATransform3DIdentity
        var mx:CGFloat = (1.0 - offset) * 100
        transform = CATransform3DTranslate(transform, mx * subsWeights[index].x, mx * subsWeights[index].y, 0 )
        view.subviews[index].layer.transform = transform
    }
    
    private func animationInOut(index:Int, _ offset:CGFloat){
        var transform = CATransform3DIdentity
        var x:CGFloat = (1.0 - offset) * 20
        
        var tmpOffset = offset
        if(tmpOffset > 1.0){
            tmpOffset = 1.0 + (1.0 - tmpOffset)
        }
        transform = CATransform3DTranslate(transform, (1.0 - tmpOffset) * subsWeights[index].x * 100, (1.0 - tmpOffset) * subsWeights[index].y * 100, 0)
        view.subviews[index].layer.transform = transform
        
    }
    
}