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
    func carouselGetCurrentIndex(scroll:UIScrollView,currentIndex:Int)
    func carouselDidEndScrollingAnimation(scroll:UIScrollView)
}

protocol AmazingComponentDataSourceProtocol:class {
    
    func numberofViewsRequired(component:AmazingComponent) -> Int
    func requiredHeightandWidth(component:AmazingComponent) -> (Double,Double,Double,Double)
    func viewForIndexPathAtFullView(component:AmazingComponent,atView:UIView,index:Int) -> UIView

}


class AmazingComponent: UIView,UIScrollViewDelegate {
    
    var FLOAT_ERROR_MARGIN:CGFloat = 0.000001
    var scrollView:UIScrollView?
    weak var delegator:AmazingComponentDelgateProtocol?
   private var numberOfViews:Int?
   private var requiredHeight:Double? = nil
   private var requiredWidth:Double? = nil
    private var requiredX:Double? = nil
    private var requiredY:Double? = nil
    fileprivate let kDistanceToProjectionPlane:CGFloat = 500.0

    public var isVertical:Bool? = true
    private var hostview:UIView?
    var _scrollOffset:CGFloat?
    var _perspective:CGFloat?
    var viewpointOffset:CGSize?
    var carouselType:Int?
    var timer:Timer?
    var lastTime:TimeInterval?
    var startTime:TimeInterval?
    var scrollDuration:TimeInterval?
    public var requiredSpacing:Double?
    var toggle:CGFloat?
    var autoscroll:CGFloat?
    var stopAtItemBoundary:Bool?
    var scrollToItemBoundary:Bool?
    var ignorePerpendicularSwipes:Bool?
    var centerItemWhenSelected:Bool?
    var dragging:Bool?
    var decelerating:Bool?
    var scrolling:Bool?
    var itemWidth:CGFloat?
    var offsetMultiplier:CGFloat?
    var startOffset:CGFloat?
    var endOffset:CGFloat?
    var startVelocity:CGFloat?
    var radius:CGFloat?
    var separationAngle:CGFloat?
    var Angle:CGFloat?
    var inclinationAngle:CGFloat?
    var backItemAlpha:CGFloat?



    open var maxCoverDegree:CGFloat = 45 {
        didSet {
            if maxCoverDegree < -360 {
                maxCoverDegree = -360
            } else if maxCoverDegree > 360 {
                maxCoverDegree = 360
            }
        }
    }
    open var coverDensity:CGFloat = 0.25 {
        didSet {
            if coverDensity < 0 {
                coverDensity = 0
            } else if coverDensity > 1 {
                coverDensity = 1
            }
        }
    }

    /**
     *  Min opacity that can be applied to individual item.
     *  Default to 1.0 (alpha 100%).
     */
    open var minCoverOpacity:CGFloat = 1.0 {
        didSet {
            if minCoverOpacity < 0 {
                minCoverOpacity = 0
            } else if minCoverOpacity > 1 {
                minCoverOpacity = 1
            }
        }
    }

