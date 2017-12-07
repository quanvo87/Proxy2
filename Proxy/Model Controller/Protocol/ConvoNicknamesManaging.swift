protocol ConvoNicknamesManaging: ReceiverNicknameManaging, SenderNicknameManaging {
    var convoNicknames: [String : String] { get set }
}
