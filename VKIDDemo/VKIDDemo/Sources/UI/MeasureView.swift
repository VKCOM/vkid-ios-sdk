//
// Copyright (c) 2023 - present, LLC “V Kontakte”
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

import UIKit

final class MeasureView: UIView {
    public var targetView: UIView? {
        didSet {
            self.setNeedsLayout()
        }
    }

    private let offset: CGFloat = 16

    init() {
        super.init(frame: .zero)

        self.backgroundColor = .clear
        self.clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let targetView = self.targetView else { return }

        self.frame = self.rectWithOffset(targetView.frame, offset: self.offset)

        self.setNeedsDisplay()
    }

    public override func draw(_ rect: CGRect) {
        let color = UIScreen
            .main
            .traitCollection
            .userInterfaceStyle == .light ?
            UIColor.darkGray.withAlphaComponent(0.5) :
            UIColor.lightGray.withAlphaComponent(0.5)

        self.drawLines(rect, with: color)
        self.drawText(rect, with: color)
    }

    private func rectWithOffset(_ rect: CGRect, offset: CGFloat) -> CGRect {
        CGRect(
            origin: CGPoint(
                x: rect.minX - offset,
                y: rect.minY - offset
            ),
            size: CGSize(
                width: rect.width + 2 * offset,
                height: rect.height + 2 * offset
            )
        )
    }

    private func drawLines(_ rect: CGRect, with color: UIColor) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let lineWidth: CGFloat = 0.5

        context.setLineWidth(lineWidth)
        context.setLineDash(phase: 0.0, lengths: [6])
        context.setStrokeColor(color.cgColor)

        context.move(
            to: CGPoint(x: 0, y: self.offset)
        )
        context.addLine(
            to: CGPoint(x: rect.size.width, y: self.offset)
        )
        context.move(
            to: CGPoint(x: 0, y: rect.height - self.offset)
        )
        context.addLine(
            to: CGPoint(x: rect.size.width, y: rect.height - self.offset)
        )
        context.move(
            to: CGPoint(x: self.offset, y: 0)
        )
        context.addLine(
            to: CGPoint(x: self.offset, y: rect.height)
        )
        context.move(
            to: CGPoint(x: rect.size.width - self.offset , y: 0)
        )
        context.addLine(
            to: CGPoint(x: rect.size.width - self.offset , y: rect.height)
        )
        context.strokePath()
    }

    private func drawText(_ rect: CGRect, with color: UIColor) {
        guard let targetView else { return }
        let size = targetView.frame.size
        let cornerRadius = targetView.layer.cornerRadius

        let attributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: self.offset - 2),
            NSAttributedString.Key.foregroundColor: color,
        ]

        let text = "\(Int(size.width)) x \(Int(size.height))"

        let textWidth = (text as NSString)
            .size(withAttributes: attributes)
            .width

        if textWidth > self.frame.width - 2 * self.offset {
            String(Int(size.width))
                .draw(
                    at: CGPoint(
                        x: self.offset,
                        y: 0
                    ),
                    withAttributes: attributes
                )
            String(Int(size.height))
                .draw(
                    at: CGPoint(
                        x: frame.size.width - self.offset,
                        y: self.offset
                    ),
                    withAttributes: attributes
                )
        } else {
            text.draw(
                at: CGPoint(x: self.offset, y: 0),
                withAttributes: attributes
            )
        }

        String(Int(cornerRadius))
            .draw(
                at: CGPoint(
                    x: 0,
                    y: frame.height - self.offset
                ),
                withAttributes: attributes
            )
    }
}
