//
//  ViewController.swift
//  CustomCarousel
//
//  Created by Sameer Junaid on 11/4/19.
//  Copyright © 2019 CodiftaLabs. All rights reserved.
//

import UIKit

class ViewController: UIViewController,AmazingComponentDelgateProtocol,AmazingComponentDataSourceProtocol {
   
    
    
    func viewForIndexPathAtFullView(component: AmazingComponent, atView: UIView, index: Int) -> UIView {
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        label.center = CGPoint(x: 160, y: 285)
        label.textAlignment = .center
        label.backgroundColor = UIColor.orange
        label.text = "I'm a test label"
        atView.addSubview(label)
        
        return atView
        
    }

    
    func requiredHeightandWidth(component: AmazingComponent) -> (Double,Double) {
            
        return (Double(self.view.frame.size.width),500)
    }
    
    func numberofViewsRequired(component: AmazingComponent) -> Int {
                return 10
    }
    
 
  
  
  var newView:AmazingComponent?
  override func viewDidLoad() {
      super.viewDidLoad()
      // Do any additional setup after loading the view.
      newView = AmazingComponent()
      newView?.frame=CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
      newView?.initWithView(view: self.view)
      newView?.isUserInteractionEnabled=true
      newView?.carouselType=CarouselType.Coverflow.rawValue
      //newView?.requiredSpacing=500
      newView?.isVertical=false
      newView?.delegator=self
      newView?.datasource=self
     
      self.view.addSubview(newView!)
      
  }

    
    func scrolldidScroll(scroll: UIScrollView) {
       // print(scroll.contentOffset)
    }
    
    
       
      

}

