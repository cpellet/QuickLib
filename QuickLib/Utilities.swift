//
//  Utilities.swift
//  QuickLib
//
//  Created by Cyrus Pellet on 17/07/2020.
//

import Foundation
import UIKit
import FirebaseFirestore
import SDWebImage

var lastLocation: String = "location"

func getBookCover(book: Book, completion: @escaping(_ image: UIImage) -> Void){
    if let cachedImage: UIImage = loadImageFromCacheWith(fileName: book.isbn!){
        completion(cachedImage)
        return
    }
    DispatchQueue.global().async {
        let manager = SDWebImageManager()
        if(book.coverURL==nil){return}
        manager.loadImage(with: URL(string: book.coverURL!), options: [], progress: nil){image,data,error,c,d,e in
            if let error = error{
                resolveCoverURLWithAmazon(isbn: book.isbn!){url in
                    if(url != nil){
                        Firestore.firestore().collection(UserDefaults.standard.string(forKey: "libraryID") ?? "books").document(book.isbn!).updateData(["coverURL":url])
                        print("UPDATED BOOK COVER VIA AMAZON")
                    }
                }
            }else{
                saveImageToCache(imageName: book.isbn!, image: image!)
                completion(image!)
            }
        }
    }
}

func getLocations(completion: @escaping(_ locations: [String]?)->Void){
    var locations: [String] = []
    Firestore.firestore().collection("\(UserDefaults.standard.string(forKey: "libraryID") ?? "books")-locations").getDocuments(){(querySnapshot, err) in
        if let err = err{
            print("Error getting documents: \(err)")
            completion(nil)
        }else{
            for document in querySnapshot!.documents{
                let location = document["name"]
                locations.append(location as! String)
            }
            completion(locations)
        }
    }
}

func saveImageToCache(imageName: String, image: UIImage, jpg: Bool = false) {
 guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
    let fileURL = cacheDirectory.appendingPathComponent(imageName)
    guard let data = (jpg) ? image.jpegData(compressionQuality: 1.0): image.pngData() else { return }
    if FileManager.default.fileExists(atPath: fileURL.path) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        } catch let removeError {
            print("couldn't remove file at path", removeError)
        }
    }
    do {
        try data.write(to: fileURL)
    } catch let error {
        print("error saving file with error", error)
    }
}

func loadImageFromCacheWith(fileName: String) -> UIImage? {
    let cachesDirectory = FileManager.SearchPathDirectory.cachesDirectory
    let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
    let paths = NSSearchPathForDirectoriesInDomains(cachesDirectory, userDomainMask, true)
    if let dirPath = paths.first {
        let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
        let image = UIImage(contentsOfFile: imageUrl.path)
        return image
    }
    return nil
}

extension UIImage{
    func scaleImage(newSize: CGSize) -> UIImage{
        var scaledSize: CGSize = newSize
        var scaleFactor: Float = 1.0
        if(self.size.width > self.size.height){
            scaleFactor = Float(self.size.width / self.size.height)
            scaledSize.width = newSize.width
            scaledSize.height = newSize.height / CGFloat(scaleFactor)
        }else{
            scaleFactor = Float(self.size.height / self.size.width)
            scaledSize.height = newSize.height
            scaledSize.width = newSize.width / CGFloat(scaleFactor)
        }
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)
        let scaledImageRect: CGRect = CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height)
        self.draw(in: scaledImageRect)
        let scaledImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return scaledImage
    }
}

extension String {
 func getCleanedURL() -> URL? {
    guard self.isEmpty == false else {
        return nil
    }
    if let url = URL(string: self) {
        return url
    } else {
        if let urlEscapedString = self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) , let escapedURL = URL(string: urlEscapedString){
            return escapedURL
        }
    }
    return nil
 }
}

extension String {

    init?(htmlEncodedString: String) {

        guard let data = htmlEncodedString.data(using: .utf8) else {
            return nil
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }

        self.init(attributedString.string)

    }

}
