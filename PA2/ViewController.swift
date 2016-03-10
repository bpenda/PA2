//
//  ViewController.swift
//  runomatic
//
//  Created by Vasil Pendavinji on 2/1/16.
//  Copyright © 2016 Vasil Pendavinji. All rights reserved.
//
import Foundation
import UIKit
import CoreMotion
import CoreLocation
import AVFoundation


import MessageUI
var motionManager: CMMotionManager!


class ViewController: UIViewController, MFMailComposeViewControllerDelegate{
    let pi = M_PI
    let me = self
    let accel_scale = 9.81
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var stillImageOutput : AVCaptureStillImageOutput? = AVCaptureStillImageOutput()
    var lm:CLLocationManager!
    //All the labels
    @IBOutlet var time:UILabel!
    @IBOutlet var xal:UILabel!
    @IBOutlet var yal:UILabel!
    @IBOutlet var zal:UILabel!
    @IBOutlet var xrl:UILabel!
    @IBOutlet var yrl:UILabel!
    @IBOutlet var zrl:UILabel!
    @IBOutlet var xml:UILabel!
    @IBOutlet var yml:UILabel!
    @IBOutlet var zml:UILabel!
    @IBOutlet var rattl:UILabel!
    @IBOutlet var pattl:UILabel!
    @IBOutlet var yattl:UILabel!
    @IBOutlet var stepl:UILabel!
    @IBOutlet var anglel:UILabel!
    @IBOutlet var distl:UILabel!
    @IBOutlet var Button: UIButton!
    
    var startTime:NSDate = NSDate()
    var elapsedTime:NSTimeInterval = 0.0
    var xa:Double = 0,ya:Double = 0,za:Double = 0
    var xr:Double = 0,yr:Double = 0,zr:Double = 0
    var xm:Double = 0,ym:Double = 0,zm:Double = 0
    var ratt:Double = 0,patt:Double = 0,yatt:Double = 0
    var compassHeading:Double = 0;
    
    var totalAngle:Double = 0
    var lastAngle:Double = 0
    
    var pathX:String = "";
    var mess:String = "";
    var start:Bool = false;
    var angleBuf = [Double]()
    
    let Xn = 0.0, Yn = 0.0, Zn = -9.81
    
    var steps = 0
    let stepTol = 1.3
    let walkDist = 20.0
    
    enum GraphState {
        case above, below, zero
    }
    var Zstate:GraphState = GraphState.above
    var Rstate:GraphState = GraphState.above

    
    override func viewDidLoad() {
        super.viewDidLoad()
        lm = CLLocationManager()
        
        lm.startUpdatingHeading()
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryZVertical)
        motionManager.startGyroUpdates()
        motionManager.startMagnetometerUpdates()
        
