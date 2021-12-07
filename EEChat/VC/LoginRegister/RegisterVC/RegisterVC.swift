//
//  RegisterVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/8.
//

import UIKit
import RxSwift
import web3swift

class RegisterVC: BaseViewController {
    
    @IBOutlet weak var phoneTextField: UITextField!
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
        let mnemonics = try! BIP39.generateMnemonics(bitsOfEntropy: 128)!
        super.show(param: mnemonics, callback: callback)
    }

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var mnemonicLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private lazy var mnemonic: String = {
        assert(self.param is String)
        return self.param as! String
    }()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if(segue.destination is VerifyPhoneLogicViewController){
            let vc = segue.destination as! VerifyPhoneLogicViewController
            vc.phone = phoneTextField.text ?? ""
        }
    }
    
    @IBAction func action() {
        if(phoneTextField.text?.isEmpty != false) {
            MessageModule.showMessage("请输入手机号")
            return
        }
        performSegue(withIdentifier: "reg", sender: nil)
    }
    
    private func bindAction() {
//        mnemonicLabel.text = mnemonic
//    
//        collectionView.rx.setDelegate(self)
//            .disposed(by: disposeBag)
//        
//        collectionView.eec.autoHeight()
//            .disposed(by: disposeBag)
//        
//        collectionView.collectionViewLayout = EECCollectionViewAutolayout(layout: collectionView.collectionViewLayout,
//                                                                          align: .center)
//        
//        Single.just(mnemonic.split(separator: " ").map{ String($0) })
//            .asObservable()
//            .bind(to: collectionView.rx.items(cellIdentifier: "cell", cellType: UICollectionViewCell.self))
//            { row, element, cell in
//                let label = cell.contentView.viewWithTag(1) as! UILabel
//                label.text = "\(row).\(element)"
//            }
//            .disposed(by: disposeBag)
    }
    
    @IBAction func copyAction() {
        UIPasteboard.general.string = mnemonic
        MessageModule.showMessage(LocalizedString("The mnemonic phrase has been copied, please keep it in a safe place!"))
    }
    
    @IBAction func nextAction() {
        RegisterNextVC.show(param: mnemonic)
    }
}


extension RegisterVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 130, height: 30)
    }
}