    /**
     *  Min scale that can be applied to individual item.
     *  Default to 1.0 (no scale).
     */
    open var minCoverScale:CGFloat = 1.0  {
        didSet {
            if minCoverScale < 0 {
                minCoverScale = 0
            } else if minCoverScale > 1 {
                minCoverScale = 1
            }
        }
    }
    weak var datasource:AmazingComponentDataSourceProtocol?{
        
        
        didSet{
            print(datasource?.numberofViewsRequired(component:self) as Any)
            self.numberOfViews=datasource?.numberofViewsRequired(component:self)
            self.requiredHeight = datasource?.requiredHeightandWidth(component: self).1
            self.requiredWidth = datasource?.requiredHeightandWidth(component: self).0
            self.requiredX = datasource?.requiredHeightandWidth(component: self).2
            self.requiredY = datasource?.requiredHeightandWidth(component: self).3
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
            contentView.tag = index + 555
            if (index%2==0){
                contentView.backgroundColor = UIColor.blue
              }else{
                  contentView.backgroundColor = UIColor.green
              }
        
        if isVertical == true{
            scrollView?.contentSize = CGSize(width:Double(self.requiredWidth!), height: Double(index) * Double(self.requiredHeight!))
            if requiredSpacing != nil {
                contentView.frame = CGRect(x: Double(self.requiredX!), y: Double(index) * Double(requiredSpacing!), width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
            }else{
                contentView.frame = CGRect(x: Double(self.requiredX!), y: Double(index) * Double(self.requiredHeight!), width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
            }
        }else{
            scrollView?.contentSize = CGSize(width: Double(index) * Double(self.requiredWidth!), height:Double(self.requiredHeight!))
            if requiredSpacing != nil {
                contentView.frame = CGRect(x: Double(index) * Double(requiredSpacing!), y:Double(self.requiredY!) , width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
            }else{
                contentView.frame = CGRect(x: Double(index) * Double(self.requiredWidth!), y:Double(self.requiredY!) , width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
            }
        }
                
        newTransForm(index: index+1, viewCell: contentView,scrollOffsetX: scrollView!.contentOffset)
        //transFromView(view:contentView,Index:index)
     //   newerTransfor(index: index, View: contentView)
        contentView=(datasource?.viewForIndexPathAtFullView(component: self, atView: contentView, index: index))!
        scrollView?.addSubview(contentView)

        
    }
    
    private func transFromView(view:UIView,Index:Int){
        var offset:CGFloat
        offset=offsetForItemAtIndex(AtIndex: Index)
        //view.center = CGPoint.init(x: self.bounds.size.width/2.0 + scrollView!.contentSize.width,
          //                         y: self.bounds.size.height/2.0 + scrollView!.contentSize.width)
        view.layer.rasterizationScale = UIScreen.main.scale;
        view.layoutIfNeeded()
        var transform:CATransform3D
        transform = transformForItemViewWithOffset(atOffset: offset)
        view.layer.zPosition = -10000.0;
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
        var angle:CGFloat  = atOffset  / count * arc

        
        print(angle)
       
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
        maxCoverDegree = 45
        coverDensity = 0.06
        minCoverScale = 1.0
        minCoverOpacity = 1
        
        separationAngle=0
        inclinationAngle = -0.1;
           backItemAlpha = 0.7;
        _perspective = -1.0/500.0;
        viewpointOffset = CGSize.zero
        _scrollOffset = 0
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
      /* let currentPage:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
              print(currentPage)
         // let currentPage:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
                 var getView:UIView  = scrollView.viewWithTag(currentPage + 555)!
                  getView.backgroundColor = UIColor.purple
                 newTransForm(index: currentPage, viewCell: getView,scrollOffsetX: scrollView.contentOffset)
*/

    }
    
   func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
     let currentPage:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
    delegator?.carouselGetCurrentIndex(scroll: scrollView, currentIndex: currentPage)
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
           // self.timer = Timer(timeInterval: 1.0/60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
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
        CATransaction.setDisableActions(!enabled)
    }
    
    func easeInOut(time:CGFloat)->CGFloat{
    
        return (time < 0.5) ? 0.5 * pow(time * 2.0, 3.0): 0.5 * pow(time * 2.0 - 2.0, 3.0) + 1.0
    }
    
    func didScroll(){
        
        
    }
    
    func popAnimationState()
    {
        CATransaction.commit()
    }
    
    func depthSortViews()
    {
        
//        var viewArray = [UIView]()
//        viewArray = [[_itemViews allValues] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:(__bridge void *)self]
//        for (view in [[_itemViews allValues] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:(__bridge void *)self] as UIView)
//        {
//            contentView.bringSubviewToFront:(UIView *__nonnull)view.superview
//        }
    }
  /*
    @objc func step(){
        
        
            pushAnimationState(enabled: false)
            var currentTime:TimeInterval = CACurrentMediaTime();
        var delta:Double = Double(currentTime) - Double(lastTime!)
            lastTime = currentTime;
            
        if (scrolling! && !dragging!)
            {
                var time:TimeInterval = min(1.0, (currentTime - startTime!) / scrollDuration!);
                delta = Double(easeInOut(time:CGFloat(time)))
                _scrollOffset = startOffset + (endOffset - startOffset) * CGFloat(delta)
                didScroll()
                if (time >= 1.0)
                {
                    scrolling = false
                    depthSortViews()
                    pushAnimationState(enabled: true)
                    delegator!.carouselDidEndScrollingAnimation(scroll:scrollView!)
                    popAnimationState()
                }
            }
            else if (decelerating!)
            {
                var time:CGFloat = min(CGFloat(scrollDuration!), CGFloat(currentTime) - CGFloat(startTime!));
                var acceleration:CGFloat = CGFloat(-startVelocity)/CGFloat(scrollDuration!)
                var distance:CGFloat = startVelocity * time + 0.5 * acceleration * pow(time, 2.0);
                _scrollOffset = startOffset + distance;
                didScroll()
                if (abs(CGFloat(time) - CGFloat(scrollDuration!)) < CGFloat(FLOAT_ERROR_MARGIN))
                {
                    decelerating = false;
                    pushAnimationState(enabled: true)
                    delegator!.carouselDidEndScrollingAnimation(scroll:scrollView!)
                    popAnimationState()
                    if ((scrollToItemBoundary || fabs(_scrollOffset - [self clampedOffset:_scrollOffset]) > FLOAT_ERROR_MARGIN) && !autoscroll)
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
                didScroll()
            }
            else if (!_autoscroll)
            {
                stopAnimation();
            }
            
            popAnimationState()
        
    }
    
    */
    func minXCenterForRow(_ row:Int)->CGFloat {
        let halfWidth = self.requiredWidth!/2
        let maxRads = degreesToRad(self.maxCoverDegree)

        let center = itemCenterForRow(row - 1).x
        let prevItemRightEdge = CGFloat(center) + CGFloat(halfWidth)
        let projectedLeftEdgeLocal = CGFloat(CGFloat(halfWidth) * cos(maxRads) * kDistanceToProjectionPlane) / CGFloat(kDistanceToProjectionPlane + CGFloat(halfWidth) * sin(maxRads))

        return prevItemRightEdge - CGFloat(self.coverDensity) *  CGFloat(self.requiredWidth!) + CGFloat(projectedLeftEdgeLocal)
    }
    
    
    func itemCenterForRow(_ row:Int)->CGPoint {
         let collectionViewSize = scrollView?.bounds.size ?? CGSize.zero
         return CGPoint(x: CGFloat(row) * collectionViewSize.width + collectionViewSize.width / 2,
                        y: collectionViewSize.height/2)
     }
     
      func degreesToRad(_ degrees:CGFloat)->CGFloat {
            return CGFloat(Double(degrees) * .pi / 180)
        }
   
     func maxXCenterForRow(_ row:Int)->CGFloat {
        let halfWidth = self.requiredWidth! / 2
        let maxRads = degreesToRad(self.maxCoverDegree)

        let center = itemCenterForRow(row + 1).x
        let nextItemLeftEdge = CGFloat(center) - CGFloat(halfWidth)
        let projectedRightEdgeLocal = abs(CGFloat(halfWidth) * CGFloat(cos(maxRads)) * kDistanceToProjectionPlane / (CGFloat(-halfWidth) * CGFloat(sin(maxRads)) - kDistanceToProjectionPlane))

        return nextItemLeftEdge + (CGFloat(self.coverDensity) * CGFloat(self.requiredWidth!)) - projectedRightEdgeLocal
    }
    
    
    //////New Real
    func newTransForm(index:Int,viewCell:UIView,scrollOffsetX:CGPoint){
    /// let attributesPath = attributes.indexPath
            
        let minInterval = CGFloat(index - 1) * CGFloat(self.requiredWidth!)
            let maxInterval = CGFloat(index + 1) * CGFloat(self.requiredWidth!)
            let minX = minXCenterForRow(index)
            let maxX = maxXCenterForRow(index)
            let spanX = maxX - minX

       // let scrollview  = scrollView!.contentOffset
            // Interpolate by formula
           // let interpolatedX =  max((CGFloat(minX) + (CGFloat(spanX))) / ((CGFloat(maxInterval) - CGFloat(minInterval)) * (CGFloat(5) - CGFloat(minInterval)),CGFloat(minX)),minX)
        
        
        
        let finalvalue = CGFloat(minX) + ((CGFloat(spanX) / (CGFloat(maxInterval) - CGFloat(minInterval))) * (CGFloat(scrollOffsetX.x) - CGFloat(minInterval)))
        let vale = max(finalvalue, minX)
        
        let interpolatedX = min(vale, maxX)

                viewCell.center = CGPoint(x: viewCell.center.x, y: viewCell.center.y)

            var transform = CATransform3DIdentity

            // Add perspective ////change direction of scroll put negative perpective
            transform.m34 = 1.0 / 500

            // Then rotate.
        let angle = CGFloat(-self.maxCoverDegree) + (CGFloat(interpolatedX) - CGFloat(minX)) * 2 * CGFloat(self.maxCoverDegree) / CGFloat(spanX)
            transform = CATransform3DRotate(transform, degreesToRad(CGFloat(angle)), 0, 1, 0)

            // Then scale: 1 - abs(1 - Q - 2 * x * (1 - Q))
        //let scale = 1.0 - abs(1 - self.minCoverScale - (interpolatedX - minX) * 2 * (1.0 - self.minCoverScale) / spanX)
        let scale = 1.0// - CGFloat(abs(1 - CGFloat(self.minCoverScale)) - (CGFloat(interpolatedX) - CGFloat(minX))) * 2 * (1.0 - CGFloat((self.minCoverScale)) / CGFloat(spanX))
        transform = CATransform3DScale(transform, CGFloat(scale), CGFloat(scale), CGFloat(scale))

            // Apply transform
            viewCell.transform3D = transform

            // Add opacity: 1 - abs(1 - Q - 2 * x * (1 - Q))
            let opacity = 1.0 - abs(1 - CGFloat(self.minCoverOpacity) - (CGFloat(interpolatedX) - CGFloat(minX)) * 2 * (1 - CGFloat(self.minCoverOpacity)) / CGFloat(spanX))

       // viewCell.alpha = CGFloat(opacity)
            print(angle)

        print(String(format:"IDX: %d. MinX: %.2f. MaxX: %.2f. Interpolated: %.2f. Interpolated angle: %.2f ..AScale : %.2f",
                   index,
                   minX,
                   maxX,
                   interpolatedX,
                   angle,scale));


           // return attributes
    
    }

  
    func newerTransfor(
        index:Int,View:UIView) {
        var transform:CATransform3D = CATransform3DIdentity;
        transform.m34 = 1.0 / 500.0;
        let itemView:UIView = View
        radius = CGFloat((self.requiredWidth!/2 )) /  tan((CGFloat(Double.pi) / CGFloat(index)))
        separationAngle = (CGFloat(Double.pi)*2) / CGFloat(index)
        var angle:CGFloat = separationAngle!
        itemView.layer.anchorPointZ = -radius!
        //itemView.layer.transform = CATransform3DMakeRotation(0,separationAngle!, 0, 0);
        itemView.layer.transform = CATransform3DConcat(transform, CATransform3DMakeRotation(0, radius!, -radius!, 0));
               
//               if (angle > CGFloat(Double.pi)/2 && angle < (1.5 * CGFloat(Double.pi))) {
//                   itemView.alpha = backItemAlpha!
//               } else {
//                   itemView.alpha = 1;
//               }
               
               
       // angle += separationAngle!;
        
           
          
    }

 
}
