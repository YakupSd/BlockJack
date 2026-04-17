//
//  EnClearTextFieldUIKitWithFocus.swift
//  TurkTicaretBankasi
//
//  Created by İhsan Akbay on 3.12.2024.
//

import SwiftUI

struct EnClearTextFieldUIKitWithFocus: UIViewRepresentable {
    @EnvironmentObject var userEnv: UserEnvironment
    @Binding var text: String
    @Binding var isEditing: Bool
        
    var placeholder: String = ""
    var font: UIFont = .setCustomUIFont(name: .InterRegular, size: 17)
    var textColor: UIColor = UIColor(ThemeColors.neonCyan)
    var returnKeyType: UIReturnKeyType = .done
    
    /// Klavye üstündeki "Kapat" butonuna basınca çalışacak (değişiklikleri iptal et)
    var cancelAction: (() -> Void)?
    
    /// Klavye üstündeki "Kapat" butonuna basınca çalışacak
    var doneButtonAction: (() -> Void)?
    
    /// Klavye kapandığında (done tuşu ya da editing bittiğinde) çalışacak
    var endEditedAction: (() -> Void)?
    
    func makeUIView(context: Context) -> WrappedTextField {
        let container = WrappedTextField()
        let textField = container.textField
            
        textField.backgroundColor = .clear
        textField.delegate = context.coordinator
            
        textField.font = font
        textField.textColor = textColor
        textField.placeholder = placeholder
        textField.returnKeyType = returnKeyType
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
            
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(
            title: userEnv.localizedString("Kapat", "Close"),
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
            
        return container
    }
        
    func updateUIView(_ uiView: WrappedTextField, context: Context) {
        let textField = uiView.textField
        if textField.text != text {
            textField.text = text
        }

        DispatchQueue.main.async {
            if isEditing {
                if !textField.isFirstResponder {
                    textField.becomeFirstResponder()
                }
            } else {
                if textField.isFirstResponder {
                    textField.resignFirstResponder()
                }
            }
        }
    }
        
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
        
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EnClearTextFieldUIKitWithFocus
        var isDoneButtonTapped = false
            
        init(_ textField: EnClearTextFieldUIKitWithFocus) {
            self.parent = textField
        }
            
        @objc func doneTapped() {
            isDoneButtonTapped = true
            parent.cancelAction?()
            parent.isEditing = false
        }
            
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if let text = textField.text,
               let textRange = Range(range, in: text)
            {
                let updatedText = text.replacingCharacters(in: textRange, with: string)
                parent.text = updatedText
            }
            return true
        }
            
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.isEditing = false
            textField.resignFirstResponder()
            return true
        }
            
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isEditing = true
            isDoneButtonTapped = false
        }
            
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isEditing = false
            if !isDoneButtonTapped {
                parent.endEditedAction?()
            }
            isDoneButtonTapped = false
        }
    }
}

class WrappedTextField: UIView {
    let textField: UITextField
        
    override init(frame: CGRect) {
        textField = UITextField()
        super.init(frame: frame)
            
        addSubview(textField)
            
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 44)
        ])
            
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
        
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
