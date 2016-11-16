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
    var icons = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = UIColor.whiteColor()
        
        navigationItem.title = "Select An Icon"
        
        let cancelButton = UIButton(type: .Custom)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: #selector(IconPickerCollectionViewController.cancel), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        ref.child(Path.Icons).child(api.uid).queryOrderedByChild(Path.Name).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            for child in snapshot.children {
                self.icons.append(child.value["name"] as! String)
            }
            self.collectionView?.reloadData()
        })
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSizeMake(60, 90)
        collectionView?.setCollectionViewLayout(flowLayout, animated: true)
        collectionView!.delaysContentTouches = false
        for case let scrollView as UIScrollView in collectionView!.subviews {
            scrollView.delaysContentTouches = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
        tabBarController?.tabBar.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.hidden = false
    }
    
    func cancel() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return icons.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Identifiers.IconPickerCell, forIndexPath: indexPath) as! IconPickerCell
        let icon = icons[indexPath.row]
        
        cell.iconImageView.kf_indicatorType = .Activity
        cell.iconImageView.image = nil
        api.getURL(forIcon: icon) { (url) in
            guard let url = url else { return }
            cell.iconImageView.kf_setImageWithURL(url, placeholderImage: nil)
        }
        
        let index = icon.endIndex.advancedBy(-3)
        cell.iconNameLabel.text = icon.substringToIndex(index)
        
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
