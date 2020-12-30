//
//  ManualAddViewController.swift
//  QuickLib
//
//  Created by Cyrus Pellet on 02/08/2020.
//

import UIKit
import FirebaseFirestore
import JGProgressHUD

class ManualAddViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var isbnField: UITextField!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var authorField: UITextField!
    @IBOutlet weak var coverUrlField: UITextField!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var addBookButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isbnField.delegate = self
        titleField.delegate = self
        authorField.delegate = self
        coverUrlField.delegate = self
        self.locationButton.setTitle("Will add book to: \(lastLocation)", for: .normal)
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func isbnEditingDidEnd(_ sender: Any) {
        resolveBookMetadata(isbn: isbnField.text!){book in
            DispatchQueue.main.async {
                self.titleField.text = book?.title
                self.authorField.text = book?.authors.first
                self.coverUrlField.text = book?.coverURL
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    @IBAction func addLocationButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Set book location", message: "Choose an existing location below", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in}))
        getLocations(){locations in
            for location in locations!{
                alert.addAction(UIAlertAction(title: location, style: .default, handler: { action in
                    lastLocation = location
                    self.locationButton.setTitle("Will add book to: \(location)", for: .normal)
                }))
            }
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addBookButtonTapped(_ sender: Any) {
        let db = Firestore.firestore()
        db.collection(UserDefaults.standard.string(forKey: "libraryID") ?? "books").document(isbnField.text!).setData([
            "title":titleField.text,
            "author":authorField.text,
            "coverURL":coverUrlField.text,
            "isbn":isbnField.text,
            "location": lastLocation
        ]){err in
            if let err = err{
                print("Error adding document: \(err)")
            }else{
                let HUD = JGProgressHUD()
                HUD.textLabel.text = "Book was added"
                HUD.indicatorView = JGProgressHUDSuccessIndicatorView()
                HUD.show(in: self.view)
                HUD.dismiss(afterDelay: 2.0)
                DispatchQueue.main.async {
                    self.isbnField.text = ""
                    self.titleField.text = ""
                    self.authorField.text = ""
                    self.coverUrlField.text = ""
                }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0, execute: {self.dismiss(animated: true)})
            }
        }
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
