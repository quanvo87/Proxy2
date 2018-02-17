import FontAwesome_swift
import PureLayout
import SwiftyButton

class Button: CustomPressableButton {
    private let activityIndicator = UIActivityIndicatorView()
    private var leftLabel: UILabel?
    private var centerLabel: UILabel?

    func setup(centerLabelText: String,
               centerLabelFont: UIFont? = nil,
               centerLabelTextColor: UIColor = .white,
               asFacebookButton: Bool = false,
               colors: ColorSet? = nil,
               disabledColors: ColorSet? = nil,
               cornerRadius: CGFloat = 5,
               shadowHeight: CGFloat = 5) {
        self.leftLabel?.removeFromSuperview()
        self.centerLabel?.removeFromSuperview()

        let centerLabel = UILabel(
            text: centerLabelText,
            font: centerLabelFont,
            textColor: centerLabelTextColor
        )
        contentView.addSubview(centerLabel)
        centerLabel.autoCenterInSuperview()
        self.centerLabel = centerLabel

        if asFacebookButton {
            setupAsFacebookButton()
        }

        if let colors = colors {
            self.colors = colors
        }

        if let disabledColors = disabledColors {
            self.disabledColors = disabledColors
        }

        self.cornerRadius = cornerRadius
        self.shadowHeight = shadowHeight
    }

    private func setupAsFacebookButton() {
        let leftLabel = UILabel(
            text: String.fontAwesomeIcon(name: .facebookSquare),
            font: UIFont.fontAwesome(ofSize: 25)
        )

        contentView.addSubview(leftLabel)

        leftLabel.autoPinEdgesToSuperviewEdges(
            with: UIEdgeInsets(
                top: 10, left: 15, bottom: 10, right: 0
            ),
            excludingEdge: .right
        )

        self.leftLabel = leftLabel

        colors = .init(button: .facebookBlue, shadow: .facebookDarkBlue)
        disabledColors = .init(button: .facebookBlue, shadow: .gray)
    }

    func showActivityIndicator() {
        isEnabled = false
        centerLabel?.isHidden = true

        contentView.addSubview(activityIndicator)
        activityIndicator.autoCenterInSuperview()
        activityIndicator.startAnimating()
    }

    func hideActivityIndicator() {
        isEnabled = true
        centerLabel?.isHidden = false

        activityIndicator.removeFromSuperview()
        activityIndicator.stopAnimating()
    }
}

// todo: move all util extensions into common
private extension UIColor {
    static var facebookBlue: UIColor {
        return UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1)
    }

    static var facebookDarkBlue: UIColor {
        return UIColor(red: 39/255, green: 69/255, blue: 132/255, alpha: 1)
    }
}

private extension UILabel {
    convenience init(text: String,
                     font: UIFont? = nil,
                     textColor: UIColor = .white) {
        self.init()
        if let font = font {
            self.font = font
        }
        self.text = text
        self.textColor = textColor
    }
}
