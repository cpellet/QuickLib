//
//  BookMetadataResolver.swift
//  QuickLib
//
//  Created by Cyrus Pellet on 18/07/2020.
//

import Foundation

func resolveBookMetadata(isbn: String, completion: @escaping (_ book: Book?) -> Void){
    resolveWithGoogleAPI(isbn: isbn){res in
        if res == nil{
            resolveWithOpenLibraryAPI(isbn: isbn){res in
                if res == nil{
                    resolveWithAmazon(isbn: isbn){book in
                        completion(book)
                    }
                }else{
                    completion(res);return
                }
            }
        }else{
            completion(res);return
        }
    }
}

func resolveWithGoogleAPI(isbn: String, completion: @escaping (_ book: Book?) -> Void){
    let dataURL = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)")!
    let dataTask = URLSession.shared.dataTask(with: dataURL){data, res, error in
        guard let data = data, error == nil else{completion(nil); return}
        do{
            let books: QLGoogleAPIResolution.Response = try JSONDecoder().decode(QLGoogleAPIResolution.Response.self, from: data)
            var book = books.items.first!.volumeInfo
            book.isbn = isbn
            if(book.imageLinks != nil){
                book.coverURL = "http://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg"
            }else{
                book.coverURL = book.imageLinks?.thumbnail
            }
            completion(book)
        }catch{
            print(error)
            completion(nil)
        }
    }
    dataTask.resume()
}

func resolveWithOpenLibraryAPI(isbn: String, completion: @escaping (_ book: Book?) -> Void){
    let dataURL = URL(string: "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&jscmd=data&format=json")!
    let dataTask = URLSession.shared.dataTask(with: dataURL){data, res, error in
        guard let data = data, error == nil else{completion(nil); return}
        do{
            let books: [String: QLOpenLibraryAPIResolution.Response] = try JSONDecoder().decode([String: QLOpenLibraryAPIResolution.Response].self, from: data)
            if((books.first == nil)){
                completion(nil); return
            }
            let book = Book(title: (books.first?.value.title)!, authors: [books.first!.value.authors.first!.name], imageLinks: nil, coverURL: "http://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg", isbn: isbn, location: nil)
            completion(book)
        }catch{
            print(error)
            completion(nil)
        }
    }
    dataTask.resume()
}

func resolveWithAmazon(isbn: String, completion: @escaping (_ book: Book?) -> Void){
    let dataURL = "https://www.amazon.fr/s?k=\(isbn)&__mk_fr_FR=ÅMÅŽÕÑ&ref=nb_sb_noss".getCleanedURL()!
    let dataTask = URLSession.shared.dataTask(with: dataURL){data, res, error in
        guard let data = data, error == nil else{print(error); return}
        let string = String(data: data, encoding: .utf8)
        //TITLE
        let trange = string?.range(of: "a-size-medium a-color-base a-text-normal")
        guard trange != nil else {completion(nil); return}
        let tstart = string?.index(trange!.upperBound, offsetBy: 13)
        let tend = string?.index(trange!.upperBound, offsetBy: 50)
        let title = string![tstart!..<tend!].split(separator: "<").first
        //AUTHOR
        let arange = string?.range(of: "<span class=\"a-size-base\" dir=\"auto\">de </span>")
        let astart = string?.index(arange!.upperBound, offsetBy: 20)
        let aend = string?.index(arange!.upperBound, offsetBy: 180)
        let author = string![astart!..<aend!].split(separator: ">")[1].split(separator: "<").first
        //COVER
        let crange = string?.range(of: "a-section aok-relative s-image-fixed-height")
        let cstart = string?.index(crange!.upperBound, offsetBy: 63)
        let cend = string?.index(crange!.upperBound, offsetBy: 500)
        let coverURL = string![cstart!..<cend!].split(separator: "\"").first
        completion(Book(title: String(htmlEncodedString: String(title!))!, authors: [String(htmlEncodedString: String(author!))!], imageLinks: nil, coverURL: String(coverURL!), isbn: isbn, location: nil))
    }
    dataTask.resume()
}

func resolveCoverURLWithAmazon(isbn: String, completion: @escaping (_ url: String?) -> Void){
    let dataURL = "https://www.amazon.fr/s?k=\(isbn)&__mk_fr_FR=ÅMÅŽÕÑ&ref=nb_sb_noss".getCleanedURL()!
    let dataTask = URLSession.shared.dataTask(with: dataURL){data, res, error in
        guard let data = data, error == nil else{completion(nil); return}
        let string = String(data: data, encoding: .utf8)
        let crange = string?.range(of: "a-section aok-relative s-image-fixed-height")
        guard crange != nil else {completion(nil); return}
        let cstart = string?.index(crange!.upperBound, offsetBy: 63)
        let cend = string?.index(crange!.upperBound, offsetBy: 500)
        let coverURL = string![cstart!..<cend!].split(separator: "\"").first
        completion(String(coverURL!))
    }
    dataTask.resume()
}

class QLGoogleAPIResolution{
    struct Response: Decodable{
        var kind: String
        var items: [Volume]
    }
    struct ImageLinks: Decodable{
        var thumbnail: String
    }
    struct Volume: Decodable{
        var volumeInfo: Book
    }
}

class QLOpenLibraryAPIResolution{
    struct Response: Decodable{
        var title: String
        var authors: [Author]
    }
    struct Author: Decodable{
        var name: String
    }
}
