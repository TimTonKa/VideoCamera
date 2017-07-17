//
//  SimpleVideoCamController.swift
//  SimpleVideoCam
//
//  Created by Tim on 17/07/2017.

import UIKit
import AVFoundation
import AVKit
import MediaPlayer

class SimpleVideoCamController: UIViewController, AVCaptureFileOutputRecordingDelegate {

    @IBOutlet var cameraButton:UIButton!
    
    let captureSession = AVCaptureSession()
    var currentDevice: AVCaptureDevice?
    var videoFileOutput: AVCaptureMovieFileOutput?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var timer: Timer!
    var isRecording = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        /* 設置全解析度來照相,High表示以高品質輸出
         * AVCaptureSessionPresetMedium
         * AVCaptureSessionPresetLow
         */
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        //取得預設相機
        if #available(iOS 10.0, *) {
            if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .front)/*position: .back*/ {
                
                //iPhone7 plus 內建雙鏡頭，針對雙鏡頭相機就使用builtInDuoCamera
                currentDevice = device
            } else if let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
                //單一個鏡頭裝置
                currentDevice = device
            }
        } else {
            // Fallback on earlier versions
            let devices = AVCaptureDevice.devices().filter{ ($0 as AnyObject).hasMediaType(AVMediaTypeVideo) && ($0 as AnyObject).position == AVCaptureDevicePosition.front }
            if let captureDevice = devices.first as? AVCaptureDevice {
                currentDevice = captureDevice
            }
            
        }
        
        //取得輸入資料源
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else {
            return
        }
        
        /* 設置輸出的session來擷取影片->用來將資料儲存至QuickTime影片檔
         * maxRecordeDuration 設定最長錄製時間
         */
        videoFileOutput = AVCaptureMovieFileOutput()
        let preferredTimeScale: Int32 = 1
        videoFileOutput?.maxRecordedDuration = CMTime(seconds: 6.2, preferredTimescale: preferredTimeScale)
        
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(videoFileOutput)
        
        //提供相機預覽
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame
        
        //將相機按鈕帶到前面
        view.bringSubview(toFront: cameraButton)
        captureSession.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Action methods
    
    @IBAction func unwindToCamera(segue:UIStoryboardSegue) {
        
    }
    
    @IBAction func capture(sender: AnyObject) {
        if !isRecording {
            isRecording = true
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: { () -> Void in
                self.cameraButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }, completion: nil)
            
            let outputPath = NSTemporaryDirectory() + "output.mp4"
            let outputFileURL = URL(fileURLWithPath: outputPath)
            videoFileOutput?.startRecording(toOutputFileURL: outputFileURL, recordingDelegate: self)
            
            
            if timer == nil {
                
                if #available(iOS 10.0, *) {
                    timer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false, block: { (timer) in
                        self.capture(sender: "" as AnyObject)
                    })
                } else {
                    timer = Timer.scheduledTimer(timeInterval: 6.0,
                                                 target: self,
                                                 selector: #selector(capture(sender:)),
                                                 userInfo: nil,
                                                 repeats: false)
                }
            }
            
        } else {
            isRecording = false
            
            UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: { () -> Void in
                self.cameraButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: nil)
            
            cameraButton.layer.removeAllAnimations()
            videoFileOutput?.stopRecording()
            
            timer?.invalidate()
            timer = nil
        }
    }
    
    //MARK: AVCaptureFileOutputRecordingDelegate
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        if error != nil {
            //print(error)
            let alertController = UIAlertController(title: "System message", message: "影片長度不能超過6秒喔", preferredStyle: UIAlertControllerStyle.alert)
            let alertAction = UIAlertAction(title: "ok", style: UIAlertActionStyle.cancel, handler: { (alertAction) in
                self.isRecording = false
                
                UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: { () -> Void in
                    self.cameraButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }, completion: nil)
                
                self.cameraButton.layer.removeAllAnimations()
                self.videoFileOutput?.stopRecording()
            })
            alertController.addAction(alertAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        performSegue(withIdentifier: "playVideo", sender: outputFileURL)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playVideo" {
            let videoPlayerViewController = segue.destination as! AVPlayerViewController
            let videoFileURL = sender as! URL
            videoPlayerViewController.player = AVPlayer(url: videoFileURL)
        }
    }

}
