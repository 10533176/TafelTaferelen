//
//  NewGroupViewController.swift
//  Tafel Taferelen
//
//  Created by Femke van Son on 16-01-17.
//  Copyright © 2017 Femke van Son. All rights reserved.
//

import UIKit
import Firebase

class NewGroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var groupsName: UITextField!
    @IBOutlet weak var newGroupMember: UITextField!
    @IBOutlet weak var createGroupBtn: UIButton!
    @IBOutlet weak var newGroupMemBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var ref: FIRDatabaseReference!
    var memberEmails = [String]()
    var memberIDs = [String]()
    var memberNames = [String]()
    var memberProfpic = [String]()
    var groupEmails = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.isTranslucent = true
        ref = FIRDatabase.database().reference()
        self.hideKeyboardWhenTappedAroung()
        
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Functions to find new member, check if he/ she is not allready in group, if not -> diplaying user information
    @IBAction func newGroupMemberAdded(_ sender: Any) {
        if newGroupMember.text != " " {
            if memberIDs.count < 11 {
                AppDelegate.instance().showActivityIndicator()
                findNewUser()
            } else {
               self.signupErrorAlert(title: "Oops!", message: "Maximum of ten members in group is reached")
            }
        } else {
            self.signupErrorAlert(title: "Oops!", message: "Fill in email adress to add new member to the group!")
        }
    }
    
    func doneLoading() {
        AppDelegate.instance().dismissActivityIndicator()
    }
    
    func findNewUser() {
        self.groupEmails = [""]
        self.ref?.child("emailDB").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let dictionary = snapshot.value as? NSDictionary
            
            if dictionary != nil {
                let tempKeys = dictionary?.allKeys as! [String]
                
                for keys in tempKeys {
                    
                    self.ref?.child("emailDB").child(keys).observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        let email = snapshot.value as! String
                        
                        self.groupEmails.append(email)

                        if self.groupEmails.count == tempKeys.count {
                            self.newUserNotFound()
                        }
                        if email == self.newGroupMember.text {
                            self.newUserFound(newUserID: keys)
                        }
                    })
                }
            }
        })
    }
    
    func newUserNotFound() {
        if self.groupEmails.contains(newGroupMember.text!) == false {
            self.doneLoading()
            self.signupErrorAlert(title: "Oops!", message: "We do not have any users with this e-mail address")
        }
    }
    
    func newUserFound(newUserID: String) {
        self.ref?.child("users").child(newUserID).child("groupID").observeSingleEvent(of: .value, with: {(snapshot) in
            
            let checkCurrentGroup = snapshot.value as? String
            
            if checkCurrentGroup == nil {
                self.findDataNewUser()
            }
            else {
                self.doneLoading()
                self.signupErrorAlert(title: "Oops, user allready in group!", message: "This member is already having dinner with other friends.. Try if someone else will have dinner with you!")
                self.newGroupMember.text = ""
            }
        })
    }
    
    func findDataNewUser() {
        
        self.ref?.child("emailDB").observeSingleEvent(of: .value, with: { (snapshot) in
            let dictionary = snapshot.value as? NSDictionary
            
            if dictionary != nil {
                let tempKeys = dictionary?.allKeys as! [String]
                
                for keys in tempKeys {
                    self.ref?.child("emailDB").child(keys).observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        let email = snapshot.value as! String
                        
                        if email == self.newGroupMember.text {
                            self.displayNewUser(newUserID: keys)
                        }
                    })
                }
            } else {
                self.doneLoading()
            }
        })
    }
    
    func displayNewUser(newUserID: String) {
        
            self.ref?.child("users").child(newUserID).child("full name").observeSingleEvent(of: .value, with: {(snapshot) in
                let name = snapshot.value as! String
                self.memberNames.append(name)
            })
            
            self.ref?.child("users").child(newUserID).child("urlToImage").observeSingleEvent(of: .value, with: {(snapshot) in
                let url = snapshot.value as! String
                self.memberProfpic.append(url)
                self.tableView.reloadData()
            })
            
            self.doneLoading()
            self.memberEmails.append(self.newGroupMember.text!)
            self.memberIDs.append(newUserID)
            self.newGroupMember.text = ""
    }
    
    @IBAction func createNewGroupPressed(_ sender: Any) {
        
        let groupID = self.ref?.child("groups").childByAutoId().key
        
        if groupsName.text != "" {
            self.ref?.child("groups").child(groupID!).child("name").setValue(groupsName.text)
            saveCurrentUserAsNewMember(groupID: groupID!)
            self.noGroupErrorAlert(title: "Yay!", message: "welcome to the club \(groupsName.text!)")
        }
        else {
            self.signupErrorAlert(title: "Oops!", message: "You forgot to fill in a groupsname")
        }
    }
    
    // MARK: Saving new users to DataBase
    func saveCurrentUserAsNewMember(groupID: String) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        self.ref?.child("users").child(userID!).child("email").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let emailCurrentUser = snapshot.value as! String
            self.memberEmails.append(emailCurrentUser)
            self.memberIDs.append(userID!)
            
            self.ref?.child("groups").child(groupID).child("members").child("email").setValue(self.memberEmails)
            self.ref?.child("groups").child(groupID).child("members").child("userid").setValue(self.memberIDs)
            let tableSetting = ["", "", "", "", "", "", "", "", "", ""]
            self.ref?.child("groups").child(groupID).child("tableSetting").setValue(tableSetting)
            
            for keys in self.memberIDs {
                self.ref?.child("users").child(keys).child("groupID").setValue(groupID)
            }
            
        })
    }

    // MARK: functions to show table view properly
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memberNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NewGroupTableViewCell
        cell.newGroupMemberDisplay.text = self.memberNames[indexPath.row]
        
        if let url = NSURL(string: self.memberProfpic[indexPath.row]) {
            
            if let data = NSData(contentsOf: url as URL) {
                cell.newGroupMemberProfPic.image = UIImage(data: data as Data)
            }
        }
        return cell
    }

}
