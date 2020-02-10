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
    @IBOutlet weak var shutterButton: UIButton!
    
    var captureSession = AVCaptureSession()
    var photoOutputObj = AVCapturePhotoOutput()
    let notification = NotificationCenter.default
    
    var authStatus: AuthorizedStatus = .authorized
    var inOutStatus: InputOutputStatus = .ready
    
    enum AuthorizedStatus {
        case authorized
        case notAuthorized
        case failed
    }
    
    enum InputOutputStatus {
        case ready
        case notReady
        case failed
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !captureSession.isRunning else {
            return
        }
        
        cameraAuth()
        setupInputOutput()
        
        if authStatus == .authorized && inOutStatus == .ready {
            setPreviewLayer()
            captureSession.startRunning()
            shutterButton.isEnabled = true
            
        } else {
            showAlert(appName: "カメラ")
        }
        
        notification.addObserver(
            self,
            selector: #selector(self.changedDeviceOrientation(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
    }
    
    func cameraAuth() {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (authorized) in
                if authorized {
                    self.authStatus = .authorized
                } else {
                    self.authStatus = .notAuthorized
                }
            })
            
        case .restricted:
            authStatus = .notAuthorized
            
        case .denied:
            authStatus = .notAuthorized
            
        case .authorized:
            authStatus = .authorized
            
        default:
            break
        }
    }
    
    func setupInputOutput() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        guard let device = AVCaptureDevice.default(
            AVCaptureDevice.DeviceType.builtInWideAngleCamera,
            for: AVMediaType.video,
            position: AVCaptureDevice.Position.back) else {
                print("デバイスを取得できなかった")
                return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("セッションに入力を追加できなかった")
                return
            }
        } catch let error as NSError {
            print("カメラがない \(error)")
            return
        }
        
        if captureSession.canAddOutput(photoOutputObj) {
            captureSession.addOutput(photoOutputObj)
        } else {
            print("セッションに出力を追加できなかった")
            return
        }
    }
    
    func setPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        previewLayer.frame = view.bounds
        previewLayer.masksToBounds = true
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        
        previewView.layer.addSublayer(previewLayer)
    }
    
    func showAlert(appName: String) {
        let alertTitle = appName + "のプライバシー認証"
        let alertMessage = "設定＞プライバシー＞" + appName + "で利用を許可してください。"
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil)
        )
        
        alertController.addAction(
            UIAlertAction(title: "設定を開く", style: .default, handler: { (action) in
                UIApplication.shared.open(
                    URL(string: UIApplication.openSettingsURLString)!,
                    options: [:],
                    completionHandler: nil)
            })
        )
        
        self.present(alertController, animated: false, completion: nil)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        if authStatus == .authorized && inOutStatus == .ready {
            var photoSettings = AVCapturePhotoSettings()
            
            if photoOutputObj.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            photoSettings.flashMode = .auto
            photoSettings.isDepthDataDeliveryEnabled = false
            photoSettings.isHighResolutionPhotoEnabled = false
            
            photoOutputObj.capturePhoto(with: photoSettings, delegate: self)
        } else {
            showAlert(appName: "カメラ")
        }
    }
    
    @objc func changedDeviceOrientation(_ notification: Notification) {
        if let photoOutputConnection = self.photoOutputObj.connection(with: AVMediaType.video) {
            switch UIDevice.current.orientation {
            case .portrait:
                print("portrait")
                photoOutputConnection.videoOrientation = .portrait
            case .portraitUpsideDown:
                print("portraitUpsideDown")
                photoOutputConnection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                print("landscapeLeft")
                photoOutputConnection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                print("landscapeRight")
                photoOutputConnection.videoOrientation = .landscapeRight
            default:
                print("default")
                break;
            }
        } else {
            print("Cannot get photo output connection")
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
