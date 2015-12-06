//
//  DayTableViewController.swift
//  Adafruit Bluefruit LE Connect
//
//  Created by Kimberly Zai on 11/30/15.
//  Copyright © 2015 Adafruit Industries. All rights reserved.
//

import UIKit
import CVCalendar

class DayTableViewController: UITableViewController {
    
    var dayTitle : String?
    var startPeriodChecked : Bool?
    var endPeriodChecked : Bool?
    var selectedDay : DayView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = selectedDay!.date.commonDescription
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        //self.navigationItem.title
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        startPeriodChecked = selectedDay!.startPeriod
        endPeriodChecked = selectedDay!.endPeriod
        
        print(startPeriodChecked!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func done(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        
        
        if selectedCell?.reuseIdentifier == "StartPeriod" {
            // if the End Period cell has not already been checked, the Start Period cell can be checked
            if !endPeriodChecked! {
                startPeriodChecked = !startPeriodChecked!
                selectedDay!.startPeriod = startPeriodChecked!
                toggleCellSelection(selectedCell!)
            }
            
        } else {
            // if the Start Period cell has not already been checked, the End Period cell can be checked
            if !startPeriodChecked! {
                endPeriodChecked = !endPeriodChecked!
                selectedDay!.endPeriod = endPeriodChecked!
                toggleCellSelection(selectedCell!)
            }

        }
    }
    
    func toggleCellSelection(cell: UITableViewCell) {
        if cell.accessoryType == .Checkmark {
            cell.accessoryType = .None
        } else {
            cell.accessoryType = .Checkmark
        }
    }

    // MARK: - Table view data source
/*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    } */

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        var cell : UITableViewCell?
        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("StartPeriodIdentifier", forIndexPath: indexPath)
            
            if startPeriodChecked! {
                toggleCellSelection(cell!)
            }
            
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("EndPeriodIdentifier", forIndexPath: indexPath)
            
            if endPeriodChecked! {
                toggleCellSelection(cell!)
            }
        }
        return cell!
    } */
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
