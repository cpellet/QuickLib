//
//  SettingsViewController.swift
//  QuickLib
//
//  Created by Cyrus Pellet on 17/07/2020.
//

import UIKit

class SettingsViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var libraryIDField: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        libraryIDField.delegate = self
        libraryIDField.text = UserDefaults.standard.string(forKey: "libraryID") ?? "books"
        // Do any additional setup after loading the view.
    }
    
    @IBAction func libraryIDEditingDidEnd(_ sender: Any) {
        let alert = UIAlertController(title: "Change library ID", message: "Are you sure you want to switch library?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in}))
        alert.addAction(UIAlertAction(title: "Switch", style: .destructive, handler: { action in
            UserDefaults.standard.set(self.libraryIDField.text, forKey: "libraryID")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func deleteCachedCoversPressed(_ sender: Any) {
        let cacheURL =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        do {
            let directoryContents = try! FileManager.default.contentsOfDirectory( at: cacheURL, includingPropertiesForKeys: nil, options: [])
            for file in directoryContents {
                do {
                    try FileManager.default.removeItem(at: file)
                }catch let error as NSError {
                    debugPrint("Ooops! Something went wrong: \(error)")
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
