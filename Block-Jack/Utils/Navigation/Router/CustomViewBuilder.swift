//
//  CustomViewBuilder.swift
//  Block-Jack
//

import SwiftUI

protocol CustomViewBuilder {
    func makeView<T: View>(
        _ view: T,
        withNavigationTitle title: String,
        navigationBarHidden: Bool,
        autoPopPrevious: Bool,
        isNavBarAlphaAnimationActive: Bool,
        backgroundImage: String,
        isShowRightButton: Bool,
        rightImage: String,
        rightImageSize: CGSize,
        isBackAnimationActive: Bool,
        rightButtonAction: @escaping () -> Void
    ) -> UIViewController
}
