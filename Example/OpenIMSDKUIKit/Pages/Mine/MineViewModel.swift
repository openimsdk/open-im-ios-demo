
import Foundation
import RxRelay
import RxSwift
import SVProgressHUD
import OIMUIKit

class MineViewModel {
    var currentUserRelay: BehaviorRelay<UserInfo?> = .init(value: nil)

    private let _disposeBag = DisposeBag()
    


    init() {
        IMController.shared.currentUserRelay.bind(to: currentUserRelay).disposed(by: _disposeBag)
        addListener()
    }

    func updateCurrentUserInfo() {
     
    }

    private func addListener() {}

    func updateGender(_ gender: Gender) {
        guard let user: UserInfo = currentUserRelay.value else { return }
        user.gender = gender
        AccountViewModel.updateUserInfo(userID: user.userID, gender: gender.rawValue) { (errCode, errMsg)  in
            IMController.shared.currentUserRelay.accept(user)
        }
    }

    func updateNickname(_ name: String) {
        guard let user: UserInfo = currentUserRelay.value else { return }
        user.nickname = name
        AccountViewModel.updateUserInfo(userID: user.userID, nickname: name) { (errCode, errMsg) in
            IMController.shared.currentUserRelay.accept(user)
        }
    }

    func updateBirthday(timeStampSeconds: Int) {
        guard let user: UserInfo = currentUserRelay.value else { return }
        user.birth = timeStampSeconds
        AccountViewModel.updateUserInfo(userID: user.userID, birth: timeStampSeconds) { (errCode, errMsg) in
            IMController.shared.currentUserRelay.accept(user)
        }
    }

    func updateFaceURL(url: String, onComplete: @escaping () -> Void) {
        guard let user: UserInfo = currentUserRelay.value else { return }
        user.faceURL = url
        AccountViewModel.updateUserInfo(userID: user.userID, faceURL: url) { (errCode, errMsg) in
            IMController.shared.currentUserRelay.accept(user)
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

    func uploadFile(fullPath: String, onProgress: @escaping (Int) -> Void, onComplete: @escaping () -> Void) {
        IMController.shared.uploadFile(fullPath: fullPath, onProgress: onProgress) { [weak self] (url: String?) in
            if let url = url {
                self?.updateFaceURL(url: url, onComplete: onComplete)
            }
        }
    }
}
