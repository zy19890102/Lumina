//
//  VideoDataOutputSampleBufferDelegate.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension LuminaCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = sampleBuffer.normalizedVideoFrame() else {
            return
        }
        let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        let metadata = NSDictionary(dictionary: metadataDict as! [AnyHashable : Any])
        let exifMetadata = (metadata.object(forKey: kCGImagePropertyExifDictionary as String) as! NSDictionary).mutableCopy() as! [String : Any]
        let brightnessValue = (exifMetadata[kCGImagePropertyExifBrightnessValue as String] as! NSNumber).floatValue
        if let modelPairs = self.streamingModels {
            LuminaLogger.notice(message: "valid CoreML models present - attempting to scan photo")
            if self.recognizer == nil {
                let newRecognizer = LuminaObjectRecognizer(modelPairs: modelPairs)
                self.recognizer = newRecognizer
            }
            guard let recognizer = self.recognizer as? LuminaObjectRecognizer else {
                LuminaLogger.error(message: "models loaded, but could not use object recognizer")
                DispatchQueue.main.async {
                    self.delegate?.videoFrameCaptured(camera: self, frame: image, brightnessValue: CGFloat(brightnessValue))
                }
                return
            }
            recognizer.recognize(from: image, completion: { results in
                DispatchQueue.main.async {
                    self.delegate?.videoFrameCaptured(camera: self, frame: image, predictedObjects: results)
                }
            })
        } else {
            DispatchQueue.main.async {
                
                self.delegate?.videoFrameCaptured(camera: self, frame: image, brightnessValue: CGFloat(brightnessValue))
            }
        }
    }
}
