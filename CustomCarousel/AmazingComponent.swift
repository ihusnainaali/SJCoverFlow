//
//  AmazingComponent.swift
//  CustomControl
//
//  Created by Sameer Junaid on 11/3/19.
//  Copyright © 2019 CodiftaLabs. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

public enum CarouselType: Int {
    case Cylinder = 1
    case Coverflow = 2
}

protocol AmazingComponentDelgateProtocol:class {
    
    func scrolldidScroll(scroll:UIScrollView)
}

protocol AmazingComponentDataSourceProtocol:class {
    
    func numberofViewsRequired(component:AmazingComponent) -> Int
    func requiredHeightandWidth(component:AmazingComponent) -> (Double,Double)
    func viewForIndexPathAtFullView(component:AmazingComponent,atView:UIView,index:Int) -> UIView

}


class AmazingComponent: UIView,UIScrollViewDelegate {
    
    var scrollView:UIScrollView?
    weak var delegator:AmazingComponentDelgateProtocol?
   private var numberOfViews:Int?
   private var requiredHeight:Double? = nil
   private var requiredWidth:Double? = nil
    public var isVertical:Bool? = true
    private var hostview:UIView?
    var _scrollOffset:CGFloat?
    var _perspective:CGFloat?
    var viewpointOffset:CGSize?
    var carouselType:Int?
    var timer:Timer?

    public var requiredSpacing:Double?
    weak var datasource:AmazingComponentDataSourceProtocol?{
        
        didSet{
            print(datasource?.numberofViewsRequired(component:self) as Any)
            self.numberOfViews=datasource?.numberofViewsRequired(component:self)
            self.requiredHeight = datasource?.requiredHeightandWidth(component: self).1
            self.requiredWidth = datasource?.requiredHeightandWidth(component: self).0
            reloadCarousel()
            }
    }

    public func reloadCarousel(){
        
        if let viewCount = self.numberOfViews {
            for i in 0..<viewCount {
            self.loadViewWithndex(index: i)
            }
        }
        
    }
    
