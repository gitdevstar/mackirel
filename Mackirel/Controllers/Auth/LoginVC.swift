//
//  LoginVC.swift
//  Mackirel
//
//  Created by brian on 5/19/21.
//

import Foundation
import UIKit
import MaterialComponents
import UITextField_Shake
import NVActivityIndicatorView

class LoginVC: UIViewController, UITextFieldDelegate, NVActivityIndicatorViewable {

    @IBOutlet weak var txtEmail: UITextField! {
        didSet {
            txtEmail.delegate = self
        }
    }
    @IBOutlet weak var txtPassword: UITextField!
    
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var btnRegister: UIButton!
    @IBOutlet weak var btnForgotPassword: UIButton!
    
    var defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("here")
    }

    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       self.navigationController?.isNavigationBarHidden = true
       
   }

   override func viewWillDisappear(_ animated: Bool) {
       super.viewWillDisappear(animated)
       self.navigationController?.isNavigationBarHidden = false
   }
    
    func login() {
        guard let email = txtEmail.text else {
                    return
                }
        guard let password = txtPassword.text else {
            return
        }
        if email.isEmpty {
            self.txtEmail.shake(6, withDelta: 10, speed: 0.06)
        }
        else if !email.isValidEmail {
            self.txtEmail.shake(6, withDelta: 10, speed: 0.06)
        }
        else if password.isEmpty {
             self.txtPassword.shake(6, withDelta: 10, speed: 0.06)
        }
        else {
            let param : [String : Any] = [
                "email" : email,
                "password": password,
                "device_id" : "ios",
                "device_token" : "ios"
            ]
            
//                    self.showLoader()
            self.startAnimating()
            RequestHandler.loginUser(parameter: param as NSDictionary, success: { (successResponse) in
                        self.stopAnimating()
                let dictionary = successResponse as! [String: Any]
                let success = dictionary["success"] as! Bool
                var user : UserAuthModel!
                if success {
                    if let userData = dictionary["user"] as? [String:Any] {
                        
                        user = UserAuthModel(fromDictionary: userData)
                    }

                    self.defaults.set(true, forKey: "isLogin")
                    self.defaults.synchronize()
                    let mainVC = self.storyboard?.instantiateViewController(withIdentifier: "SplashVC") as! SplashVC
                    self.navigationController?.pushViewController(mainVC, animated: true)
                } else {
                    let alert = Alert.showBasicAlert(message: dictionary["message"] as! String)
                    self.presentVC(alert)
                }
            }) { (error) in
                        self.stopAnimating()
                let alert = Alert.showBasicAlert(message: error.message)
                        self.presentVC(alert)
            }
        }
    }
    
    @IBAction func submit(_ sender: Any) {
        self.login()
    }
    
    
}