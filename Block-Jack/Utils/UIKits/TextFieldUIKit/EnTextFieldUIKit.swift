//
//  EnTextFieldUIKit.swift
//  Block-Jack
//

import SwiftUI
import UIKit

struct EnTextFieldUIKit: UIViewRepresentable {
    @EnvironmentObject var userEnv: UserEnvironment
    @Binding var txtFieldText: String
    var isSecureField: Bool = false
    var height: CGFloat = 44
    var width: CGFloat = 300
    var txtPlaceHolder = "Placeholder"
    var topLabel = ""
    var colorTopLabel = UIColor(ThemeColors.textMuted)
    var borderColor: UIColor = UIColor(ThemeColors.surfaceDark)
    var cornerRadius: CGFloat = 8
    var lineWidth: CGFloat = 1.0
    var mainBGColor: UIColor = UIColor(ThemeColors.cosmicBlack)
    var textColor: UIColor = UIColor(ThemeColors.neonCyan)
    var isDisabled: Bool = false
    var configuration: TextFieldKeyboardType = .init(keyboardType: .default)

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EnTextFieldUIKit
        weak var topLabel: UILabel?
        weak var textField: UITextField?

        init(_ parent: EnTextFieldUIKit) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.txtFieldText = textField.text ?? ""
            updateTopLabel()
        }

        func updateTopLabel() {
            UIView.animate(withDuration: 0.2) {
                self.topLabel?.alpha = (self.textField?.text?.isEmpty == true) ? 0 : 1
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        // Top Label
        let topLabel = UILabel()
        topLabel.text = self.topLabel
        topLabel.font = UIFont.setCustomUIFont(name: .InterMedium, size: 10)
        topLabel.textColor = colorTopLabel
        topLabel.alpha = txtFieldText.isEmpty ? 0 : 1
        containerView.addSubview(topLabel)

        // TextField
        let textField = UITextField()
        textField.placeholder = txtPlaceHolder
        textField.font = UIFont.setCustomUIFont(name: .InterBold, size: 14)
        textField.keyboardType = configuration.keyboardType
        textField.isSecureTextEntry = isSecureField
        textField.text = txtFieldText
        textField.isEnabled = !isDisabled
        textField.textColor = textColor
        textField.backgroundColor = mainBGColor
        textField.layer.cornerRadius = cornerRadius
        textField.layer.borderWidth = lineWidth
        textField.layer.borderColor = borderColor.cgColor
        textField.delegate = context.coordinator
        
        // Toolbar for closing keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(
            title: userEnv.localizedString("Bitti", "Done"),
            style: .done,
            target: textField,
            action: #selector(UIView.endEditing(_:))
        )
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
        
        containerView.addSubview(textField)

        // Layout
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            topLabel.topAnchor.constraint(equalTo: containerView.topAnchor),

            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textField.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 4),
            textField.heightAnchor.constraint(equalToConstant: height),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            containerView.widthAnchor.constraint(equalToConstant: width)
        ])

        context.coordinator.topLabel = topLabel
        context.coordinator.textField = textField

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let textField = context.coordinator.textField {
            textField.text = txtFieldText
            textField.isSecureTextEntry = isSecureField
            textField.isEnabled = !isDisabled
        }
        context.coordinator.updateTopLabel()
    }
}
