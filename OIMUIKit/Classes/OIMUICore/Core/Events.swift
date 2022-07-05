
import Foundation

class EventLoginSucceed: Event {}

class EventRecordClear: Event {
    let conversationId: String
    init(conversationId: String) {
        self.conversationId = conversationId
    }
}

public class EventLogout: Event {}

class EventGroupDismissed: Event {
    let conversationId: String
    init(conversationId: String) {
        self.conversationId = conversationId
    }
}
