//
//  AddBookViewController.swift
//  QuickLib
//
//  Created by Cyrus Pellet on 17/07/2020.
//

import UIKit
import FirebaseFirestore
import JGProgressHUD

class AddBookViewController: UIViewController {
    
    var book: Book?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var addBookButton: UIButton!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.titleLabel.text = self.book?.title
        self.authorLabel.text = self.book?.authors.first
        self.locationButton.setTitle("Will add book to: \(lastLocation)", for: .normal)
        if(delegate.knownISBNs.contains((self.book?.isbn!)!)){
            addBookButton.isEnabled = false
            addBookButton.backgroundColor = UIColor.lightGray
            addBookButton.setTitle(" Book already was added ", for: .disabled)
        }
        getBookCover(book: book!){image in
            DispatchQueue.main.async {
                self.coverView.image = image
            }
        }
    }
    
    @IBAction func changeLocationTapped(_ sender: Any) {
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
    
    
    @IBAction func addBookPressed(_ sender: Any) {
        book?.location = lastLocation
        let db = Firestore.firestore()
        db.collection(UserDefaults.standard.string(forKey: "libraryID") ?? "books").document((book?.isbn)!).setData([
            "title":book?.title,
            "author":book?.authors.first,
            "coverURL":book?.coverURL,
            "isbn":book?.isbn,
            "location": book?.location
        ]){err in
            if let err = err{
                print("Error adding document: \(err)")
            }else{
                let HUD = JGProgressHUD()
                HUD.textLabel.text = "Book was added"
                HUD.indicatorView = JGProgressHUDSuccessIndicatorView()
                HUD.show(in: self.view)
                HUD.dismiss(afterDelay: 2.0)
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
