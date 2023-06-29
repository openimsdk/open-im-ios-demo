
import Foundation
import RxRelay
import RxSwift
import OUICore

class MineViewModel {
    var currentUserRelay: BehaviorRelay<QueryUserInfo?> = .init(value: nil)

    private let _disposeBag = DisposeBag()
    
    func queryUserInfo() {
        AccountViewModel.queryUserInfo(userIDList: [AccountViewModel.userID!],
                                       valueHandler: { [weak self] (users: [QueryUserInfo]) in
            guard let user: QueryUserInfo = users.first else { return }
            self?.currentUserRelay.accept(user)
        }, completionHandler: {(errCode, errMsg) in
        })
    }

    func updateGender(_ gender: Gender, completion: (() -> Void)?) {
        AccountViewModel.updateUserInfo(userID: IMController.shared.uid, gender: gender) { (errCode, errMsg) in
            completion?()
        }
    }

    func updateNickname(_ name: String, completion: (() -> Void)?) {
        AccountViewModel.updateUserInfo(userID: IMController.shared.uid, nickname: name) { (errCode, errMsg) in
            completion?()
        }
    }

    func updateBirthday(timeStampSeconds: Int, completion: (() -> Void)?) {
        AccountViewModel.updateUserInfo(userID: IMController.shared.uid, birth: timeStampSeconds * 1000) { (errCode, errMsg) in
            completion?()
        }
    }

    func updateFaceURL(url: String, onComplete: @escaping () -> Void) {
        AccountViewModel.updateUserInfo(userID: IMController.shared.uid, faceURL: url) { (errCode, errMsg) in
            onComplete()
        }
    }

    func logout() {
        IMController.shared.logout(onSuccess: { _ in
            IMController.shared.currentUserRelay.accept(nil)
            AccountViewModel.saveUser(uid: nil, imToken: nil, chatToken: nil)
            NotificationCenter.default.post(name: .init("logout"), object: nil)
        })
    }

    func uploadFile(fullPath: String, onProgress: @escaping (CGFloat) -> Void, onComplete: @escaping () -> Void) {
        IMController.shared.uploadFile(fullPath: fullPath, onProgress: onProgress) { [weak self] url in
            if let url = url {
                self?.updateFaceURL(url: url, onComplete: onComplete)
            }
        }
    }
}
