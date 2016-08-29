//self.ref.child("users").child(receiverProxy.owner).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
//    if let unread = currentData.value as? Int {
//        currentData.value = unread + 1
//        return FIRTransactionResult.successWithValue(currentData)
//    }
//    return FIRTransactionResult.successWithValue(currentData)
//}) { (error, committed, snapshot) in
//    if let error = error {
//        print("Error Updating Unread Message Count: \(error.localizedDescription)")
//    }
//}
//
//self.ref.child("users").child(receiverProxy.owner).child("proxies").child(receiverProxy.name).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
//    if let unread = currentData.value as? Int {
//        currentData.value = unread + 1
//        return FIRTransactionResult.successWithValue(currentData)
//    }
//    return FIRTransactionResult.successWithValue(currentData)
//}) { (error, committed, snapshot) in
//    if let error = error {
//        print("Error Updating Unread Message Count: \(error.localizedDescription)")
//    }
//}
//self.ref.child("users").child(receiverProxy.owner).child("convos").child(convoKey).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
//    if let unread = currentData.value as? Int {
//        currentData.value = unread + 1
//        return FIRTransactionResult.successWithValue(currentData)
//    }
//    return FIRTransactionResult.successWithValue(currentData)
//}) { (error, committed, snapshot) in
//    if let error = error {
//        print("Error Updating Unread Message Count: \(error.localizedDescription)")
//    }
//}