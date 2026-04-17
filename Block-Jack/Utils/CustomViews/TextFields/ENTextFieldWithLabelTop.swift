////
////  ENTextFieldWithLabelTopTowTruck.swift
////  TurkiyeKatılımSigorta
////
////  Created by enqura on 18.09.2023.
////
//
//import SwiftUI
//
//struct ENTextFieldWithLabelTop: View {
//    // MARK: - Properties
//    @EnvironmentObject var ue : UserEnvironment
//    var isSecureField: Bool = false
//    var height: CGFloat = 44
//    @Binding var txtFieldText: String
//    @State private var isClicked = false
//    var btnImageStyle: String? = "arrow.down"
//    @State var isPlaceHolderColorBlack: Bool = false
//    @State var hideTopLabel: Bool = false
//    @State var showRightButton: Bool = true
//    @State var showRawValue: Bool = false
//    @State var showLeftImage: Bool = true
//    var addCloseButtonControl = false
//    var showOtherWarningMessage:Bool = false
//    var showOtherWarningBorderColor = ThemeColors.colorStateError
//    var showOtherWarningTopLabelColor = ThemeColors.colorStateError
//    var showOtherWarningMassageColor = ThemeColors.colorStateError
//    var otherWarningMassageLineWidth: CGFloat = 1.4
//    var otherWarningMessage:String = ""
//    var showAsteriskPrefixForWarning: Bool = true
//    var showRightText: Bool = false
//    var rightText: String = UserEnvironment.shared.txtDay
//    var showRightBottomText: Bool = false
//    var rightBottomText: String = "*Opsiyonel"
//    var cornerRadius: CGFloat = 5
//    var lineWidth: CGFloat = 0.7
//    var txtPlaceHolder = "Placeholder"
//    var placeHolderFont: Font = .setCustomFont(name: .MavenMedium, size: 11)
//    var mainFont: UIFont = UIFont.setCustomUIFont(name: .MavenBold, size: 14)
//    var toolBarCloseButtonFont: Font = .setCustomFont(name: .MavenSemiBold, size: 14)
//    var topLabel = "Kimlik Numarası"
//    var colorTopLabel = ThemeColors.colorSecondaryDarkGray
//    var colorTopLabelBg = ThemeColors.colorTopLabelBg
//    @State var borderColor: Color = ThemeColors.colorPrimaryGray
//    var borderColorChecked: Color = ThemeColors.colorPrimaryGray
//    @State private var warningMessage: String = ""
//    var colorText = ThemeColors.colorSecondaryDarkGray
//    var mainBG = ThemeColors.colorSecondaryWhite
//    var topLabelTextSize: CGFloat = 10
//    var topLabelRatio: CGFloat = -60.0
//    var isDisabled = false
//    var validationType: TextFieldValidationType = .none
//    var configuration: TextFieldKeyboardType = .init(keyboardType: .default)
//    var minLength: Int = 0
//    var maxLenght: Int = 0
//    @State var customErrorPromt: String = ""
//    var systemImageName: String? = nil
//    var customImageName: String? = nil
//    var systemImageWidth: CGFloat = 16.0
//    var rightIconHeight: CGFloat = 18
//    @State var showLabel = false
//    var editFinished: (Bool) -> Void = { _ in }
//    var action: () -> Void = {}
//    var pushField:Bool = false
//    var beginEditingAction: () -> Void = {}
//    var endEditingAction: () -> Void = {}
//    
//    
//    // MARK: - Dynamic calucalated properties
//    
//    @State private var topLabelWidth: CGFloat = 0
//    @State private var topLabelHeight: CGFloat = 0
//    @State private var warningMessageHeight: CGFloat = 0
//    @State private var showTopLabel: Bool = false
//    var body: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                if showLeftImage {
//                    if let systemImageName {
//                        Image(systemName: systemImageName)
//                            .resizable()
//                            .foregroundColor(.black)
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: systemImageWidth)
//                            .padding(.leading, 15)
//                    } else if let customImageName {
//                        Image(customImageName)
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: systemImageWidth)
//                            .padding(.leading, 15)
//                    }
//                }
//                
//                
////                if isSecureField {
////                    SecureField("", text: $txtFieldText)
////                        .font(.setCustomFont(name: .MavenBold, size: 14))
////                        .lineLimit(0)
////                        .keyboardType(configuration.keyboardType)
////                        .foregroundColor(isPlaceHolderColorBlack ? .black : colorText)
////                        .multilineTextAlignment(.leading)
////                        .fixedSize(horizontal: false, vertical: true)
////                        .modifier(PlaceholderStyle(showPlaceHolder: txtFieldText.isEmpty, placeholder: txtPlaceHolder, isPlaceHolderColorBlack: isPlaceHolderColorBlack, placeHolderFont: placeHolderFont))
////                        .validateText($txtFieldText, validationType: validationType, borderColor: $borderColor, prompt: $warningMessage, userEnvironment: ue)
////                } else {
//                GeometryReader { geo in
//                    TextFieldUIKit(text: $txtFieldText,isFocused:$showTopLabel, font: mainFont,buttonTitle:ue.txtClose.localize ,isSecureField: isSecureField, keyboardType: TextFieldKeyboardType(keyboardType: configuration.keyboardType), textColor: isPlaceHolderColorBlack ? .black : colorText, shouldPushUpOnKeyboard: pushField, beginEditingAction: beginEditingAction, endEditingAction: endEditingAction, width: geo.size.width, height: geo.size.height, maxLength: (validationType == .phone || validationType == .billPaymentPhone) ? nil : (maxLenght > 0 ? maxLenght : nil))
////                                        .lineLimit(0)
//                        .modifier(PlaceholderStyle(showPlaceHolder: txtFieldText.isEmpty, placeholder:!showTopLabel ? txtPlaceHolder : "", isPlaceHolderColorBlack: isPlaceHolderColorBlack, placeHolderFont: placeHolderFont))
//                        .validateText(
//                            $txtFieldText,
//                            validationType: validationType,
//                            borderColor: $borderColor,
//                            prompt: $warningMessage,
//                            userEnvironment: ue,
//                            minLenght: minLength,
//                            maxLenght: maxLenght,
//                            customErrorText: (validationType == .customMinMax || validationType == .billPaymentPhone) ? $customErrorPromt : nil
//                        )
//                        .disabled(isDisabled)
//                }
//                                    
//                    
//                    
////                    TextField("", text: $txtFieldText, onEditingChanged: { finished in editFinished(finished) })
////                        .font(mainFont)
////                        .lineLimit(0)
////                        .keyboardType(configuration.keyboardType)
////                        .foregroundColor(isPlaceHolderColorBlack ? .black : colorText)
////                        .multilineTextAlignment(.leading)
////                        .fixedSize(horizontal: false, vertical: true)
////                        .modifier(PlaceholderStyle(showPlaceHolder: txtFieldText.isEmpty, placeholder: txtPlaceHolder, isPlaceHolderColorBlack: isPlaceHolderColorBlack, placeHolderFont: placeHolderFont))
////                        .validateText($txtFieldText, validationType: validationType, borderColor: $borderColor, prompt:$warningMessage,userEnvironment:ue)
////                        .disabled(isDisabled)
//                    
//                //}
//                
//                Spacer()
//                Button {
//                    action()
//                } label: {
//                    if showRightButton {
//                        let buttonImage = Image(btnImageStyle!)
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .foregroundColor(.black)
//                            .frame(height: rightIconHeight, alignment: .center)
//                        
//                        if addCloseButtonControl {
//                            if !txtFieldText.isEmpty {
//                                buttonImage
//                            }
//                        } else {
//                            buttonImage
//                        }
//                    }
//                }
//                
//                if showRightText {
//                    Text(rightText)
//                        .font(.setCustomFont(name: .MavenBold, size: 14))
//                        .foregroundStyle(colorText)
//                }
//            }
//            .frame(height: height)
//            .padding(.horizontal)
//            .background {
//                ZStack(alignment: .leading) {
//                    RoundedRectangle(cornerRadius: cornerRadius)
//                        .fill(isDisabled ? ThemeColors.colorSecondaryLightGray : mainBG)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: cornerRadius)
//                                .stroke(hasWarnings() ? showOtherWarningBorderColor : borderColor, lineWidth: hasWarnings() ? otherWarningMassageLineWidth : lineWidth)
//                        )
//                    if (showTopLabel && txtFieldText.count == 0) || (txtFieldText.count > 0 && !hideTopLabel) {
//                        Text(topLabel)
//                            .font(.setCustomFont(name: hasWarnings() ? .MavenBold : .MavenRegular, size: topLabelTextSize))
//                            .foregroundColor(hasWarnings() ? showOtherWarningTopLabelColor : colorTopLabel)
//                            .background {
//                                GeometryReader { geo in
//                                    colorTopLabelBg
//                                        .frame(width: geo.size.width + 18, height: 2)
//                                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
//                                }
//                            }
//                            .zIndex(2)
//                            .offset(x: 18, y: -height * 0.5)
//                    }
//                }
//                .animation(.smooth(duration: 0.2), value: txtFieldText.count)
//            }
//            
//            if showRightBottomText  {
//                HStack(alignment: .lastTextBaseline, spacing: 4) {
//                    Spacer()
//                    Text(rightBottomText)
//                        .multilineTextAlignment(.trailing)
//                        .lineLimit(nil)
//                }
//                .font(.setCustomFont(name: .MavenMedium, size: 11))
//                .foregroundStyle(ThemeColors.colorSecondaryDarkGray)
//            }
//            
//            if !warningMessage.isEmpty || showOtherWarningMessage {
//                HStack(alignment: .firstTextBaseline, spacing: 4) {
//                    let message = showOtherWarningMessage ? otherWarningMessage : warningMessage
//                    let prefix = (!showAsteriskPrefixForWarning || validationType == .customMinMax || validationType == .billPaymentPhone) ? "" : "* "
//                    Text("\(prefix)\(message)")
//                        .multilineTextAlignment(.leading)
//                        .lineLimit(nil)
//                }
//                .font(.setCustomFont(name: .MavenSemiBold, size: 11))
//                .foregroundStyle(showOtherWarningMassageColor)
//            }
//        }
//        .animation(.smooth(duration: 0.2), value: !warningMessage.isEmpty)
//    }
//    
//    private func hasWarnings() -> Bool {
//        showOtherWarningMessage || !warningMessage.isEmpty || borderColor == .red
//    }
//}
//
//struct ENTextFieldWithLabelTop_Previews: PreviewProvider {
//    @State static private var testText: String = "1"
//    @State static private var testType: TextFieldValidationType = .tc
//    
//    static var previews: some View {
//        ENTextFieldWithLabelTop(txtFieldText: $testText, validationType: testType)
//            .environmentObject(UserEnvironment())
//    }
//}
