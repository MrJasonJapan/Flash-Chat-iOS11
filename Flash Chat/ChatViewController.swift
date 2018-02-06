//
//  ViewController.swift
//  Flash Chat
//
//  Created by Angela Yu on 29/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    // Declare instance variables here
    var messageArray: [Message] = [Message]()
    
    // We've pre-linked the IBOutlets
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var messageTextfield: UITextField!
    @IBOutlet var messageTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set yourself as the delegate and datasource here:
        messageTableView.delegate = self
        messageTableView.dataSource = self
        
        //Set yourself as the delegate of the text field here:
        messageTextfield.delegate = self
        
        //Set the tapGesture here:
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        messageTableView.addGestureRecognizer(tapGesture)
        

        //Register your MessageCell.xib file here:
        messageTableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")
        
        // apply our "default" table characteristics.
        configureTableView()
        
        // retrieve our messages
        retrieveMessages()
        
        messageTableView.separatorStyle = .none
    }

    ///////////////////////////////////////////
    
    //MARK: - TableView DataSource Methods

    //Declare cellForRowAtIndexPath here:
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
        
        cell.messageBody.text = messageArray[indexPath.row].messageBody
        cell.senderUsername.text = messageArray[indexPath.row].sender
        cell.avatarImageView.image = UIImage(named: "egg")
        
        if cell.senderUsername.text == Auth.auth().currentUser?.email as String! {
            // Messages we sent
            cell.avatarImageView.backgroundColor = UIColor.flatMint()
            cell.messageBackground.backgroundColor = UIColor.flatSkyBlue()
        } else {
            cell.avatarImageView.backgroundColor = UIColor.flatWatermelon()
            cell.messageBackground.backgroundColor = UIColor.flatGray()
        }
        
        return cell
    }

    //Declare numberOfRowsInSection here:
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return messageArray.count
    }
    
    //Declare tableViewTapped here:
    @objc func tableViewTapped() {
        // textFieldDidEndEditing gets triggered here.
        messageTextfield.endEditing(true)
    }

    // Declare configureTableView here: -> declare the "default" properties for our table.
    func configureTableView() {
        messageTableView.rowHeight = UITableViewAutomaticDimension
        messageTableView.estimatedRowHeight = 120.0
    }
    
    
    ///////////////////////////////////////////
    
    //MARK:- TextField Delegate Methods (Optional)
    
    //Declare textFieldDidBeginEditing here:
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        UIView.animate(withDuration: 0.5){
            self.heightConstraint.constant = 308
            self.view.layoutIfNeeded()
        }
    }
    
    //Declare textFieldDidEndEditing here: (this method is triggerd by our code)
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        UIView.animate(withDuration: 0.5) {
            self.heightConstraint.constant = 50
            self.view.layoutIfNeeded()
        }
        
    }

    
    ///////////////////////////////////////////
    //MARK: - Send & Recieve from Firebase
    
    //Send the message to Firebase and save it in our database
    @IBAction func sendPressed(_ sender: AnyObject) {
        messageTextfield.endEditing(true)
        
        //Disable the messageText field and the send button temporarily so we can prevent "double sending."
        messageTextfield.isEnabled = false
        sendButton.isEnabled = false
        
        // create a DB strictly for message (inside are firebase)
        let messagesDB = Database.database().reference().child("Messages")
        
        let messageDictionary = ["Sender": Auth.auth().currentUser?.email,
                                 "MessageBody": messageTextfield.text!]
        
        // save our messageDicionary into our DB under an automatically generated auto ID.
        messagesDB.childByAutoId().setValue(messageDictionary) {
            (error, reference) in
            
            if error != nil {
                print(error!)
            }
            else{
                print("Message saved successfully!")
                self.messageTextfield.isEnabled = true
                self.sendButton.isEnabled = true
                
                // reset the text field
                self.messageTextfield.text = ""
            }
        }
    }
    
    //Create the retrieveMessages method here:
    func retrieveMessages() {
        
        // create a reference to our database.
        let messageDB = Database.database().reference().child("Messages")
        
        // this is sort of like @@identity on SqlServer in a sense that we can see what was "just" inserted.
        // But it also seems to act like an event that triggers for already existing rows in the DB,
        // So that when the app is started we can tranfer the existing database entries to our messageArray.
        // The Documentation says this: child added is triggered once for each existing child
        // and then again every time a new child is added to the specified path.
        messageDB.observe(.childAdded, with: { (snapshot) in
            let snapshotValue = snapshot.value as! Dictionary<String, String>
            
            let text = snapshotValue["MessageBody"]!
            let sender = snapshotValue["Sender"]!
            
            // create a model object, and add it to our messageArray
            let insertedMessage = Message()
            insertedMessage.messageBody = text
            insertedMessage.sender = sender
            self.messageArray.append(insertedMessage)
            
            // reformat the table view so it can show the message properly.
            self.configureTableView()
            self.messageTableView.reloadData() // reload the data
        })
    }
    
    
    @IBAction func logOutPressed(_ sender: AnyObject) {
        
        //Log out the user and send them back to WelcomeViewController
        do {
            try Auth.auth().signOut()
            
            // navigate to the root of the navigation stack.
            navigationController?.popToRootViewController(animated: true)
        }
        catch {
            print("error, there was a problem. signing out.")
        }
    }
    


}
