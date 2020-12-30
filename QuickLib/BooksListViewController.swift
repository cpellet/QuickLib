//
//  BooksListViewController.swift
//  QuickLib
//
//  Created by Cyrus Pellet on 17/07/2020.
//

import UIKit
import FirebaseFirestore
import JGProgressHUD
import DJSemiModalViewController

class BooksListViewController: UITableViewController {
    
    var books: [Book] = []
    var filteredBooks: [Book] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isSearchBarEmpty: Bool{
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool{
        return searchController.isActive && !isSearchBarEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        refreshControl = UIRefreshControl()
        self.view.addSubview(refreshControl!)
        refreshControl?.addTarget(self, action: #selector(fetchData(_:)), for: .valueChanged)
        searchController.searchResultsUpdater = self
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.obscuresBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.placeholder = "Search books"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchData(self)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0, execute: {
            if((UIApplication.shared.delegate as! AppDelegate).shouldAddImmediately){
                self.tabBarController?.selectedIndex = 1
            }
        })
    }
    
    @objc private func fetchData(_ sender: AnyObject){
        books = []
        let delegate = UIApplication.shared.delegate as! AppDelegate
        Firestore.firestore().collection(UserDefaults.standard.string(forKey: "libraryID") ?? "books").getDocuments(){(querySnapshot, err) in
            if let err = err{
                let HUD = JGProgressHUD()
                HUD.indicatorView = JGProgressHUDErrorIndicatorView()
                HUD.textLabel.text = "Failed to retreive books"
                HUD.show(in: self.view)
                print("Error getting documents: \(err)")
                self.refreshControl?.endRefreshing()
            }else{
                for document in querySnapshot!.documents{
                    let book = Book(title: document["title"] as! String, authors: [document["author"] as! String], coverURL: (document["coverURL"] as? String) ?? "", isbn: document["isbn"] as! String, location: document["location"] as! String)
                    delegate.knownISBNs.append(document["isbn"] as! String)
                    self.books.append(book)
                }
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
                print(self.books.count)
            }
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
      filteredBooks = books.filter { (book: Book) -> Bool in
        return (book.title.lowercased().contains(searchText.lowercased()) || book.authors.first!.lowercased().contains(searchText.lowercased()))
        }
      tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let controller = DJSemiModalViewController()
        let book: Book
        if isFiltering{
            book = filteredBooks[indexPath.row]
        }else{
            book = books[indexPath.row]
        }
        controller.title = book.title
        let authorLabel = UILabel()
        authorLabel.textColor = .secondaryLabel
        authorLabel.text = book.authors.first
        authorLabel.textAlignment = .center
        controller.addArrangedSubview(view: authorLabel, height: 50)
        let coverView = UIImageView()
        coverView.contentMode = .scaleAspectFit
        getBookCover(book: book){image in
            coverView.image = image.scaleImage(newSize: CGSize(width: 200, height: 200))
        }
        controller.addArrangedSubview(view: coverView)
        let ISBNLabel = UILabel()
        ISBNLabel.textColor = .placeholderText
        ISBNLabel.text = "ISBN: \(book.isbn!)"
        controller.addArrangedSubview(view: ISBNLabel)
        let locationLabel = UILabel()
        locationLabel.textColor = .placeholderText
        locationLabel.text = "Location: \(book.location!)"
        controller.addArrangedSubview(view: locationLabel)
        controller.minYOffset = 60.0
        controller.presentOn(presentingViewController: self, animated: true, onDismiss: {})
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(books.count == 0){
            tableView.setEmptyView(title: "No books found", message: "You can add books with the Add tab")
        }else{
            tableView.restore()
        }
        if(isFiltering){
            return filteredBooks.count
        }
        return books.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookCell", for: indexPath) as! BookCell
        let book: Book
        if isFiltering{
            book = filteredBooks[indexPath.row]
        }else{
            book = books[indexPath.row]
        }
        cell.authorLabel.text = book.authors.first
        cell.titleLabel.text = book.title
        getBookCover(book: book){image in
            DispatchQueue.main.async {
                cell.coverView.image = image
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Remove book", message: "Are you sure you want to remove this book?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in tableView.endEditing(false)}))
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { action in
                Firestore.firestore().collection(UserDefaults.standard.string(forKey: "libraryID") ?? "books").document(self.books[indexPath.row].isbn!).delete()
                self.books.remove(at: indexPath.row)
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

class BookCell: UITableViewCell{
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
}

extension UITableView {
    func setEmptyView(title: String, message: String) {
        let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont(name: "HelveticaNeue-Regular", size: 17)
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)
        titleLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 20).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -20).isActive = true
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        self.backgroundView = emptyView
        self.separatorStyle = .none
    }
    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}

extension BooksListViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}
