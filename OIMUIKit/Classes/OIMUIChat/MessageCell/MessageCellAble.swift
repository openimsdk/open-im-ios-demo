
import Foundation

protocol MessageCellAble: UITableViewCell {
    func setMessage(model: MessageInfo, extraInfo: ExtraInfo?)
    var delegate: MessageDelegate? { get set }
}

protocol MessageDelegate: AnyObject {
    func didTapMessageCell(cell: UITableViewCell, with message: MessageInfo)
    func didLongPressBubbleView(bubbleView: UIView, with message: MessageInfo)
    func didTapResendBtn(with message: MessageInfo)
    func didTapAvatar(with message: MessageInfo)
    func didDoubleTapMessageCell(cell: UITableViewCell, with message: MessageInfo)
    func didTapQuoteView(cell: UITableViewCell, with message: MessageInfo)
}

struct ExtraInfo {
    let isC2C: Bool
}

enum MessageCell {
    static let allCells: [UITableViewCell.Type] = [
        MessageTextLeftTableViewCell.self,
        MessageTextRightTableViewCell.self,
        MessageAudioLeftTableViewCell.self,
        MessageAudioRightTableViewCell.self,
        MessageVideoLeftTableViewCell.self,
        MessageVideoRightTableViewCell.self,
        MessageBusinessCardLeftTableViewCell.self,
        MessageBusinessCardRightTableViewCell.self,
        MessageImageLeftTableViewCell.self,
        MessageImageRightTableViewCell.self,
        MessageQuoteLeftTableViewCell.self,
        MessageQuoteRightTableViewCell.self,
        MessageTimeOrTipsTableViewCell.self,
    ]

    static let rightCellsMap: [MessageContentType: MessageCellAble.Type] = [
        .text: MessageTextRightTableViewCell.self,
        .audio: MessageAudioRightTableViewCell.self,
        .video: MessageVideoRightTableViewCell.self,
        .card: MessageBusinessCardRightTableViewCell.self,
        .quote: MessageQuoteRightTableViewCell.self,
        .image: MessageImageRightTableViewCell.self,
    ]

    static let leftCellsMap: [MessageContentType: MessageCellAble.Type] = [
        .text: MessageTextLeftTableViewCell.self,
        .audio: MessageAudioLeftTableViewCell.self,
        .video: MessageVideoLeftTableViewCell.self,
        .card: MessageBusinessCardLeftTableViewCell.self,
        .quote: MessageQuoteLeftTableViewCell.self,
        .image: MessageImageLeftTableViewCell.self,
    ]

    static func getCellType(by messageType: MessageContentType, isRight: Bool) -> MessageCellAble.Type {
        if isRight {
            let cellType = rightCellsMap[messageType] ?? MessageTimeOrTipsTableViewCell.self
            return cellType
        }

        let cellType = leftCellsMap[messageType] ?? MessageTimeOrTipsTableViewCell.self
        return cellType
    }
}
