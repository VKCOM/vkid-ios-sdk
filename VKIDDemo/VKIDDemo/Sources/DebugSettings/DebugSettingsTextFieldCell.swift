//
// Copyright (c) 2024 - present, LLC “V Kontakte”
//
// 1. Permission is hereby granted to any person obtaining a copy of this Software to
// use the Software without charge.
//
// 2. Restrictions
// You may not modify, merge, publish, distribute, sublicense, and/or sell copies,
// create derivative works based upon the Software or any part thereof.
//
// 3. Termination
// This License is effective until terminated. LLC “V Kontakte” may terminate this
// License at any time without any negative consequences to our rights.
// You may terminate this License at any time by deleting the Software and all copies
// thereof. Upon termination of this license for any reason, you shall continue to be
// bound by the provisions of Section 2 above.
// Termination will be without prejudice to any rights LLC “V Kontakte” may have as
// a result of this agreement.
//
// 4. Disclaimer of warranty and liability
// THE SOFTWARE IS MADE AVAILABLE ON THE “AS IS” BASIS. LLC “V KONTAKTE” DISCLAIMS
// ALL WARRANTIES THAT THE SOFTWARE MAY BE SUITABLE OR UNSUITABLE FOR ANY SPECIFIC
// PURPOSES OF USE. LLC “V KONTAKTE” CAN NOT GUARANTEE AND DOES NOT PROMISE ANY
// SPECIFIC RESULTS OF USE OF THE SOFTWARE.
// UNDER NO CIRCUMSTANCES LLC “V KONTAKTE” BEAR LIABILITY TO THE LICENSEE OR ANY
// THIRD PARTIES FOR ANY DAMAGE IN CONNECTION WITH USE OF THE SOFTWARE.
//

import Foundation
import UIKit

class DebugSettingsTextFieldCell: UITableViewCell {
    internal var onChange: ((String?) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.textField)
        NSLayoutConstraint.activate([
            self.contentView.leadingAnchor.constraint(
                equalTo: self.textField.leadingAnchor, constant: -16
            ),
            self.contentView.trailingAnchor.constraint(
                equalTo: self.textField.trailingAnchor, constant: 16
            ),
            self.contentView.centerYAnchor.constraint(
                equalTo: self.textField.centerYAnchor, constant: 0
            ),
            self.textField.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        self.onChange = nil
        self.textField.text = nil
    }

    lazy var textField = {
        let textField = UITextField()
        textField.addTarget(
            self,
            action: #selector(self.onTextChange),
            for: .editingChanged
        )
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    @objc
    private func onTextChange(textField: UITextField) {
        self.onChange?(textField.text)
    }

    func configure(
        placeholder: String,
        text: String?,
        keyboardType: UIKeyboardType = .default,
        action: @escaping (String?) -> Void
    ) {
        self.textField.text = text
        self.textField.placeholder = placeholder
        self.textField.keyboardType = keyboardType
        self.onChange = action
    }
}
