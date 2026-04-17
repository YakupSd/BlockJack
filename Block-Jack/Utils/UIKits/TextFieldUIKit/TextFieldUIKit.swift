//
//  File.swift
//  TurkTicaretBankasi
//
//  Created by Fatih Pazarbas on 16.10.2024.
//

import SwiftUI
import UIKit

struct TextFieldUIKit: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var font: UIFont
    var buttonTitle: String
    var isSecureField: Bool? = false
    var keyboardType: TextFieldKeyboardType = .init(keyboardType: .default)
    var textColor: Color
    var shouldPushUpOnKeyboard: Bool
    var beginEditingAction: () -> Void = {}
    var endEditingAction: () -> Void = {}
    var width: CGFloat
    var height: CGFloat
    var multilineTextAlignment: NSTextAlignment = .left
    var maxLength: Int? = nil

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: TextFieldUIKit
        var doneButton: UIBarButtonItem?
        let blackView = UIView()
        weak var textField: UITextField?
        init(parent: TextFieldUIKit) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
//            handleBlackView()
            parent.beginEditingAction()
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
//            handleDismissBlackView()
            parent.endEditingAction()
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.text = textField.text ?? ""
            }
        }

        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let currentText = textField.text else { return true }

            let nsString = currentText as NSString
            let prospectiveText = nsString.replacingCharacters(in: range, with: string)
            
            if let maxLength = parent.maxLength, !string.isEmpty {
                if currentText.count >= maxLength {
                    return false
                }
                if prospectiveText.count > maxLength {
                    return false
                }
            }

            // Sadece decimalPad klavye türü için özel karakter dönüşümünü uygula
            if parent.keyboardType.keyboardType == .decimalPad {
                let isTurkish = UserEnvironment.shared.language == .turkish
                let decimalSeparator = isTurkish ? "," : "."

                if string == "." || string == "," {
                    var newText = NSString(string: currentText).replacingCharacters(in: range, with: string)
                    newText = String(newText.dropLast()) + decimalSeparator
                    textField.text = newText
                    parent.text = newText
                    return false
                }
            }

            return true
        }

    }

    func makeCoordinator() -> Coordinator {
      
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.font = font
        textField.textColor = UIColor(textColor)
        textField.isSecureTextEntry = isSecureField ?? false
        textField.keyboardType = keyboardType.keyboardType
        textField.textAlignment = multilineTextAlignment
        containerView.addSubview(textField)
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(title: buttonTitle, style: .plain, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        context.coordinator.doneButton = doneButton

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexibleSpace, doneButton]
        textField.inputAccessoryView = toolbar
        containerView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.widthAnchor.constraint(equalToConstant: width),
            textField.heightAnchor.constraint(equalToConstant: height),
        ])
        context.coordinator.textField = textField
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let textField = context.coordinator.textField {
            textField.text = text
            textField.isSecureTextEntry = isSecureField ?? false
            textField.keyboardType = keyboardType.keyboardType
            textField.textColor = UIColor(textColor)
        }
       

        context.coordinator.doneButton?.title = buttonTitle
        
        

        if shouldPushUpOnKeyboard {
            if isFocused {
                uiView.becomeFirstResponder()
            } else {
                uiView.resignFirstResponder()
            }

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
