//
//  ScanViewController.swift
//  QuickLib
//
//  Created by Cyrus Pellet on 17/07/2020.
//

import UIKit
import AVFoundation
import JGProgressHUD

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var labelVFView: UIVisualEffectView!
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var barcodeFrameView: UIView?
    var previousScanResult: String = ""
    let HUD = JGProgressHUD(style: .light)

    override func viewDidLoad() {
        super.viewDidLoad()
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        guard let captureDevice = deviceDiscoverySession.devices.first else{print("Failed to get camera device"); return}
        do{
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
            barcodeFrameView = UIView()
            if let barcodeFrameView = barcodeFrameView{
                barcodeFrameView.layer.borderColor = UIColor.green.cgColor
                barcodeFrameView.layer.borderWidth = 2
                view.addSubview(barcodeFrameView)
            }
        }catch{print(error); return}
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = captureMetadataOutput.availableMetadataObjectTypes
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        captureSession.startRunning()
        view.bringSubviewToFront(barcodeFrameView!)
        view.bringSubviewToFront(labelVFView)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0{
            DispatchQueue.main.async {
                self.barcodeFrameView?.frame = CGRect.zero
            }
            return
        }
        if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject{
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            DispatchQueue.main.async {
                self.barcodeFrameView?.frame = barCodeObject!.bounds
            }
            if metadataObj.stringValue != nil{
                if metadataObj.stringValue != previousScanResult{
                    DispatchQueue.main.async{
                        self.HUD.textLabel.text = "Fetching data from ISBN..."
                        self.HUD.indicatorView = JGProgressHUDIndeterminateIndicatorView()
                        self.HUD.show(in: self.view)
                        self.labelVFView.isHidden = true
                    }
                    previousScanResult = metadataObj.stringValue!
                    resolveBookMetadata(isbn: metadataObj.stringValue!){res in
                        DispatchQueue.main.async {
                            if res != nil{
                                let vc = self.storyboard?.instantiateViewController(identifier: "addBookVC") as! AddBookViewController
                                vc.book = res
                                self.HUD.dismiss()
                                self.present(vc, animated: true)
                            }else{
                                DispatchQueue.main.async {
                                    self.HUD.textLabel.text = "Failed to retreive book data"
                                    self.HUD.indicatorView = JGProgressHUDErrorIndicatorView()
                                    self.HUD.dismiss(afterDelay: 2.0)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct Book: Decodable{
    var title: String
    var authors: [String]
    var imageLinks: QLGoogleAPIResolution.ImageLinks?
    var coverURL: String?
    var isbn: String?
    var location: String?
}

extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}
