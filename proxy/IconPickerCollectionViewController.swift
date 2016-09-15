//
//  IconPickerCollectionViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/9/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class IconPickerCollectionViewController: UICollectionViewController {

    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var proxy = Proxy()
    var convos = [Convo]()
    
    var iconRef = FIRDatabaseReference()
    var iconRefHandle = FIRDatabaseHandle()
    var icons = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        observeIcons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
    }
    
    deinit {
        iconRef.removeObserverWithHandle(iconRefHandle)
    }
    
    func setUp() {
        navigationItem.title = "Select An Icon"
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSizeMake(60, 90)
        collectionView?.setCollectionViewLayout(flowLayout, animated: true)
        collectionView!.delaysContentTouches = false
        for case let scrollView as UIScrollView in collectionView!.subviews {
            scrollView.delaysContentTouches = false
        }
        collectionView?.backgroundColor = UIColor.whiteColor()
    }
    
    func observeIcons() {
        iconRef = ref.child("icons").child(api.uid)
        iconRefHandle = iconRef.queryOrderedByChild("name").observeEventType(.Value, withBlock: { (snapshot) in
            var icons = [String]()
            for child in snapshot.children {
                icons.append(child.value["name"] as! String)
            }
            self.icons = icons
            self.collectionView?.reloadData()
        })
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return icons.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Identifiers.IconPickerCell, forIndexPath: indexPath) as! IconPickerCell
        cell.icon = icons[indexPath.row]
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor().blue()
    }
    
    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor.whiteColor()
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        api.update(icon: icons[indexPath.row], forProxy: proxy)
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func tapCancelButton(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
}