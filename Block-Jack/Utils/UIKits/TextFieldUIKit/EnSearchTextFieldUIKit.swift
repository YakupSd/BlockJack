//
//  EnSearchTextFieldUIKit.swift
//  TurkTicaretBankasi
//
//  Created by ISMAIL PALALI on 21.10.2024.
//

import SwiftUI
import UIKit

struct EnSearchTextFieldUIKit: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont
    var buttonTitle: String
    var keyboardType: TextFieldKeyboardType = .init(keyboardType: .default)
    var textColor: Color
    var shouldPushUpOnKeyboard: Bool
    var endEditingAction: () -> Void = {}
    var width: CGFloat = 300
    var height: CGFloat = 41
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EnSearchTextFieldUIKit
        var doneButton: UIBarButtonItem?

        init(parent: EnSearchTextFieldUIKit) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.endEditingAction()
        }
        
        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.backgroundColor = .clear
        textField.font = font
        textField.textColor = UIColor(textColor)
        textField.keyboardType = keyboardType.keyboardType

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(title: buttonTitle, style: .plain, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        context.coordinator.doneButton = doneButton

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexibleSpace, doneButton]
        textField.inputAccessoryView = toolbar
        NSLayoutConstraint.activate([
            textField.widthAnchor.constraint(equalToConstant: width),
            textField.heightAnchor.constraint(equalToConstant: height),
        ])
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.keyboardType = keyboardType.keyboardType
        uiView.textColor = UIColor(textColor)

        context.coordinator.doneButton?.title = buttonTitle

        if shouldPushUpOnKeyboard {
            uiView.resignFirstResponder()

            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    let keyboardHeight = keyboardFrame.cgRectValue.height
                    if let parentView = uiView.superview?.superview?.superview {
                        parentView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight / 2.2)
                    }
                }
            }

            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                if let parentView = uiView.superview?.superview?.superview {
                    parentView.transform = .identity
                }
            }
        }
    }
}
