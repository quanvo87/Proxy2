import JSQMessagesViewController

protocol ConvoMemberIconsManaging: ReceiverIconManaging, SenderIconManaging {
    var convoMemberIcons: [String: JSQMessagesAvatarImage] { get set }
}
