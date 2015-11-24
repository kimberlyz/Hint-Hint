//
//  CalendarViewController.swift
//  Adafruit Bluefruit LE Connect
//
//  Created by Kimberly Zai on 11/19/15.
//  Copyright © 2015 Adafruit Industries. All rights reserved.
//

import UIKit
import CVCalendar
import CoreBluetooth
import Foundation

protocol MainViewControllerDelegate : Any {
    func onDeviceConnectionChange(peripheral:CBPeripheral)
}


class MainViewController: UIViewController, MainViewControllerDelegate {

    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var monthLabel: UILabel!
    
    var shouldShowDaysOut = true
    var animationFinished = true
    
    var selectedDay:DayView!
    
    
    enum ConnectionStatus:Int {
        case Idle = 0
        case Scanning
        case Connected
        case Connecting
    }
    
    var connectionMode:ConnectionMode = ConnectionMode.None
    var connectionStatus:ConnectionStatus = ConnectionStatus.Idle
    var deviceListViewController:DeviceListViewController!
    var controllerViewController:ControllerViewController!
    var delegate:MainViewControllerDelegate?
    
    
    
    private var connectionTimer:NSTimer?
    private let cbcmQueue = dispatch_queue_create("com.adafruit.bluefruitconnect.cbcmqueue", DISPATCH_QUEUE_CONCURRENT)
    private var currentPeripheral:BLEPeripheral?
    private var currentAlertView:UIAlertController?
    private var cm:CBCentralManager?
    private var firmwareUpdater : FirmwareUpdater?
    
    func centralManager()->CBCentralManager{
        
        return cm!;
        
    }
    
    //for Objective-C delegate compatibility
    func setDelegate(newDelegate:AnyObject){
        
        if newDelegate.respondsToSelector(Selector("onDeviceConnectionChange:")){
            delegate = newDelegate as? MainViewControllerDelegate
        }
        else {
            printLog(self, funcName: "setDelegate", logString: "failed to set delegate")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        monthLabel.text = CVDate(date: NSDate()).globalDescription
        // Do any additional setup after loading the view.
        
        self.delegate = self
        
        // Create core bluetooth manager on launch
        if (cm == nil) {
            cm = CBCentralManager(delegate: self, queue: cbcmQueue)
            
            connectionMode = ConnectionMode.None
            connectionStatus = ConnectionStatus.Idle
            currentAlertView = nil
        }
        
        //refresh updates for DFU
        FirmwareUpdater.refreshSoftwareUpdatesDatabase()
        let areAutomaticFirmwareUpdatesEnabled = NSUserDefaults.standardUserDefaults().boolForKey("updatescheck_preference");
        if (areAutomaticFirmwareUpdatesEnabled) {
            firmwareUpdater = FirmwareUpdater()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.calendarView.commitCalendarViewUpdate()
        self.menuView.commitMenuViewUpdate()
    }
    
    // MARK: Optional methods
    
    func shouldShowWeekdaysOut() -> Bool {
        return shouldShowDaysOut
    }
    
    func shouldAnimateResizing() -> Bool {
        return true // Default value is true
    }
    
    func didSelectDayView(dayView: CVCalendarDayView, animationDidFinish: Bool) {
        print("\(dayView.date.commonDescription) is selected!")
        selectedDay = dayView
    }
    
    func presentedDateUpdated(date: CVDate) {
        if monthLabel.text != date.globalDescription && self.animationFinished {
            let updatedMonthLabel = UILabel()
            updatedMonthLabel.textColor = monthLabel.textColor
            updatedMonthLabel.font = monthLabel.font
            updatedMonthLabel.textAlignment = .Center
            updatedMonthLabel.text = date.globalDescription
            updatedMonthLabel.sizeToFit()
            updatedMonthLabel.alpha = 0
            updatedMonthLabel.center = self.monthLabel.center
            
            let offset = CGFloat(48)
            updatedMonthLabel.transform = CGAffineTransformMakeTranslation(0, offset)
            updatedMonthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
            
            UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.animationFinished = false
                self.monthLabel.transform = CGAffineTransformMakeTranslation(0, -offset)
                self.monthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
                self.monthLabel.alpha = 0
                
                updatedMonthLabel.alpha = 1
                updatedMonthLabel.transform = CGAffineTransformIdentity
                
                }) { _ in
                    
                    self.animationFinished = true
                    self.monthLabel.frame = updatedMonthLabel.frame
                    self.monthLabel.text = updatedMonthLabel.text
                    self.monthLabel.transform = CGAffineTransformIdentity
                    self.monthLabel.alpha = 1
                    updatedMonthLabel.removeFromSuperview()
            }
            
            self.view.insertSubview(updatedMonthLabel, aboveSubview: self.monthLabel)
        }
    }
    
    // MARK : Bluetooth Connection
    
