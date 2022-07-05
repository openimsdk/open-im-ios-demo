
import Foundation
import RxRelay
import RxSwift

class MineViewModel {
    let currentUserRelay: BehaviorRelay<UserInfo?> = .init(value: nil)

    private let _disposeBag = DisposeBag()

    init() {
        IMController.shared.currentUserRelay.bind(to: currentUserRelay).disposed(by: _disposeBag)
        addListener()
    }

    func updateCurrentUserInfo() {
        IMController.shared.getSelfInfo { _ in }
    }

    private func addListener() {}

    func updateGender(_ gender: Gender) {
        guard let user: UserInfo = currentUserRelay.value else { return }
        user.gender = gender
        IMController.shared.setSelfInfo(userInfo: user) { _ in
            IMController.shared.currentUserRelay.accept(user)
        }
    }

    func updateNickname(_ name: String) {
        guard let user: UserInfo = currentUserRelay.value else { return }
        user.nickname = name
        IMController.shared.setSelfInfo(userInfo: user) { _ in
            IMController.shared.currentUserRelay.accept(user)
        }
    }

    func updateBirthday(timeStampSeconds: Int) {
        guard let user: UserInfo = currentUserRelay.value else { return }
        user.birth = timeStampSeconds
        IMController.shared.setSelfInfo(userInfo: user) { _ in
            IMController.shared.currentUserRelay.accept(user)
        }
    }

    func updateFaceURL(url: String) {
        guard let user: UserInfo = currentUserRelay.value else { return }
        user.faceURL = url
        IMController.shared.setSelfInfo(userInfo: user) { _ in
            IMController.shared.currentUserRelay.accept(user)
        }
    }

    func logout() {
        IMController.shared.logout(onSuccess: { _ in
            IMController.shared.currentUserRelay.accept(nil)
            let event = EventLogout()
            JNNotificationCenter.shared.post(event)
        })
    }

    func uploadFile(fullPath: String, onProgress: @escaping (Int) -> Void, onComplete: @escaping () -> Void) {
        IMController.shared.uploadFile(fullPath: fullPath, onProgress: onProgress) { [weak self] (url: String?) in
            if let url = url {
                self?.updateFaceURL(url: url)
            }
            onComplete()
        }
    }
}
