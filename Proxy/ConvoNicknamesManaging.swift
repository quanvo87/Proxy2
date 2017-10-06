protocol ConvoNicknamesManaging: ReceiverNicknameManaging, SenderNicknameManaging {
    var nicknames: [String : String] { get set }
}
