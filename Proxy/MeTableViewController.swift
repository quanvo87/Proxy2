//
//  MeTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 10/24/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class MeTableViewController: UITableViewController {

    let api = API.sharedInstance
    let ref = Database.database().reference()

    var messagesReceivedRef = DatabaseReference()
    var messagesReceived = "-"

    var messagesSentRef = DatabaseReference()
    var messagesSent = "-"

    var proxiesInteractedWithRef = DatabaseReference()
    var proxiesInteractedWith = "-"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                self.navigationItem.title = user.displayName

//                self.messagesReceivedRef = self.ref.child(Child.MessagesReceived).child(self.api.uid).child(Child.MessagesReceived)
                self.messagesReceivedRef.observe(.value, with: { (data) in
                    if let messagesReceived = data.value as? Int {
                        self.messagesReceived = messagesReceived.asStringWithCommas
                        self.tableView.reloadData()
                    }
                })

//                self.messagesSentRef = self.ref.child(Child.MessagesSent).child(self.api.uid).child(Child.MessagesSent)
                self.messagesSentRef.observe(.value, with: { (data) in
                    if let messagesSent = data.value as? Int {
                        self.messagesSent = messagesSent.asStringWithCommas
                        self.tableView.reloadData()
                    }
                })

//                self.proxiesInteractedWithRef = self.ref.child(Child.ProxiesInteractedWith).child(self.api.uid).child(Child.ProxiesInteractedWith)
                self.proxiesInteractedWithRef.observe(.value, with: { (data) in
                    if let proxiesInteractedWith = data.value as? Int {
                        self.proxiesInteractedWith = proxiesInteractedWith.asStringWithCommas
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        messagesReceivedRef.removeAllObservers()
        messagesSentRef.removeAllObservers()
        proxiesInteractedWithRef.removeAllObservers()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 1
        case 2: return 2
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.meTableViewCell, for: indexPath as IndexPath) as! MeTableViewCell
//        let size = CGSize(width: 30, height: 30)
//        let isAspectRatio = true
        switch indexPath.section {

        case 0:
            cell.selectionStyle = .none
            switch indexPath.row {
            case 0:
//                cell.iconImageView.image = UIImage(named: "messages-received")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.subtitleLabel.text = messagesReceived
                cell.titleLabel?.text = "Messages Received"
            case 1:
//                cell.iconImageView.image = UIImage(named: "messages-sent")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.subtitleLabel.text = messagesSent
                cell.titleLabel?.text = "Messages Sent"
            case 2:
//                cell.iconImageView.image = UIImage(named: "proxies-interacted-with")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.subtitleLabel.text = proxiesInteractedWith
                cell.titleLabel?.text = "Proxies Interacted With"
            default: break
            }

        case 1:
            cell.accessoryType = .disclosureIndicator
//            cell.iconImageView.image = UIImage(named: "blocked")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
            cell.subtitleLabel.text = ""
            cell.titleLabel.text = "Blocked Users"

        case 2:
            cell.subtitleLabel.text = ""
            switch indexPath.row {
            case 0:
//                cell.iconImageView.image = UIImage(named: "logout")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.titleLabel?.text = "Log Out"
            case 1:
//                cell.iconImageView.image = UIImage(named: "about")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.titleLabel?.text = "About"
            default: break
            }

        default: break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {

        // Show blocked users
        case 1:
            let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifier.blockedUsersTableViewController) as! BlockedUsersTableViewController
            navigationController?.pushViewController(dest, animated: true)

        case 2:
            tableView.deselectRow(at: indexPath, animated: true)
            switch indexPath.row {

            // Log out
            case 0:
                let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
                    try? Auth.auth().signOut()
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(alert, animated: true, completion: nil)

            // Show About
            case 1:
                let alert = UIAlertController(title: "About Proxy:", message: "Contact: qvo1987@gmail.com\n\nUpcoming features: sound in videos, location sharing\n\nIcons from icons8.com\n\nLibraries used: Kingfisher, JSQMessagesViewController, Fusuma, MobilePlayer, RAMReel\n\nVersion 0.1", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel) { action in
                })
                self.present(alert, animated: true, completion: nil)

            default: return
            }
        default:
            return
        }
    }
}
