import FontAwesome_swift
import PureLayout
import SwiftyButton

class Button: CustomPressableButton {
    enum ColorScheme {
        case normal
        case complement
        case facebook
        case custom(colors: ColorSet, disabledColors: ColorSet)
    }

    private let activityIndicator = UIActivityIndicatorView()
    private var leftLabel: UILabel?
    private var centerLabel: UILabel?

    func configure(colorScheme: ColorScheme = .normal,
                   centerLabelText: String,
                   centerLabelFont: UIFont? = nil,
                   centerLabelTextColor: UIColor = .white,
                   cornerRadius: CGFloat = 5,
                   shadowHeight: CGFloat = 5) {
        self.leftLabel?.removeFromSuperview()
        self.centerLabel?.removeFromSuperview()

        switch colorScheme {
        case .normal:
            self.colors = .init(button: Color.teal, shadow: Color.teal.shaded())
            self.disabledColors = .init(button: Color.teal.tinted(), shadow: Color.teal.tinted().shaded())
        case .complement:
            self.colors = .init(button: Color.orange, shadow: Color.orange.shaded())
            self.disabledColors = .init(button: Color.orange.tinted(), shadow: Color.orange.tinted().shaded()
            )
        case .facebook:
            setupAsFacebookButton()
        case .custom(let colors, let disabledColors):
            self.colors = colors
            self.disabledColors = disabledColors
        }

        let centerLabel = UILabel(
            text: centerLabelText,
            font: centerLabelFont,
            textColor: centerLabelTextColor
        )
        contentView.addSubview(centerLabel)
        centerLabel.autoCenterInSuperview()
        self.centerLabel = centerLabel

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

        colors = .init(button: Color.facebookBlue, shadow: Color.facebookBlue.shaded())
        disabledColors = .init(button: Color.facebookBlue.tinted(), shadow: Color.facebookBlue.tinted().shaded())
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
