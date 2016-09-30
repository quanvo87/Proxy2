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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        observeIcons()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        iconRef.removeObserverWithHandle(iconRefHandle)
    }
    
    func setUp() {
        navigationItem.title = "Select An Icon"
        collectionView?.backgroundColor = UIColor.whiteColor()
        setUpCancelButton()
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSizeMake(60, 90)
        collectionView?.setCollectionViewLayout(flowLayout, animated: true)
        collectionView!.delaysContentTouches = false
        for case let scrollView as UIScrollView in collectionView!.subviews {
            scrollView.delaysContentTouches = false
        }
        iconRef = ref.child(Path.Icons).child(api.uid)
    }
    
    func setUpCancelButton() {
        let cancelButton = UIButton(type: .Custom)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: #selector(IconPickerCollectionViewController.closeIconPicker), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
    }
    
    func closeIconPicker() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func observeIcons() {
        iconRefHandle = iconRef.queryOrderedByChild(Path.Name).observeEventType(.Value, withBlock: { (snapshot) in
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
        let icon = icons[indexPath.row]
        
        // Set icon
        cell.iconImageView.image = nil
        cell.iconImageView.kf_indicatorType = .Activity
        api.getURL(forIcon: icon) { (url) in
            guard let url = url.absoluteString where url != "" else { return }
            cell.iconImageView.kf_setImageWithURL(NSURL(string: url), placeholderImage: nil)
        }
        
        // Set name
        let index = icon.endIndex.advancedBy(-3)
        cell.iconNameLabel.text = icon.substringToIndex(index)
        
        // Set up
        cell.layer.cornerRadius = 5
        
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
        api.set(icon: icons[indexPath.row], forProxy: proxy)
        navigationController?.popViewControllerAnimated(true)
    }
}
