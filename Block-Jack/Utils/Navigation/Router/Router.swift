//
//  Router.swift
//  TurkiyeKatılımSigorta
//
//  Created by ISMAIL PALALI on 12.09.2023.
//

import UIKit
import Combine

protocol Router: ObservableObject {
    var nav: UINavigationController? { get set }
    func pushTo(view: UIViewController)
    func popToRoot()
}

extension Router {
    func popToRoot() {
        nav?.popToRootViewController(animated: true)
    }
    
    func popTo(view : UIViewController){
        nav?.popToViewController(view, animated: true)
    }
}
