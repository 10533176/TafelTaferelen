//
//  SettingsViewController.swift
//  Tafel Taferelen
//
//  Created by Femke van Son on 19-01-17.
//  Copyright © 2017 Femke van Son. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageProfPic: UIImageView!
    var ref: FIRDatabaseReference!
    let picker = UIImagePickerController()
    var userStorage: FIRStorageReference!
    let userID = FIRAuth.auth()?.currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        let storage = FIRStorage.storage().reference(forURL: "gs://tafel-taferelen.appspot.com")
        userStorage = storage.child("users")
        picker.delegate = self
        displayCurrentProfilePicture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displayCurrentProfilePicture() {
        
        ref?.child("users").child(userID!).child("urlToImage").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let urlImage = snapshot.value as! String
            
            if let url = NSURL(string: urlImage) {
                
                if let data = NSData(contentsOf: url as URL) {
                    self.imageProfPic.image = UIImage(data: data as Data)
                }
            }
            
        })
        
        self.imageProfPic.layer.cornerRadius = self.imageProfPic.frame.size.width / 2
        self.imageProfPic.clipsToBounds = true
    }
    
    @IBAction func changeProfPic(_ sender: Any) {
        
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        
        present(picker, animated: true, completion: nil)
        
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {

            self.imageProfPic.image = image
            saveImage()

        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func saveImage() {

        let userID = FIRAuth.auth()?.currentUser?.uid
        let changeRequest = FIRAuth.auth()!.currentUser!.profileChangeRequest()

        changeRequest.commitChanges(completion: nil)
        
        let imageRef = self.userStorage.child("\(userID).jpg")
        let data = UIImageJPEGRepresentation(self.imageProfPic.image!, 0.5)
        
        let uploadTask = imageRef.put(data!, metadata: nil, completion: { (metadata, err) in
            if err != nil {
                self.signupErrorAlert(title: "Oops!", message: err!.localizedDescription)
                
            }
            
            imageRef.downloadURL(completion: {(url, er) in
                if er != nil {
                    self.signupErrorAlert(title: "Oops!", message: er!.localizedDescription)
                }
                
                if let url = url {
                    self.getImageURL(newURL: url.absoluteString)
                }
            })
        })
        
        uploadTask.resume()
    }
    
    func getImageURL(newURL: String) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        self.ref?.child("users").child(userID!).child("urlToImage").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let urlImage = snapshot.value as? String
            
            if urlImage != nil {
                self.changeProfileTable(url: urlImage!, newURL: newURL)
            }
        })
        
    }
    
    func changeProfileTable(url: String, newURL: String) {
        
        self.ref.child("users").child(userID!).child("urlToImage").setValue(newURL)
        
        self.ref?.child("users").child(userID!).child("groupID").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let groupID = snapshot.value as? String
            
            if groupID != nil {
                
                self.ref?.child("groups").child(groupID!).child("tableSetting").observeSingleEvent(of: .value, with: { (snapshot) in
            
                    var table = snapshot.value as? [String]
                    var index = 0
                    if table != nil {
                        for key in table! {
                            if key == url {
                                table?[index] = newURL
                                self.ref?.child("groups").child(groupID!).child("tableSetting").setValue(table)
                            }
                            index = index + 1
                        }
                    }
                })
            }
        })
    }
    
    @IBAction func loggingOUT(_ sender: Any) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            present( UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "logIn") as UIViewController, animated: true, completion: nil)
        
        } catch {
            self.signupErrorAlert(title: "Oops!", message: "Something went wrong while logging out. Try again later.")
        }
        
    }
    
}
