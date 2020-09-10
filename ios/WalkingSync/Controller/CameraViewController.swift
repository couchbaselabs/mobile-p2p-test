//
//  CameraViewController.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/7/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit
import AVFoundation

/// Delegate to handle when getting the URL from the QR Code Scanner
protocol CameraViewControllerDelegate {
    func didScanRemoteEndpointURL(url: URL)
}

/// Controller for the QR Code Scanner
class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var previewView: UIView!
    
    var previewLayer: AVCaptureVideoPreviewLayer!
       
    var session: AVCaptureSession!
    
    var delegate: CameraViewControllerDelegate?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if session == nil {
            startCaptureSession()
        }
    }
    
    // MARK: - Capture QR Code

    func startCaptureSession() {
        let device = AVCaptureDevice.default(for: .video)
        if device == nil {
            showMessage("No video capture devices found", title: "")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device!)
            session = AVCaptureSession()
            session.addInput(input)
            
            let output = AVCaptureMetadataOutput()
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            session.addOutput(output)
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

            previewLayer = AVCaptureVideoPreviewLayer(session: session)
                as AVCaptureVideoPreviewLayer
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer.frame = self.previewView.bounds
            self.previewView.layer.addSublayer(previewLayer)

            session.startRunning()
        } catch {
            showMessage("Cannot start QRCode capture session", title: "Error")
        }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        for metadata in metadataObjects {
            if metadata.type == AVMetadataObject.ObjectType.qr {
                let transformed = previewLayer.transformedMetadataObject(for: metadata)
                    as! AVMetadataMachineReadableCodeObject
                if let url = URL(string: transformed.stringValue!) {
                    if let delegate = self.delegate {
                        delegate.didScanRemoteEndpointURL(url: url)
                    }
                    session.stopRunning()
                    session = nil
                    break
                }
            }
        }
    }
    
}

