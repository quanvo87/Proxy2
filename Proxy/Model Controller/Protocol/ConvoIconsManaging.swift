import JSQMessagesViewController

protocol ConvoIconsManaging: ReceiverIconManaging, SenderIconManaging {
    var icons: [String : JSQMessagesAvatarImage] { get set }
}
