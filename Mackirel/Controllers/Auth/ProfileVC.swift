//
//  ProfileVC.swift
//  Mackirel
//
//  Created by brian on 5/20/21.
//

import Foundation
import UIKit

class ProfileVC: UIViewController {

    @IBOutlet weak var lbUserName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let data = UserDefaults.standard.object(forKey: "userAuthData")
        let objUser = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! [String: Any]
        let userAuth = UserAuthModel(fromDictionary: objUser)
        
        self.lbUserName.text = "\(userAuth.first_name!) \(userAuth.last_name!)"
    }


}