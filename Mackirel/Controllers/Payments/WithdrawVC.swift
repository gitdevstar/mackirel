//
//  WithdrawVC.swift
//  Mackirel
//
//  Created by brian on 6/14/21.
//

import UIKit
import NVActivityIndicatorView
import LinkKit

class WithdrawVC: UIViewController, UITextFieldDelegate, NVActivityIndicatorViewable {
    
    var balance = 0.0
    var paypal: String!
    var withdrawFee = 0.0

    var bank: String!
    var stripeAccountVerified = false
    var type: String!
    var selectedCard: String!
    var handler: Handler!
    
    @IBOutlet weak var lbBalance: UILabel!
    
    @IBOutlet weak var txtAmount: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        self.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
        self.getOpenLink()
    }
    
    func loadData() {
        self.startAnimating()
        let param : [String : Any] = [:]
        RequestHandler.getRequest(url: Constants.URL.SELLER_BALANCE, params: param as NSDictionary, success: { (successResponse) in
                        self.stopAnimating()
            let dictionary = successResponse as! [String: Any]
            
            self.balance = (dictionary["balance"] as! NSString).doubleValue
            
            self.lbBalance.text = PriceFormat.init(amount: self.balance, currency: Currency.usd).description
            self.paypal = dictionary["paypal"] as? String
            self.bank = dictionary["stripe_bank"] as? String
            self.withdrawFee = (dictionary["withdraw_fee"] as! NSString).doubleValue
            
            self.stripeAccountVerified = (dictionary["stripe_account_verified"] as! Int) == 0 ? false : true
            
            }) { (error) in
                        self.stopAnimating()
                let alert = Alert.showBasicAlert(message: error.message)
                        self.presentVC(alert)
            }
    }
    
    func submitWithdraw(amount: String) {
        let param : [String : Any] = [
            "type": self.type!,
            "amount": amount,
            "paypal": self.paypal!,
            "card_id": self.selectedCard!
        ]
        self.startAnimating()
        RequestHandler.getRequest(url: Constants.URL.REQUEST_CASHOUT, params: param as NSDictionary, success: { (successResponse) in
                        self.stopAnimating()
            let dictionary = successResponse as! [String: Any]
            
            self.balance = (dictionary["balance"] as! NSString).doubleValue
            
            self.lbBalance.text = PriceFormat.init(amount: self.balance, currency: Currency.usd).description
            
            self.showToast(message: dictionary["message"] as! String)
        }) { (error) in
                        self.stopAnimating()
            let alert = Alert.showBasicAlert(message: error.message)
                    self.presentVC(alert)
        }
    }
    
    func createStripeConnectLink(create: Bool) {
        let param : [String: Any] = [:]
        self.startAnimating()
        RequestHandler.getRequest(url: Constants.URL.REQUEST_STRIPE_CONNECT, params: param as NSDictionary, success: { (successResponse) in
                        self.stopAnimating()
            let dictionary = successResponse as! [String: Any]
            
            self.stripeAccountVerified = (dictionary["stripe_account_verified"] as! Int) == 0 ? false : true
            
            if self.stripeAccountVerified {
                let alert = Alert.showBasicAlert(message: dictionary["message"] as! String)
                self.presentVC(alert)
            } else {
                if create {
                    let webviewController = self.storyboard?.instantiateViewController(withIdentifier: "webVC") as! webVC
                    webviewController.url = dictionary["stripe_connect_link"] as! String
                    self.navigationController?.pushViewController(webviewController, animated: true)
                } else {
                    let alert = Alert.showBasicAlert(message: "Not connected")
                    self.presentVC(alert)
                }
            }
            
            
            
        }) { (error) in
                        self.stopAnimating()
            let alert = Alert.showBasicAlert(message: error.message)
                    self.presentVC(alert)
        }
    }
    
    func checkValidate() -> Bool {
        guard let amount = txtAmount.text else {
            return false
        }
        if !amount.isValid(regex: "/^\\d*\\.?\\d*$/") {
             self.txtAmount.shake(6, withDelta: 10, speed: 0.06)
            return false
        }
       
            if Double(amount)! > self.balance {
                let alert = Alert.showBasicAlert(message: "Insufficient balance")
                self.presentVC(alert)
                return false
            }
        
        
        
        return true
    }
    
    func openPlaid() {
        let method: PresentationMethod = .viewController(self)
        
        self.handler.open(presentUsing: method)
    }
    
    func connectPlaid(linkToken: String) {
        let configuration = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { linkSuccess in
                // Send the linkSuccess.publicToken to your app server.
                
                self.sendPlaid(pubToken: linkSuccess.publicToken, accountId: linkSuccess.metadata.accounts[0].id)
            }
        )
        
        let result = Plaid.create(configuration)
        
        switch result {
          case .failure(let error):
            let alert = Alert.showBasicAlert(message: "Unable to create Plaid handler due to: \(error)")
            self.presentVC(alert)
          case .success(let handler):
              self.handler = handler
            
        }
    }
    
    func getOpenLink() {
        let param : [String: Any] = [:]
        self.startAnimating()
        RequestHandler.getRequest(url: Constants.URL.GET_PLAID_LINK_TOKEN, params: param as NSDictionary, success: { (successResponse) in
                        self.stopAnimating()
            let dictionary = successResponse as! [String: Any]
            
            self.connectPlaid(linkToken: dictionary["link_token"] as! String)
            
            
            
        }) { (error) in
                        self.stopAnimating()
            let alert = Alert.showBasicAlert(message: error.message)
                    self.presentVC(alert)
        }
    }
    
    func sendPlaid(pubToken: String, accountId: String) {
        let param : [String: Any] = [
            "pub_token": pubToken,
            "account_id": accountId
        ]
        self.startAnimating()
        RequestHandler.postRequest(url: Constants.URL.REQUEST_STRIPE_CONNECT, params: param as NSDictionary, success: { (successResponse) in
                        self.stopAnimating()
            let dictionary = successResponse as! [String: Any]
            
            self.showToast(message: dictionary["message"] as! String)
            
        }) { (error) in
                        self.stopAnimating()
            let alert = Alert.showBasicAlert(message: error.message)
                    self.presentVC(alert)
        }
    }
    
    
    @IBAction func onAddBank(_ sender: Any) {
        if bank.isEmpty {
            if stripeAccountVerified {
                //Plaid
                openPlaid()
            } else {
                let alert = Alert.showConfirmAlert(message: "No connected account. Would you connect?", handler: {
                                                    (_) in self.createStripeConnectLink(create: true)}
                )
                self.presentVC(alert)
            }
        } else {
            let alert = Alert.showConfirmAlert(message: "Connected to \(bank!) already. Would you replace with other bank?", handler: {
                                                (_) in }
            )
            self.presentVC(alert)
        }
    }
    
    
    
    @IBAction func onCreateStripe(_ sender: Any) {
    }
    
    
    @IBAction func onWithdrawtoBank(_ sender: Any) {
        self.type = "bank"
        
        let validate = self.checkValidate()
        
        if !validate {
            return
        }
        let amount = self.txtAmount.text!
        let alert = Alert.showConfirmAlert(message: "Payout amount: $\(amount) ? \n Withdraw fee: $\(self.withdrawFee)", handler: {(_) in
            self.submitWithdraw(amount: amount)
        })
        self.presentVC(alert)
    }
    
    @IBAction func onWithdrawToPaypal(_ sender: Any) {
        self.type = "paypal"
        
        let validate = self.checkValidate()
        
        if !validate {
            return
        }
        let amount = self.txtAmount.text!
        let alert = Alert.showConfirmAlert(message: "Payout amount: $\(amount) ? \n Withdraw fee: $\(self.withdrawFee)", handler: {(_) in
            self.submitWithdraw(amount: amount)
        })
        self.presentVC(alert)
    }
}