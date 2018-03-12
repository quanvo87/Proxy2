import FontAwesome_swift
import PureLayout
import SwiftyButton

class Button: CustomPressableButton {
    private let activityIndicator = UIActivityIndicatorView()
    private var leftLabel: UILabel?
    private var centerLabel: UILabel?

    func configure(centerLabelText: String,
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
            font: UIFont.fontAwesome(ofSize: DeviceUtilities.isSmallDevice ? 15 : 25)
        )

        contentView.addSubview(leftLabel)

        leftLabel.autoPinEdgesToSuperviewEdges(
            with: UIEdgeInsets(
                top: 10, left: 15, bottom: 10, right: 0
            ),
            excludingEdge: .right
        )

        self.leftLabel = leftLabel

        colors = .init(button: Color.facebookBlue, shadow: Color.facebookBlueShadow)
        disabledColors = .init(button: Color.facebookBlue, shadow: .gray)
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
