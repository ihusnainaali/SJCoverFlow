//
//  ViewController.swift
//  CustomCarousel
//
//  Created by Sameer JD on 11/4/19.
//  Copyright © 2019 CodiftaLabs. All rights reserved.
//

import UIKit

class ViewController: UIViewController,SJCarouselDelgateProtocol,SJCarouselDataSourceProtocol {
   
    func carouselDidSelectItemAtIndex(scrollview: UIScrollView, Index: Int) {
        
               // print(Index)

    }
    
   
    
    
    func carouselGetCurrentIndex(scroll: UIScrollView, currentIndex: Int) {
       // print(currentIndex)
    }
    
  
    
    func carouselDidEndScrollingAnimation(scroll: UIScrollView) {
        
    }
    
   
    
    
    func viewForIndexPathAtFullView(component: SJCarousel, atView: UIView, index: Int) -> UIView {
        
        let backgroundImage = UIImageView()
        backgroundImage.frame = CGRect.init(x: 0, y:  0, width:240, height:380)
        backgroundImage.image = UIImage(named:"page")
        backgroundImage.clipsToBounds = true
        backgroundImage.contentMode = .scaleAspectFill
        atView.addSubview(backgroundImage)

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 21))
        label.textAlignment = .center
        label.backgroundColor = UIColor.orange
        label.text = "I'm a test label"
       // atView.addSubview(label)
        //atView.backgroundColor = .magenta
        
        
        return atView
        
    }

    
    func requiredHeightandWidth(component: SJCarousel) -> (Double, Double, Double, Double) {
            
        return (Double( 240),380,30,180)
    }
    
    func numberofViewsRequired(component: SJCarousel) -> Int {
                return 10
    }
    
 
  
  
  var newView:SJCarousel?
  override func viewDidLoad() {
      super.viewDidLoad()
    
    self.view.backgroundColor = UIColor.orange
      // Do any additional setup after loading the view.
      newView = SJCarousel()
      newView?.frame=CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
      newView?.initWithView(view: self.view)
      newView?.isUserInteractionEnabled=true
      newView?.carouselType=CarouselType.Cylinder.rawValue
      //newView?.requiredSpacing=500
      newView?.carouselDirectionRight = true
      newView?.isVertical=false
      newView?.delegator=self
      newView?.datasource=self
      newView?.backgroundImage!.image = UIImage(named:"background")

      self.view.addSubview(newView!)
      
  }

    
    func scrolldidScroll(scroll: UIScrollView) {
      //  print(scroll.contentOffset)
    }
    
    
       
      

}

