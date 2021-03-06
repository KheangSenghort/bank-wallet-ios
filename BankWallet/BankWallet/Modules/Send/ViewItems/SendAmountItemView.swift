import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit
import RxSwift
import RxCocoa

class AmountTextField: UITextField {
    var onPaste: (() -> ())?

    override func paste(_ sender: Any?) {
        onPaste?()
    }

}

class SendAmountItemView: BaseActionItemView {
    private let disposeBag = DisposeBag()

    private let amountTypeLabel = UILabel()
    private let inputField = AmountTextField()
    private let lineView = UIView()
    private let maxButton = RespondButton()
    private let hintLabel = UILabel()
    private let errorLabel = UILabel()
    private let switchButton = RespondButton()
    private let switchButtonIcon = UIImageView()

    override var item: SendAmountItem? { return _item as? SendAmountItem }

    override func initView() {
        super.initView()

        backgroundColor = SendTheme.itemBackground

        addSubview(amountTypeLabel)
        addSubview(lineView)
        addSubview(maxButton)
        addSubview(inputField)
        addSubview(switchButton)
        addSubview(hintLabel)
        addSubview(errorLabel)
        switchButton.addSubview(switchButtonIcon)

        amountTypeLabel.font = SendTheme.amountFont
        amountTypeLabel.textColor = SendTheme.amountColor
        amountTypeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        amountTypeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
        }

        lineView.backgroundColor = SendTheme.amountLineColor
        lineView.snp.makeConstraints { maker in
            maker.leading.equalTo(amountTypeLabel)
            maker.top.equalTo(inputField.snp.bottom).offset(SendTheme.amountLineTopMargin)
            maker.height.equalTo(SendTheme.amountLineHeight)
        }

        maxButton.onTap = { [weak self] in
            self?.item?.onMaxClicked?()
        }
        maxButton.titleLabel.text = "send.max_button".localized
        maxButton.borderWidth = 1 / UIScreen.main.scale
        maxButton.borderColor = SendTheme.buttonBorderColor
        maxButton.cornerRadius = SendTheme.buttonCornerRadius
        maxButton.backgrounds = SendTheme.buttonBackground
        maxButton.textColors = [.active: SendTheme.buttonIconColor, .selected: SendTheme.buttonIconColor]
        maxButton.titleLabel.font = SendTheme.buttonFont
        maxButton.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        maxButton.snp.makeConstraints { maker in
            maker.leading.equalTo(lineView.snp.trailing).offset(SendTheme.smallMargin)
            maker.centerY.equalTo(lineView)
            maker.height.equalTo(SendTheme.buttonSize)
        }
        maxButton.titleLabel.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.buttonTitleHorizontalMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.buttonTitleHorizontalMargin)
        }

        inputField.inputView = UIView()
        inputField.font = SendTheme.amountFont
        inputField.textColor = SendTheme.amountColor
        inputField.attributedPlaceholder = NSAttributedString(string: "send.amount_placeholder".localized, attributes: [NSAttributedStringKey.foregroundColor: SendTheme.amountPlaceholderColor])
        inputField.keyboardAppearance = AppTheme.keyboardAppearance
        inputField.keyboardType = .decimalPad
        inputField.tintColor = SendTheme.amountInputTintColor
        inputField.snp.makeConstraints { maker in
            maker.centerY.equalTo(amountTypeLabel.snp.centerY)
            maker.leading.equalTo(amountTypeLabel.snp.trailing).offset(SendTheme.smallMargin)
            maker.top.equalToSuperview().offset(SendTheme.margin)
            maker.trailing.equalTo(lineView)
        }

        switchButton.borderWidth = 1 / UIScreen.main.scale
        switchButton.borderColor = SendTheme.buttonBorderColor
        switchButton.cornerRadius = SendTheme.buttonCornerRadius
        switchButton.backgrounds = SendTheme.buttonBackground
        switchButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.centerY.equalTo(lineView.snp.centerY)
            maker.leading.equalTo(maxButton.snp.trailing).offset(SendTheme.smallMargin)
            maker.size.equalTo(SendTheme.buttonSize)
        }

        switchButtonIcon.image = UIImage(named: "Send Switch Icon")
        switchButtonIcon.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        hintLabel.font = SendTheme.amountHintFont
        hintLabel.textColor = SendTheme.amountHintColor
        hintLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalTo(lineView).offset(SendTheme.smallMargin)
            maker.trailing.equalTo(lineView)
        }

        errorLabel.font = SendTheme.errorFont
        errorLabel.textColor = SendTheme.errorColor
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalTo(lineView).offset(SendTheme.smallMargin)
            maker.trailing.equalTo(lineView)
        }

        inputField.onPaste = { [weak self] in
            self?.item?.onPasteClicked?()
        }
        inputField.rx.controlEvent(.editingChanged)
                .subscribe(onNext: { [weak self] _ in
                    self?.updateUI()

                    let amount: Decimal = ValueFormatter.instance.parseAnyDecimal(from: self?.inputField.text) ?? 0
                    self?.item?.onAmountChanged?(amount)
                })
                .disposed(by: disposeBag)
        switchButton.onTap = item?.onSwitchClicked

        item?.showKeyboard = { [weak self] in
            DispatchQueue.main.async {
                self?.inputField.becomeFirstResponder()
            }
        }

        item?.bindAmountType = { [weak self] in
            self?.amountTypeLabel.text = $0
        }
        item?.bindAmount = { [weak self] in
            let amount = $0 ?? 0
            let formattedAmount = ValueFormatter.instance.format(amount: amount)
            self?.inputField.text = amount == 0 ? nil : formattedAmount
            self?.inputField.sendActions(for: .editingChanged)
        }
        item?.bindHint = { [weak self] in
            self?.hintLabel.text = $0
        }
        item?.bindError = { [weak self] in
            self?.errorLabel.text = $0
        }
        item?.bindSwitchEnabled = { [weak self] enabled in
            self?.switchButton.state = enabled ? .active : .disabled
            self?.switchButtonIcon.tintColor = enabled ? SendTheme.buttonIconColor : SendTheme.buttonIconColorDisabled
        }

        item?.addLetter = { [weak self] letter in
            self?.addLetter(letter)
        }
        item?.removeLetter = { [weak self] in
            self?.inputField.deleteBackward()
        }
    }

    func addLetter(_ letter: String) {
        if let selectedRange = inputField.selectedTextRange, let text = inputField.text {
            let cursorPosition = inputField.offset(from: inputField.beginningOfDocument, to: selectedRange.start)
            let index = text.index(text.startIndex, offsetBy: cursorPosition)

            var text = text
            text.insert(Character(letter), at: index)
            if let value = ValueFormatter.instance.parseAnyDecimal(from: text), value.decimalCount <= (item?.decimal ?? 0) {
                inputField.insertText(letter)
            } else {
                inputField.shakeView()
            }
        } else {
            inputField.insertText(letter)
        }
    }

    func updateUI() {
        let text = inputField.text ?? ""
        maxButton.snp.remakeConstraints { maker in
            if text.count == 0 {
                maker.leading.equalTo(lineView.snp.trailing).offset(SendTheme.smallMargin)
                maker.centerY.equalTo(lineView)
                maker.height.equalTo(SendTheme.buttonSize)
            } else {
                maker.leading.equalTo(lineView.snp.trailing).offset(0)
                maker.centerY.equalTo(lineView)
                maker.height.equalTo(SendTheme.buttonSize)
                maker.width.equalTo(0)
            }
        }
    }

}