      /*  if motionManager.deviceMotionAvailable {
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
                
                // translate the attitude
                data.attitude.multiplyByInverseOfAttitude(initialAttitude)
                
                // calculate magnitude of the change from our initial attitude
                let magnitude = magnitudeFromAttitude(data.attitude) ?? 0
                
                // show the prompt
                if !showingPrompt && magnitude > showPromptTrigger {
                    if let promptViewController = self?.storyboard?.instantiateViewControllerWithIdentifier("PromptViewController") as? PromptViewController {
                        showingPrompt = true
                        
                        promptViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
                        self!.presentViewController(promptViewController, animated: true, completion: nil)
                    }
                }
                
                // hide the prompt
                if showingPrompt && magnitude < showAnswerTrigger {
                    showingPrompt = false
                    self?.dismissViewControllerAnimated(true, completion: nil)
                }
            
        }*/
            /*if motionManager.deviceMotionAvailable {
                motionManager.deviceMotionUpdateInterval = 100
                motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue(), ) {
                    (data: CMDeviceMotion?, error: NSError?) in
                    self.ratt = data!.attitude.yaw
                }
                
        }*/
        _ = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("getReadings"), userInfo: nil, repeats: true)
        _ = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("writeReadings"), userInfo: nil, repeats: true)
        
        startTime = NSDate()
        time.text = "hi ben"
        self.xal.text = "x"
        self.yal.text = "y"
        self.zal.text = "z"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateRotation(){
        print("updateing as ;ldfja")
    }
    

    
    func countSteps(){
            if ((Zstate == .above) && (za < (Zn - stepTol))){
                Zstate = .below
            }
            if ((Zstate == .below) && (za > (Zn + stepTol))){
                Zstate = .above
                steps++
                
            }
        
    }
    
    func countRotation(){
        if(Rstate == .above && abs(zr) > 50){
            Rstate = .below
            lastAngle = abs(yatt)
        }
        if(Rstate == .below && abs(zr) < 5){
            //totalAngle += (Double(Int(abs(angleBuf[0] - abs(yatt)))/5)+1)*5
            var dif = abs(lastAngle - abs(yatt))
            if(dif > 180){
                dif = 360 - dif
            }
            totalAngle += dif
            Rstate = .above
        }
    }
    
    func getReadings(){
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            if let accelerometerData = motionManager.accelerometerData {
                self.xa = accelerometerData.acceleration.x * self.accel_scale
                self.ya = accelerometerData.acceleration.y * self.accel_scale
                self.za = accelerometerData.acceleration.z * self.accel_scale
                self.elapsedTime = NSDate().timeIntervalSinceDate(self.startTime)
                self.countSteps()
            }
            if let gyroData = motionManager.gyroData {
                self.xr = gyroData.rotationRate.x*180/self.pi
                self.yr = gyroData.rotationRate.y*180/self.pi
                self.zr = gyroData.rotationRate.z*180/self.pi
                
            }
            if let magData = motionManager.magnetometerData {
                self.xm = magData.magneticField.x
                self.ym = magData.magneticField.y
                self.zm = magData.magneticField.z
                
            }
            if let heading = self.lm.heading?.magneticHeading{
                self.compassHeading = Double(heading)
                print(self.compassHeading)
            }
            if let heading = self.lm.heading?.magneticHeading{
                self.compassHeading = Double(heading)
            }

            
            
            if let attData = motionManager.deviceMotion?.attitude {
                self.ratt = attData.roll
                self.patt = attData.pitch
                self.yatt = attData.yaw*180/self.pi
                if(self.yatt < 0){
                    self.yatt = 360 + self.yatt
                }
                
                self.countRotation()
            }
            dispatch_async(dispatch_get_main_queue()) {
                //update accelerometer labels
                self.xal.text = String(format: "%.2f", self.xa)
                self.yal.text = String(format: "%.2f", self.ya)
                self.zal.text = String(format: "%.2f", self.za)
                //update gyro labels
                self.xrl.text = String(format: "%.2f", self.xr)
                self.yrl.text = String(format: "%.2f", self.yr)
                self.zrl.text = String(format: "%.2f", self.zr)
                //update mag labels
                self.xml.text = String(format: "%.2f", self.xm)
                self.yml.text = String(format: "%.2f", self.ym)
                self.zml.text = String(format: "%.2f", self.zm)
                
                self.rattl.text = String(format: "%.2f", self.ratt)
                self.pattl.text = String(format: "%.2f", self.patt)
                self.yattl.text = String(format: "%.2f", self.yatt)
                
                self.anglel.text = String(format: "%.2f", self.totalAngle)

                //update time label and step-count label
                self.time.text = String(self.elapsedTime)
                self.stepl.text = String(self.steps)
                self.distl.text = String(format: "%d inches", self.steps*18)
            }
        }
    }
    
    func writeReadings(){
        if (start){
            print("writing file")
            self.writeToFile("readings.csv")
        }
    }
    
    func writeToFile(file: String){
        mess =  self.time.text! + ", " + self.xal.text! + ", " + self.yal.text! + ", " + self.zal.text! + ", " + self.xrl.text! + ", " + self.yrl.text! + ", " + self.zrl.text! + ", " + self.xml.text! + ", " + self.yml.text! + ", " + self.zml.text! + ", " + String(self.compassHeading) + ", " + self.yattl.text! + ", " + self.anglel.text! + "\n"
        if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
            let path = dir.stringByAppendingPathComponent(file);
            pathX = path;
            if let outputStream = NSOutputStream(toFileAtPath: path, append: true) {
                outputStream.open()
                outputStream.write(mess, maxLength: mess.characters.count)
                outputStream.close()
            } else {
                print("Write to file failed")
            }
            
        }
        
    }
    
    func readFromFile(){
        let file = "data.asc"
        if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
            let path = dir.stringByAppendingPathComponent(file);
            do {let read = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)}
            catch {print("Read from file failed")}
        }
    }
    
    
    @IBAction func sendEmail(sender: UIButton) {
        if (!start){
            start = true
            startTime = NSDate()
        }else{
            start = false
            if( MFMailComposeViewController.canSendMail() ) {
                print("Able to send")
                let mailComposer = MFMailComposeViewController()
                mailComposer.mailComposeDelegate = self
                mailComposer.setSubject("Booty")
                mailComposer.setMessageBody("YAY", isHTML: false)
                let fileManager = NSFileManager.defaultManager()
                    if let fileData = NSData(contentsOfFile: pathX) {
                        print("File data loaded.")
                        mailComposer.addAttachmentData(fileData, mimeType: "text/csv", fileName: "readings.csv")
                        do {
                            try fileManager.removeItemAtPath(pathX)
                            print("Deleted")
                        }
                        catch let error as NSError {
                            print("Ooops")
                        }
                    }else{
                        print("File data is NOT loaded.")
                    }
                self.presentViewController(mailComposer, animated: true, completion: nil)
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
}

