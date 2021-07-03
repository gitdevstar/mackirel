//
//  BuyerPagerVC.swift
//  Mackirel
//
//  Created by brian on 7/3/21.
//


import UIKit
import XLPagerTabStrip
import NVActivityIndicatorView

class BuyerPagerVC: SegmentedPagerTabStripViewController, NVActivityIndicatorViewable {
    var isReload = false
    
    var orderList = [OrderModel]()
    var historyList = [OrderModel]()
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        settings.style.segmentedControlColor = .green
    }
    
    override func viewDidLoad() {
       
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.looadData()
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        

        
        let child1 = self.storyboard?.instantiateViewController(withIdentifier: "OrdersVC") as! OrdersVC
        let child2 = self.storyboard?.instantiateViewController(withIdentifier: "OrdersHistoryVC") as! OrdersHistoryVC
        
        child1.orderList = orderList
        child2.historyList = historyList
        
        return [child1, child2]

        
    }
    
    func looadData() {
        let param : [String : Any] = [:]
        self.startAnimating()
        self.startAnimating()
        RequestHandler.getRequest(url: Constants.URL.ORDER_LIST, params: param as NSDictionary, success: { (successResponse) in
            self.stopAnimating()
            let dictionary = successResponse as! [String: Any]
            
            
            var order: OrderModel!
            
            
            if let data = dictionary["data"] as? [[String:Any]] {
                
                self.orderList = [OrderModel]()
                
                for item in data {
                    order = OrderModel(fromDictionary: item)
                    if order.status == "Processing" {
                        self.orderList.append(order)
                    } else {
                        self.orderList.append(order)
                    }
                    
                }
            }
            if let data = dictionary["wining_auction"] as? [[String:Any]] {
                
                self.historyList = [OrderModel]()
                
                for item in data {
                    order = OrderModel(fromDictionary: item)
                    self.historyList.append(order)
                }
            }
            
            
            self.reloadPagerTabStripView()
                    
        }) { (error) in
            let alert = Alert.showBasicAlert(message: error.message)
                    self.presentVC(alert)
        }
        
    }
    
    
}

