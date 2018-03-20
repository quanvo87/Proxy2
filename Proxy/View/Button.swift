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
            self.colors = .init(button: Color.blue, shadow: Color.blue.darkened())
            self.disabledColors = .init(button: Color.blue.tinted(), shadow: Color.blue.tinted().darkened())
        case .complement:
            self.colors = .init(button: Color.red, shadow: Color.red.darkened())
            self.disabledColors = .init(button: Color.red.tinted(), shadow: Color.red.tinted().darkened())
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
            font: UIFont.fontAwesome(ofSize: DeviceUtility.isSmallDevice ? 15 : 25)
        )

        contentView.addSubview(leftLabel)

        leftLabel.autoPinEdgesToSuperviewEdges(
            with: UIEdgeInsets(
                top: 10, left: 15, bottom: 10, right: 0
            ),
            excludingEdge: .right
        )

        self.leftLabel = leftLabel

        colors = .init(button: Color.facebookBlue, shadow: Color.facebookBlue.darkened())
        disabledColors = .init(button: Color.facebookBlue.tinted(), shadow: Color.facebookBlue.tinted().darkened())
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
