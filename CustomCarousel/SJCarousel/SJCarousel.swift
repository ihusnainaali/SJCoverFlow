//
//  SJCarousel.swift
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

protocol SJCarouselDelgateProtocol:class {
    
    func scrolldidScroll(scroll:UIScrollView)
    func carouselGetCurrentIndex(scroll:UIScrollView,currentIndex:Int)
    func carouselDidEndScrollingAnimation(scroll:UIScrollView)
    func carouselDidSelectItemAtIndex(scrollview:UIScrollView,Index:Int)
}

protocol SJCarouselDataSourceProtocol:class {
    
    func numberofViewsRequired(component:SJCarousel) -> Int
    func requiredHeightandWidth(component:SJCarousel) -> (Double,Double,Double,Double)
    func viewForIndexPathAtFullView(component:SJCarousel,atView:UIView,index:Int) -> UIView

}


class SJCarousel: UIView,UIScrollViewDelegate {
    
    var FLOAT_ERROR_MARGIN:CGFloat = 0.000001
    var scrollView:UIScrollView?
    weak var delegator:SJCarouselDelgateProtocol?
   private var numberOfViews:Int?
   private var requiredHeight:Double? = nil
   private var requiredWidth:Double? = nil
    private var requiredX:Double? = nil
    private var requiredY:Double? = nil
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
    var isGapDistanceEnabled:Bool = false
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
    var xPos : CGFloat = 0
    var xAngle : CGFloat?
    var yAngle : CGFloat?
    var zAngle : CGFloat?

    
    
  fileprivate var kDistanceToProjectionPlane:CGFloat = 1/500.0
    open var carouselDirectionRight:Bool = false {
        
        didSet {
            if carouselDirectionRight == true {
                kDistanceToProjectionPlane = -1/500.0
            } else   {
                kDistanceToProjectionPlane = 1/500.0
            }
        }
        
    }

    

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

    var gapDistance:CGFloat? = 0
    
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
    weak var datasource:SJCarouselDataSourceProtocol?{
        
        
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
            if requiredSpacing != nil {
                contentView.frame = CGRect(x: Double(index) * Double(requiredSpacing!), y:Double(self.requiredY!) , width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
            }else{
                
                if (index==0){
                    contentView.frame = CGRect(x:Double(xPos +
                       80), y:Double(self.requiredY!) , width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
              }else{
                contentView.frame = CGRect(x: Double(xPos +
                0), y:Double(self.requiredY!) , width:Double(self.requiredWidth!), height: Double(self.requiredHeight!))
                }
                xPos = contentView.frame.origin.x  + contentView.frame.width + 0
               //xPos scrollView.contentSize = CGSize(width:x+padding, height:scrollView.frame.size.height)
                scrollView?.contentSize = CGSize(width: Double(xPos+10), height:Double(self.requiredHeight!))
                scrollView?.layoutIfNeeded()
                print("indexxx at: %d >>>> frame at:%@",contentView.frame.origin.x)
            }
        }
                
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTap(tapGesture:)))
        contentView.addGestureRecognizer(tap)
        contentView.isUserInteractionEnabled = true
        newTransForm(index: index, viewCell: contentView,scrollOffsetX: scrollView!.contentOffset)
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

               // print(angle)
       
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
        coverDensity = 0.25
        minCoverScale = 0.69
        minCoverOpacity = 1
        gapDistance = 1
        xAngle = -10
        yAngle = 0
        zAngle = -10
        isGapDistanceEnabled=true
        separationAngle=0
        inclinationAngle = -0.1;
           backItemAlpha = 0.7;
        _perspective = -1.0/500.0;
        viewpointOffset = CGSize.zero
        _scrollOffset = 0
        scrollView = UIScrollView()
        scrollView?.frame = CGRect.init(x: hostview!.frame.origin.x, y:  hostview!.frame.origin.y, width:  hostview!.frame.size.width, height:  hostview!.frame.size.height)
        scrollView?.delegate=self
        scrollView?.backgroundColor = UIColor.cyan
        scrollView?.isScrollEnabled=true
        scrollView?.clipsToBounds = false
    //    scrollView?.isPagingEnabled=true
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
        let currentPage:Int = Int(scrollView.contentOffset.x / CGFloat(self.requiredWidth!))
    print("><<<<<<<<<<< %d",currentPage)
        let getView:UIView  = scrollView.viewWithTag((currentPage) + 555) ?? scrollView
        //getView.backgroundColor = UIColor.purple
        
