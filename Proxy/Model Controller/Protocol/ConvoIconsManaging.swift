import JSQMessagesViewController

protocol ConvoIconsManaging: ReceiverIconManaging, SenderIconManaging {
    var convoIcons: [String : JSQMessagesAvatarImage] { get set }
}
