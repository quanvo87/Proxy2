import UIKit

class AboutViewController: UIViewController {
    @IBAction func didTapThirdPartySoftwareButton(_ sender: Any) {
    }

    @IBAction func didTapTermsAndConditionsButton(_ sender: Any) {
    }

    @IBAction func didTapPrivacyPolicyButton(_ sender: Any) {
        showWebViewController(title: "Privacy Policy", urlString: Constant.URL.privacyPolicy)
    }

    @IBAction func didTapIcons8Button(_ sender: Any) {
    }

    @IBAction func didTapCoverrButton(_ sender: Any) {
    }
}