        let views = scrollView.subviews
        for view in views{
            if scrollView.bounds.intersects(view.frame) {
                if view.tag>500{
                    
                        self.newTransForm(index: view.tag - 555, viewCell: view,scrollOffsetX: scrollView.contentOffset)
                }
            }
        }
     }
    
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
           

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
    
    
    @objc func didTap(tapGesture:UITapGestureRecognizer)
    {
        //check for tapped view
      let view = tapGesture.view
      let loc = tapGesture.location(in: view)
      let subview = view?.hitTest(loc, with: nil)
        if subview != nil{
                delegator?.carouselDidSelectItemAtIndex(scrollview: self.scrollView!, Index: subview!.tag -     555)
        }
    }

    
    func popAnimationState()
    {
        CATransaction.commit()
    }
    

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
        print(collectionViewSize)
        var final:CGPoint = CGPoint(x: CGFloat(row) * collectionViewSize.width + collectionViewSize.width / 2,
            y: collectionViewSize.height/2)
        //print(collectionViewSize)

            return final
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

        return  nextItemLeftEdge + (CGFloat(self.coverDensity) * CGFloat(self.requiredWidth!)) - projectedRightEdgeLocal
    }
    
    
    //////New Real
    func newTransForm(index:Int,viewCell:UIView,scrollOffsetX:CGPoint){
    /// let attributesPath = attributes.indexPath
        
        if(index==0){
        print(">>>>>>>Row",index)
        print(">>>>>>>Offset",scrollOffsetX)
        }
            let minInterval = CGFloat(index - 1) * CGFloat(self.requiredWidth!)
            let maxInterval = CGFloat(index + 1) * CGFloat(self.requiredWidth!)
            let minX = minXCenterForRow(index)
            let maxX = maxXCenterForRow(index)
            let spanX = maxX - minX
        print(">>>>>>>minX",minX)

    
        
        
        let finalvalue = CGFloat(minX) + ((CGFloat(spanX) / (CGFloat(maxInterval) - CGFloat(minInterval))) * (CGFloat(scrollOffsetX.x) - CGFloat(minInterval)))
        let vale = max(finalvalue, minX)
        
        let interpolatedX = min(vale, maxX)

            viewCell.center = CGPoint(x: viewCell.center.x, y: viewCell.center.y)

            var transform = CATransform3DIdentity

            // Add perspective ////change direction of scroll put negative perpective
            transform.m34 = kDistanceToProjectionPlane

            // Then rotate.
        let angle = CGFloat(-self.maxCoverDegree) + (CGFloat(interpolatedX) - CGFloat(minX)) * 2 * CGFloat(self.maxCoverDegree) / CGFloat(spanX)
            transform = CATransform3DRotate(transform, degreesToRad(CGFloat(angle)), xAngle!, yAngle!, zAngle!)

            // Then scale: 1 - abs(1 - Q - 2 * x * (1 - Q))
        //let scale = 1.0 - abs(1 - self.minCoverScale - (interpolatedX - minX) * 2 * (1.0 - self.minCoverScale) / spanX)
        //let scale = 1.0// - CGFloat(abs(1 - CGFloat(self.minCoverScale)) - (CGFloat(interpolatedX) - CGFloat(minX))) * 2 * (1.0 - CGFloat((self.minCoverScale)) / CGFloat(spanX))
        var scale = 1.0 - abs(1 - CGFloat(self.minCoverScale) - (CGFloat(interpolatedX) - CGFloat(minX)) * 2 * (1.0 - CGFloat(self.minCoverScale)) / CGFloat(spanX))
        print(">>>>>>>scale",scale)

        if(isGapDistanceEnabled == true){
            gapDistance = scale
        }
            
        print(">>>>>>>gapDistance",gapDistance)

      //
    transform = CATransform3DScale(transform, CGFloat(gapDistance!), CGFloat(scale), CGFloat(scale))
        
            // Apply transform
             viewCell.transform3D = transform
      
            // Add opacity: 1 - abs(1 - Q - 2 * x * (1 - Q))
            let opacity = 1.0 - abs(1 - CGFloat(self.minCoverOpacity) - (CGFloat(interpolatedX) - CGFloat(minX)) * 2 * (1 - CGFloat(self.minCoverOpacity)) / CGFloat(spanX))

        viewCell.alpha = CGFloat(opacity)
        print(">>>>>>>Angle",angle)

//        print(String(format:"IDX: %d. MinX: %.2f. MaxX: %.2f. Interpolated: %.2f. Interpolated angle: %.2f ..AScale : %.2f",
//                   index,
//                   minX,
//                   maxX,
//                   interpolatedX,
//                   angle,scale));


           // return attributes
    
    }

  

 
}
