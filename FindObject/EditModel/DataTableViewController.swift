//
//  DataTableViewController.swift
//  FindObject
//
//  Created by 安江洸希 on 2022/11/11.
//

import UIKit

class DataTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableview: UITableView!
    var filenameArray: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "データ選択"
        
        filenameArray = DataManagement.getEntireDataCount()
        setup()
        print(filenameArray!)
    }
    
    func setup() {
        if let index = filenameArray.firstIndex(of: "保存前") {
            filenameArray.remove(at: index)
        }
        
        if let index2 = filenameArray.firstIndex(of: ".Trash") {
            filenameArray.remove(at: index2)
        }
    }
    
    //cellの数
    func tableView(_ tableview: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filenameArray.count
    }
    //cellに値を設定
    func tableView(_ tableview: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "data_cell", for: indexPath)
        cell.textLabel?.text = filenameArray[indexPath.row]
        //cell.detailTextLabel?.text = "b"
        return cell
    }
    //cellを選択直後に呼び出し
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: "EditView", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        vc.filename = filenameArray[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //セルの編集許可
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    //スワイプしたセルを削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            
            let remove_filename = filenameArray[indexPath.row]
            DataManagement.removeDirectory(name: remove_filename)
            filenameArray.remove(at: indexPath.row)

            //セル更新
            tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
        }
    }
    
}
