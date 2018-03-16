import UIKit

class AboutViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "About"
    }
}

private extension AboutViewController {
    @IBAction func didTapThirdPartySoftwareButton(_ sender: Any) {
        let thirdPartySoftwareViewController = ThirdPartySoftwareViewController()
        let navigationController = UINavigationController(rootViewController: thirdPartySoftwareViewController)
        present(navigationController, animated: true)
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