    func abortConnection() {
        
        connectionTimer?.invalidate()
        
        if (cm != nil) && (currentPeripheral != nil) {
            cm!.cancelPeripheralConnection(currentPeripheral!.currentPeripheral)
        }
        
        currentPeripheral = nil
        
        connectionMode = ConnectionMode.None
        connectionStatus = ConnectionStatus.Idle
    }
    
    


}

extension MainViewController: CVCalendarViewDelegate, CVCalendarMenuViewDelegate {
    
    /// Required method to implement!
    func presentationMode() -> CalendarMode {
        return .MonthView
    }
    
    /// Required method to implement!
    func firstWeekday() -> Weekday {
        return .Sunday
    }
}

// MARK: - CVCalendarViewAppearanceDelegate

extension MainViewController: CVCalendarViewAppearanceDelegate {
    func dayLabelPresentWeekdayInitallyBold() -> Bool {
        return false
    }
    
    func spaceBetweenDayViews() -> CGFloat {
        return 2
    }
}

//MARK: CBCentralManagerDelegate methods

extension MainViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        if (central.state == CBCentralManagerState.PoweredOn){
            
            //respond to powered on
        }
            
        else if (central.state == CBCentralManagerState.PoweredOff){
            
            //respond to powered off
        }
        
    }
    
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        if connectionMode == ConnectionMode.None {
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                if self.deviceListViewController == nil {
                    self.createDeviceListViewController()
                }
                self.deviceListViewController.didFindPeripheral(peripheral, advertisementData: advertisementData, RSSI:RSSI)
            })
            

            
        }
    }
    
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        if (delegate != nil) {
            delegate!.onDeviceConnectionChange(peripheral)
        }
        
        //Connecting in DFU mode, discover specific services
        if connectionMode == ConnectionMode.DFU {
            peripheral.discoverServices([dfuServiceUUID(), deviceInformationServiceUUID()])
        }
        
        if currentPeripheral == nil {
            printLog(self, funcName: "didConnectPeripheral", logString: "No current peripheral found, unable to connect")
            return
        }
        
        
        if currentPeripheral!.currentPeripheral == peripheral {
            
            printLog(self, funcName: "didConnectPeripheral", logString: "\(peripheral.name)")
            
            //Discover Services for device
            if((peripheral.services) != nil){
                printLog(self, funcName: "didConnectPeripheral", logString: "Did connect to existing peripheral \(peripheral.name)")
                currentPeripheral!.peripheral(peripheral, didDiscoverServices: nil)  //already discovered services, DO NOT re-discover. Just pass along the peripheral.
            }
            else {
                currentPeripheral!.didConnect(connectionMode)
            }
            
        }
    }
    
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        //respond to disconnection
        
        if (delegate != nil) {
            delegate!.onDeviceConnectionChange(peripheral)
        }
        
        if connectionMode == ConnectionMode.DFU {
            connectionStatus = ConnectionStatus.Idle
            return
        }
        else if connectionMode == ConnectionMode.Controller {
            controllerViewController.showNavbar()
        }
        
        printLog(self, funcName: "didDisconnectPeripheral", logString: "")
        
        if currentPeripheral == nil {
            printLog(self, funcName: "didDisconnectPeripheral", logString: "No current peripheral found, unable to disconnect")
            return
        }
        
        //if we were in the process of scanning/connecting, dismiss alert
        if (currentAlertView != nil) {
            uartDidEncounterError("Peripheral disconnected")
        }
        
        //if status was connected, then disconnect was unexpected by the user, show alert
        if  connectionStatus == ConnectionStatus.Connected {
            
            printLog(self, funcName: "centralManager:didDisconnectPeripheral", logString: "unexpected disconnect while connected")
            
            //return to main view
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.respondToUnexpectedDisconnect()
            })
        }
            
            // Disconnected while connecting
        else if connectionStatus == ConnectionStatus.Connecting {
            
            abortConnection()
            
            printLog(self, funcName: "centralManager:didDisconnectPeripheral", logString: "unexpected disconnect while connecting")
            
            //return to main view
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.respondToUnexpectedDisconnect()
            })
            
        }
        
        connectionStatus = ConnectionStatus.Idle
        connectionMode = ConnectionMode.None
        currentPeripheral = nil
        
        // Dereference mode controllers
        dereferenceModeController()
        
    }
    
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        if (delegate != nil) {
            delegate!.onDeviceConnectionChange(peripheral)
        }
        
    }
    
    
    func respondToUnexpectedDisconnect() {
        
        //display disconnect alert
        let alert = UIAlertView(title:"Disconnected",
            message:"BlE device disconnected",
            delegate:self,
            cancelButtonTitle:"OK")
        
        let note = UILocalNotification()
        note.fireDate = NSDate().dateByAddingTimeInterval(0.0)
        note.alertBody = "BLE device disconnected"
        note.soundName =  UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(note)
        
        alert.show()
        
        
    }
    
    
    func dereferenceModeController() {
        
        uartViewController = nil
        deviceInfoViewController = nil
        controllerViewController = nil
    }
    

}
