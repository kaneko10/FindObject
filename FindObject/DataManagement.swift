//
//  DataManagement.swift
//  FindObject
//
//  Created by 金子友南 on 2022/10/24.
//

import Foundation

class DataManagement {
    
    //ディレクトリ作成
    static func makeDirectory(name: String) {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let directory_pass = url.appendingPathComponent("\(name)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: directory_pass, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("ディレクトリ作成：失敗")
            }
        }
    }
    
    //ディレクトリ削除
    static func removeDirectory(name: String) {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                try FileManager.default.removeItem(at: url.appendingPathComponent(name))
                print("ディレクトリ削除：成功")
            } catch _ {
                print("ディレクトリ削除：失敗 or 存在しない")
            }
        }
    }
    
    //ディレクトリのリネーム
    static func rename(oldName: String, newName: String) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let atPathName = "\(paths)/\(oldName)"
        let toPathName = "\(paths)/\(newName)"
        do {
            try FileManager.default.moveItem(atPath: atPathName, toPath: toPathName)
            print("ディレクトリ:リネーム成功")
        } catch {
            print("ディレクトリ:リネーム失敗")
        }
    }
    
    //データ保存
    static func saveData(name: String, Data: Data) {
        //ディレクトリ内にデータを保存
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dataPath = url.appendingPathComponent("\(name)")
            do {
                try Data.write(to: dataPath)
            } catch {
                print("データ保存失敗", error)
            }
        }
    }
    
    //データ取得
    static func getData(name: String) -> Data {
        var data: Data!
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dataPath = url.appendingPathComponent("\(name)")
            data = try! Data(contentsOf: dataPath)
        }
        return data
    }
    
    //データ数取得
    static func getDataCount(name: String) -> Int {
        var count = 0
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dataPath = url.appendingPathComponent("\(name)")
            do {
                let contentUrls = try FileManager.default.contentsOfDirectory(at: dataPath, includingPropertiesForKeys: nil)
                print(contentUrls.count)
                count = contentUrls.count
                //        let files = contentUrls.map{$0.lastPathComponent}
                //        print(files)
            } catch {
                print(error)
            }
        }
        return count
    }
    
    //全体のデータ数取得
    static func getEntireDataCount() -> [String] {
        var filenameArray = [String]()
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let contentUrls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                //print(contentUrls.count)
                filenameArray = contentUrls.map{$0.lastPathComponent}
            } catch {
                print(error)
            }
        }
        return filenameArray
    }
}
