
import Foundation
import RxRelay
import RxSwift

class GroupListViewModel {
    let isICreateTableSelected: BehaviorRelay<Bool> = .init(value: true)
    let items: BehaviorRelay<[GroupInfo]> = .init(value: [])
    let myGroupsRelay: BehaviorRelay<[GroupInfo]> = .init(value: [])
    private let _disposeBag = DisposeBag()
    private var iCreateGroups: [GroupInfo] = []
    private var iJoinedGroups: [GroupInfo] = []
    init() {
        isICreateTableSelected.subscribe(onNext: { [weak self] (isICreated: Bool) in
            guard let sself = self else { return }
            if isICreated {
                self?.items.accept(sself.iCreateGroups)
            } else {
                self?.items.accept(sself.iJoinedGroups)
            }
        }).disposed(by: _disposeBag)
    }

    func getMyGroups() {
        IMController.shared.getJoinedGroupList { [weak self] (groups: [GroupInfo]) in
            let groups: [GroupInfo] = groups ?? []
            var createGroups: [GroupInfo] = []
            var joinedGroups: [GroupInfo] = []
            for group in groups {
                if group.creatorUserID == IMController.shared.imManager.getLoginUid() {
                    createGroups.append(group)
                } else {
                    joinedGroups.append(group)
                }
            }
            self?.iCreateGroups = createGroups
            self?.iJoinedGroups = joinedGroups
            self?.myGroupsRelay.accept(groups)
            self?.isICreateTableSelected.accept(true)
        }
    }
}
