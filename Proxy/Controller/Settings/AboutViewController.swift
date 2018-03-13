import UIKit

class AboutViewController: UIViewController {
    @IBAction func didTapThirdPartySoftwareButton(_ sender: Any) {
    }

    @IBAction func didTapTermsAndConditionsButton(_ sender: Any) {
        showWebViewController(title: Constant.URL.termsAndConditions.name, url: Constant.URL.termsAndConditions.url)
    }

    @IBAction func didTapPrivacyPolicyButton(_ sender: Any) {
        showWebViewController(title: Constant.URL.privacyPolicy.name, url: Constant.URL.privacyPolicy.url)
    }

    @IBAction func didTapIcons8Button(_ sender: Any) {
        UIApplication.shared.open(Constant.URL.icons8)
    }

    @IBAction func didTapCoverrButton(_ sender: Any) {
        UIApplication.shared.open(Constant.URL.coverr)
    }
}
