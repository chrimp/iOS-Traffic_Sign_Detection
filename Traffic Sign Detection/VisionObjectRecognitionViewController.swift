/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the object recognition view controller for the Breakfast Finder.
*/

import UIKit
import AVFoundation
import Vision
import os

class VisionObjectRecognitionViewController: ViewController {
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    private var requests_1 = [VNRequest]()
    private var requests_2 = [VNRequest]()
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "temp-final", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        guard let modelURL_1 = Bundle.main.url(forResource: "tfsigndetection_newset", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        guard let modelURL_2 = Bundle.main.url(forResource: "temp_final1", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        print("Model Called")
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let visionModel_1 = try VNCoreMLModel(for: MLModel(contentsOf: modelURL_1))
            let visionModel_2 = try VNCoreMLModel(for: MLModel(contentsOf: modelURL_2))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.drawVisionRequestResults(results, coordinate: nil)
                    }
                })
            })
            let objectRecognition_1 = VNCoreMLRequest(model: visionModel_1, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    if let results = request.results {
                        self.drawVisionRequestResults(results, coordinate: 1)
                    }
                })
                
            })
            let objectRecognition_2 = VNCoreMLRequest(model: visionModel_2, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    if let results = request.results {
                        self.drawVisionRequestResults(results, coordinate: 2)
                    }
                })
            })
            self.requests = [objectRecognition]
            self.requests_1 = [objectRecognition_1]
            self.requests_2 = [objectRecognition_2]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any], coordinate: Int?) {
        
        var shapeLayer: CALayer? = nil
        var textLayer: CATextLayer? = nil
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let obstr = "\(objectBounds)" // from here
            
            let sizearr = obstr.components(separatedBy: ",")
            let xSizearr = sizearr[2].components(separatedBy: ".")
            let ySizearr = sizearr[3].components(separatedBy: ".")
            let xSizestr = xSizearr[0].components(separatedBy: .whitespacesAndNewlines).joined()
            let ySizestr = ySizearr[0].components(separatedBy: .whitespacesAndNewlines).joined()
            let xSize = Int(xSizestr)!
            let ySize = Int(ySizestr)!
            //print(xSize, ySize)
            //let ms : UInt32 = 1000
            //usleep(10 * ms)
            
            if coordinate == 1 {
                shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds, coord: coordinate)
                textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                                identifier: topLabelObservation.identifier,
                                                                confidence: topLabelObservation.confidence,
                                                                coord: 1)
                shapeLayer!.addSublayer(textLayer!)
                detectionOverlay.addSublayer(shapeLayer!)
            } else if coordinate == 2 && xSize <= 100 && ySize <= 650 {
                shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds, coord: coordinate)
                textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                                identifier: topLabelObservation.identifier,
                                                                confidence: topLabelObservation.confidence,
                                                                coord: 2)
                shapeLayer!.addSublayer(textLayer!)
                detectionOverlay.addSublayer(shapeLayer!)
            } else if xSize <= 1100 && ySize <= 650 {
                shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds,coord: coordinate)
                textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                                identifier: topLabelObservation.identifier,
                                                                confidence: topLabelObservation.confidence,
                                                                coord: coordinate)
                shapeLayer!.addSublayer(textLayer!)
                detectionOverlay.addSublayer(shapeLayer!)
            }
            
            
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
            try imageRequestHandler.perform(self.requests_1)
            try imageRequestHandler.perform(self.requests_2)
        } catch {
            //withUnsafePointer(to: error, { pointer -> Void in
                //print(pointer)
            //})
            //fatalError(error.localizedDescription)
            print(error)
        }
    }
    
        
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence, coord: Int?) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        printRecogOBJ(id: identifier, coord: coord)
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect, coord: Int?) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        if coord == 1 {
            shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.01, 0.84, 0.99, 0.4])
        }
        else if coord == 2{
            shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.01, 0.99, 0.54, 0.4])
        }
        else {
            shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        }
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
    func readModelOutput(_ identifier: String) {
        
    }

    func printRecogOBJ (id: String, coord: Int?) {
        if coord == 1 {
            if id == "Right" { os_log("Right_1") }
            if id == "Left" { os_log("Left_1") }
        }
        else if coord == 2{
            if id == "Right" { os_log("Right_2") }
            if id == "Left" { os_log("Left_2") }
        }
        else {
            if id == "Right" { os_log("Right") }
            if id == "Left" { os_log("Left") }
        }
    }
    
}