    private func loadViewWithndex(index:Int){
        
        var contentView:UIView = UIView()
            if (index%2==0){
                contentView.backgroundColor = UIColor.blue
              }else{
                  contentView.backgroundColor = UIColor.green
              }
        
        if isVertical == true{
            scrollView?.contentSize = CGSize(width:Double(self.requiredWidth!), height: Double(index) * Double(self.requiredHeight!))
            if requiredSpacing != nil {
                contentView.frame = CGRect(x: Double(0), y: Double(index) * Double(requiredSpacing!), width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
            }else{
                contentView.frame = CGRect(x: Double(0), y: Double(index) * Double(self.requiredHeight!), width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
            }
        }else{
            scrollView?.contentSize = CGSize(width: Double(index) * Double(self.requiredWidth!), height:Double(self.requiredHeight!))
            if requiredSpacing != nil {
                contentView.frame = CGRect(x: Double(index) * Double(requiredSpacing!), y:Double(0) , width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
            }else{
                contentView.frame = CGRect(x: Double(index) * Double(self.requiredWidth!), y:Double(0) , width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
            }
        }
        
        contentView=(datasource?.viewForIndexPathAtFullView(component: self, atView: contentView, index: index))!
        transFromView(view:contentView,Index:index)
        scrollView?.addSubview(contentView)

        
    }
    
    private func transFromView(view:UIView,Index:Int){
        
        var offset:CGFloat
        offset=offsetForItemAtIndex(AtIndex: Index)
        view.layoutIfNeeded()
        var transform:CATransform3D
        transform = transformForItemViewWithOffset(atOffset: offset)
        view.layer.transform = transform;

    }
    
     private func transformForItemViewWithOffset(atOffset:CGFloat)->CATransform3D{
        
       var  transform:CATransform3D = CATransform3DIdentity;
            transform.m34 = _perspective!;
            transform = CATransform3DTranslate(transform, -viewpointOffset!.width, -viewpointOffset!.height, 0.0);

        
        switch CarouselType(rawValue:carouselType!) {
        case .Cylinder:
        var transform:CATransform3D
        transform = CATransform3DIdentity;
        transform.m34 = _perspective!;
        transform = CATransform3DTranslate(transform, -viewpointOffset!.width, -viewpointOffset!.height, 0.0);
        let count:CGFloat = CGFloat(self.numberOfViews!)
        let spacing:CGFloat  = 1.0
        let arc:CGFloat  = CGFloat(Double.pi * 2.0);
        let radius:CGFloat  = max(0.01, CGFloat(Double(self.requiredWidth!) * Double(spacing) / 2.0) / tan(arc/2.0/count))
        let angle:CGFloat  = atOffset / count * arc
       

       
        if (isVertical!)
       {
           transform = CATransform3DTranslate(transform, 0.0, 0.0, -radius);
           transform = CATransform3DRotate(transform, angle, -1.0, 0.0, 0.0);
           return CATransform3DTranslate(transform, 0.0, 0.0, radius + 0.01);
       }
       else
       {
           transform = CATransform3DTranslate(transform, 0.0, 0.0, -radius);
           transform = CATransform3DRotate(transform, angle, 0.0, 1.0, 0.0);
           return CATransform3DTranslate(transform, 0.0, 0.0, radius + 0.01);
       }
        case .none:
            let transform:CATransform3D?=nil
            return transform!

        case .Coverflow:
            let tilt:CGFloat = 0.9
           let spacing:CGFloat = 0.25
           let clampedOffset:CGFloat = max(-1.0, min(1.0, atOffset));

           
           let x:CGFloat = (clampedOffset * 0.5 * tilt + atOffset * spacing) * CGFloat(Double(self.requiredWidth!))
            let z:CGFloat = abs(clampedOffset) * -CGFloat(Double(self.requiredWidth!)) * 0.5
           
            if (isVertical!)
           {
            transform = CATransform3DTranslate(transform, 0.0, x, z);
            return CATransform3DRotate(transform, CGFloat(Double(-clampedOffset) * Double(Double.pi * Double(tilt))), -1.0, 0.0, 0.0)
           }
           else
           {
               transform = CATransform3DTranslate(transform, x, 0.0, z);
               return CATransform3DRotate(transform, CGFloat(Double(-clampedOffset) * Double(Double.pi * Double(tilt))), 0.0, 1.0, 0.0);
           }
        }
    }

    private func offsetForItemAtIndex(AtIndex:Int)->CGFloat{
        
        var offset:CGFloat = CGFloat(AtIndex) - CGFloat(_scrollOffset ?? 0)
        if (Double(offset) > Double(self.numberOfViews!)/2.0)
        {
            offset -= CGFloat(self.numberOfViews!)
        }
        else if (Double(offset) < -Double(self.numberOfViews!)/2.0)

        {
            offset += CGFloat(self.numberOfViews!)
        }
         return offset;
    }
    
    public func initWithView(view: UIView) {
        
            hostview = view
            setupContent()
        }
    
    private func setupContent(){
        
        _perspective = -1.0/500.0;
        viewpointOffset = CGSize.zero
        _scrollOffset = 1
        scrollView = UIScrollView()
        scrollView?.frame = CGRect.init(x: hostview!.frame.origin.x, y:  hostview!.frame.origin.y, width:  hostview!.frame.size.width, height: hostview!.frame.size.height)
        scrollView?.delegate=self
        scrollView?.backgroundColor = UIColor.cyan
        scrollView?.isScrollEnabled=true
        scrollView?.isPagingEnabled=true
        scrollView?.bounces=false
        self.addSubview(scrollView!)
        
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()

    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
            
        delegator?.scrolldidScroll(scroll: scrollView)
        
//           let offsetX = scrollView.contentOffset.x
//
//            if (offsetX > scrollView.frame.size.width * 1.5) {
//                // 1. Update the model. Remove (n-1)th and add (n+2)th.
//
//                scrollView.contentOffset.x -= scrollView.frame.width
//            }
//        if (offsetX < scrollView.frame.size.width * 0.5) {
//
//            scrollView.contentOffset.x += scrollView.frame.height
//            }
    }
    
   func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
       let currentPage:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        print(currentPage)
//       if currentPage == 0 {
//        self.scrollView!.contentOffset = CGPoint(x: scrollView.frame.size.width * CGFloat(self.numberOfViews!), y: scrollView.contentOffset.y)
//       }
//       else if currentPage == numberOfViews {
//        self.scrollView!.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
//       }
   }
    
    
// # Mark: Animation
    func startAnimation()
    {
        if (timer != nil)
        {
            self.timer = Timer(timeInterval: 1.0/60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.tracking)

        }
    }

    func stopAnimation()
    {
        timer?.invalidate()
        timer = nil;
    }
    
    
    func pushAnimationState(enabled:Bool)
    {
        CATransaction.begin()
        CATransaction.disableActions()=!enabled
    }
    
    func step{
        
        
            [self pushAnimationState:NO];
            NSTimeInterval currentTime = CACurrentMediaTime();
            double delta = currentTime - _lastTime;
            _lastTime = currentTime;
            
            if (_scrolling && !_dragging)
            {
                NSTimeInterval time = MIN(1.0, (currentTime - _startTime) / _scrollDuration);
                delta = [self easeInOut:time];
                _scrollOffset = _startOffset + (_endOffset - _startOffset) * delta;
                [self didScroll];
                if (time >= 1.0)
                {
                    _scrolling = NO;
                    [self depthSortViews];
                    [self pushAnimationState:YES];
                    [_delegate carouselDidEndScrollingAnimation:self];
                    [self popAnimationState];
                }
            }
            else if (_decelerating)
            {
                CGFloat time = MIN(_scrollDuration, currentTime - _startTime);
                CGFloat acceleration = -_startVelocity/_scrollDuration;
                CGFloat distance = _startVelocity * time + 0.5 * acceleration * pow(time, 2.0);
                _scrollOffset = _startOffset + distance;
                [self didScroll];
                if (fabs(time - _scrollDuration) < FLOAT_ERROR_MARGIN)
                {
                    _decelerating = NO;
                    [self pushAnimationState:YES];
                    [_delegate carouselDidEndDecelerating:self];
                    [self popAnimationState];
                    if ((_scrollToItemBoundary || fabs(_scrollOffset - [self clampedOffset:_scrollOffset]) > FLOAT_ERROR_MARGIN) && !_autoscroll)
                    {
                        if (fabs(_scrollOffset - self.currentItemIndex) < FLOAT_ERROR_MARGIN)
                        {
                            //call scroll to trigger events for legacy support reasons
                            //even though technically we don't need to scroll at all
                            [self scrollToItemAtIndex:self.currentItemIndex duration:0.01];
                        }
                        else
                        {
                            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
                        }
                    }
                    else
                    {
                        CGFloat difference = round(_scrollOffset) - _scrollOffset;
                        if (difference > 0.5)
                        {
                            difference = difference - 1.0;
                        }
                        else if (difference < -0.5)
                        {
                            difference = 1.0 + difference;
                        }
                        _toggleTime = currentTime - MAX_TOGGLE_DURATION * fabs(difference);
                        _toggle = MAX(-1.0, MIN(1.0, -difference));
                    }
                }
            }
            else if (_autoscroll && !_dragging)
            {
                //autoscroll goes backwards from what you'd expect, for historical reasons
                self.scrollOffset = [self clampedOffset:_scrollOffset - delta * _autoscroll];
            }
            else if (fabs(_toggle) > FLOAT_ERROR_MARGIN)
            {
                NSTimeInterval toggleDuration = _startVelocity? MIN(1.0, MAX(0.0, 1.0 / fabs(_startVelocity))): 1.0;
                toggleDuration = MIN_TOGGLE_DURATION + (MAX_TOGGLE_DURATION - MIN_TOGGLE_DURATION) * toggleDuration;
                NSTimeInterval time = MIN(1.0, (currentTime - _toggleTime) / toggleDuration);
                delta = [self easeInOut:time];
                _toggle = (_toggle < 0.0)? (delta - 1.0): (1.0 - delta);
                [self didScroll];
            }
            else if (!_autoscroll)
            {
                stopAnimation();
            }
            
            [self popAnimationState];
        
    }
    
    
    
}
