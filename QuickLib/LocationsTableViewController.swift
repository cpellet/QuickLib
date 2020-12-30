//
//  LocationsTableViewController.swift
//  QuickLib
//
//  Created by Cyrus Pellet on 17/07/2020.
//

import UIKit
import FirebaseFirestore
import JGProgressHUD

class LocationsTableViewController: UITableViewController {
    
    var locations: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addLocation(_:))), animated: false)
    }
    
    @objc func addLocation(_ sender: AnyObject){
        let alert = UIAlertController(title: "Add a location", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Location name"
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if let name = alert.textFields?.first?.text {
                Firestore.firestore().collection("\(UserDefaults.standard.string(forKey: "libraryID")!)-locations").addDocument(data: ["name":name])
                self.locations.append(name)
                self.tableView.insertRows(at: [IndexPath(row: self.locations.count-1, section: 0)], with: .fade)
            }
        }))
        self.present(alert, animated: true)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        locations = []
        Firestore.firestore().collection("\(UserDefaults.standard.string(forKey: "libraryID")!)-locations").getDocuments(){(querySnapshot, err) in
            if let err = err{
                let HUD = JGProgressHUD()
                HUD.indicatorView = JGProgressHUDErrorIndicatorView()
                HUD.textLabel.text = "Failed to retreive locations"
                HUD.show(in: self.view)
                print("Error getting documents: \(err)")
                self.refreshControl?.endRefreshing()
            }else{
                for document in querySnapshot!.documents{
                    let location = document["name"]
                    self.locations.append(location as! String)
                }
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(locations.count == 0){
            tableView.setEmptyView(title: "No locations", message: "Add locations by tapping +")
        }else{
            tableView.restore()
        }
        return locations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath) as! UITableViewCell
        cell.textLabel?.text = locations[indexPath.row]
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Remove location", message: "Are you sure you want to remove this location?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in tableView.endEditing(false)}))
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { action in
                Firestore.firestore().collection("\(UserDefaults.standard.string(forKey: "libraryID")!)-locations").document(self.locations[indexPath.row]).delete()
                self.locations.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
