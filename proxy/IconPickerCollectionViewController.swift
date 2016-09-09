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
    var iconRef = FIRDatabaseReference()
    var iconRefHandle = FIRDatabaseHandle()
    var icons = [String]()
    var proxy = Proxy()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select An Icon"
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSizeMake(60, 90)
        collectionView?.setCollectionViewLayout(flowLayout, animated: true)
        
        collectionView!.delaysContentTouches = false
        for case let scrollView as UIScrollView in collectionView!.subviews {
            scrollView.delaysContentTouches = false
        }
        
        collectionView?.backgroundColor = UIColor.whiteColor()
        
        observeIcons()
    }
    
    deinit {
        iconRef.removeObserverWithHandle(iconRefHandle)
    }
    
    func observeIcons() {
        iconRef = ref.child("icons").child(api.uid)
        iconRefHandle = iconRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let icons = snapshot.value?.allKeys as? [String] {
                self.icons = icons.sort()
                self.collectionView?.reloadData()
            }
        })
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return icons.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Icon Picker Cell", forIndexPath: indexPath) as! IconPickerCell
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
}