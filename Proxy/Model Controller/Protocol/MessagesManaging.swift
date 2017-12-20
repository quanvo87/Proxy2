import MessageKit

protocol MessagesManaging: class {
    var messages: [MessageType] { get set }
}
