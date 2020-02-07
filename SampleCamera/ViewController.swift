//
//  ViewController.swift
//  SampleCamera
//
//  Created by 濱田一輝 on 2020/02/05.
//  Copyright © 2020 Kazuki Hamada. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    
    var session = AVCaptureSession()
    var photoOutputObj = AVCapturePhotoOutput()
    let notification = NotificationCenter.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notification.addObserver(
            self,
            selector: #selector(self.changedDeviceOrientation(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
        
        if session.isRunning {
            return
        }
        
        setupInputOutput()
        setPreviewLayer()
        
        session.startRunning()
    }
    
    func setupInputOutput() {
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        do {
            let device = AVCaptureDevice.default(
                AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                for: AVMediaType.video,
                position: AVCaptureDevice.Position.back)
            
            let input = try AVCaptureDeviceInput(device: device!)
            
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                print("セッションに入力を追加できなかった")
                return
            }
        } catch let error as NSError {
            print("カメラがない \(error)")
            return
        }
        
        if session.canAddOutput(photoOutputObj) {
            session.addOutput(photoOutputObj)
        } else {
            print("セッションに出力を追加できなかった")
            return
        }
    }
    
    func setPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.frame = view.bounds
        previewLayer.masksToBounds = true
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        
        previewView.layer.addSublayer(previewLayer)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        let captureSetting = AVCapturePhotoSettings()
        
        captureSetting.flashMode = .auto
        captureSetting.isDepthDataDeliveryEnabled = true
        captureSetting.isHighResolutionPhotoEnabled = false
        
        photoOutputObj.capturePhoto(with: captureSetting, delegate: self)
    }
    
    @objc func changedDeviceOrientation(_ notification: Notification) {
        if let photoOutputConnection = self.photoOutputObj.connection(with: AVMediaType.video) {
            switch UIDevice.current.orientation {
            case .portrait:
                photoOutputConnection.videoOrientation = .portrait
            case .portraitUpsideDown:
                photoOutputConnection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                photoOutputConnection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                photoOutputConnection.videoOrientation = .landscapeRight
            default:
                break;
            }
        }
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        
        if let stillImage = UIImage(data: photoData) {
            UIImageWriteToSavedPhotosAlbum(stillImage, self, nil, nil)
        }
    }
}
