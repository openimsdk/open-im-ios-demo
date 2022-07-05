
import Foundation
import RxDataSources
import RxRelay
import RxSwift

class SearchRecordViewModel {
    typealias MediaSectionModel = SectionModel<String, MessageInfo>
    let conversationId: String

    let textRelay: BehaviorRelay<[MessageInfo]> = .init(value: [])
    let imagesRelay: BehaviorRelay<[MediaSectionModel]> = .init(value: [])
    let videosRelay: BehaviorRelay<[MediaSectionModel]> = .init(value: [])
    let filesRelay: BehaviorRelay<[MediaSectionModel]> = .init(value: [])

    init(conversationId: String) {
        self.conversationId = conversationId
    }

    func searchText(_ text: String?) {
        guard let keyword = text, !keyword.isEmpty else {
            textRelay.accept([])
            return
        }
        let param = SearchParam()
        param.conversationID = conversationId
        param.messageTypeList = [MessageContentType.text]
        param.keywordList = [keyword]
        search(param: param) { [weak self] (messages: [MessageInfo]) in
            self?.textRelay.accept(messages)
        }
    }

    func searchImages() {
        let param = SearchParam()
        param.conversationID = conversationId
        param.messageTypeList = [MessageContentType.image]
        search(param: param) { [weak self] (messages: [MessageInfo]) in
            guard let sself = self else { return }
            let ret = sself.divideMessagesToSection(messages: messages)
            self?.imagesRelay.accept(ret)
        }
    }

    func searchVideos() {
        let param = SearchParam()
        param.conversationID = conversationId
        param.messageTypeList = [MessageContentType.video]
        search(param: param) { [weak self] (messages: [MessageInfo]) in
            guard let sself = self else { return }
            let ret = sself.divideMessagesToSection(messages: messages)
            self?.videosRelay.accept(ret)
        }
    }

    func searchFiles() {
        let param = SearchParam()
        param.conversationID = conversationId
        param.messageTypeList = [MessageContentType.file]
        search(param: param) { [weak self] (messages: [MessageInfo]) in
            guard let sself = self else { return }
            let ret = sself.divideMessagesToSection(messages: messages)
            self?.filesRelay.accept(ret)
        }
    }

    private func search(param: SearchParam, onSuccess: @escaping ([MessageInfo]) -> Void) {
        IMController.shared.searchRecord(param: param) { [weak self] (result: SearchResultInfo?) in
            guard let result = result else {
                return
            }
            var messages: [MessageInfo] = []
            for resultItem in result.searchResultItems {
                messages.append(contentsOf: resultItem.messageList)
            }
            onSuccess(messages)
        }
    }

    private func divideMessagesToSection(messages: [MessageInfo]) -> [MediaSectionModel] {
        var sections: [MediaSectionModel] = []
        var map: [String: [MessageInfo]] = [:]
        let current = Calendar.current
        var dateString = ""

        for message in messages {
            let sendTime = message.sendTime / 1000
            var sendDate = Date(timeIntervalSince1970: sendTime)
            if current.isDateInWeek(sendDate) {
                dateString = "本周".innerLocalized()
            } else if current.isDateInMonth(sendDate) {
                dateString = "本月".innerLocalized()
            } else {
                dateString = FormatUtil.getFormatDate(formatString: "yyyy/MM", of: Int(sendTime))
            }
            var list: [MessageInfo] = map[dateString] ?? []
            list.append(message)
            map[dateString] = list
        }

        for sectionName in map.keys.sorted() {
            let values: [MessageInfo] = map[sectionName] ?? []
            sections.append(MediaSectionModel(model: sectionName, items: values))
        }
        return sections
    }
}
