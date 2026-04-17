//
//  TextFieldKeyboardType.swift
//  Block-Jack
//

import UIKit

/// UIKeyboardType wrapper — TextFieldUIKit ve EnSearchTextFieldUIKit tarafından kullanılır.
struct TextFieldKeyboardType {
    let keyboardType: UIKeyboardType

    init(keyboardType: UIKeyboardType = .default) {
        self.keyboardType = keyboardType
    }
}
