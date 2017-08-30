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
    let ref = Database.database().reference()
    var icons = [String]()
    var proxy = Proxy()
    var convos = [Convo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select An Icon"
        
        let cancelButton = UIButton(type: .custom)
        cancelButton.addTarget(self, action: #selector(IconPickerCollectionViewController.cancel), for: UIControlEvents.touchUpInside)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelButton.setImage(UIImage(named: "cancel"), for: UIControlState.normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        collectionView?.backgroundColor = UIColor.white
        collectionView!.delaysContentTouches = false
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 90)
        collectionView?.setCollectionViewLayout(flowLayout, animated: true)
        for case let scrollView as UIScrollView in collectionView!.subviews {
            scrollView.delaysContentTouches = false
        }
        
        ref.child(Child.Icons).child(api.uid).queryOrdered(byChild: Child.Name).observeSingleEvent(of: .value, with: { (data) in
            for child in data.children {
                self.icons.append(((child as! DataSnapshot).value as AnyObject)[Child.Name] as! String)
            }
            self.collectionView?.reloadData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
    }
    
    @objc func cancel() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return icons.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifier.IconPickerCell, for: indexPath as IndexPath) as! IconPickerCell
//        let icon = icons[indexPath.row]
        cell.iconImageView.image = nil
//        api.getURL(forIconName: icon) { (url) in
//        }
//        cell.iconNameLabel.text = icon.substring(to: icon.index(icon.endIndex, offsetBy: -3))
        cell.layer.cornerRadius = 5
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.blue
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.white
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        api.setIcon(toIconNamed: icons[indexPath.row], for: proxy)
        _ = navigationController?.popViewController(animated: true)
    }
}
