//
//  MenuViewController.swift
//  FindObject
//
//  Created by 安江洸希 on 2022/11/11.
//

import Foundation
import UIKit

class MenuViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tapped_mappingButton(_ sender: UIButton) {
        print("マッピング画面に遷移")
        let storyboard = UIStoryboard(name: "MappingView", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MappingViewController") as! MappingViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func tapped_editButton(_ sender: UIButton) {
        print("データ選択画面に遷移")
        let storyboard = UIStoryboard(name: "EditView", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DataTableViewController") as! DataTableViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
