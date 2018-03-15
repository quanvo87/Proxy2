import paper_onboarding
import SwiftVideoBackground
import SwiftyButton

class WelcomeViewController: UIViewController {
    @IBOutlet weak var onboarding: PaperOnboarding!
    @IBOutlet weak var createAccountButton: Button!
    @IBOutlet weak var logInButton: Button!

    // swiftlint:disable line_length
    private let onboardingItems = [
        OnboardingItemInfo(
            title: "Welcome",
            description: "Sign in to talk to anyone in the world without revealing your identity.",
            pageIcon: Image.make(.comments)
        ),
        OnboardingItemInfo(
            title: "Fast. Easy.",
            description: "Create a new identify with just one tap. Throw it away when you’re done. Have up to 30 at a time!",
            pageIcon: Image.make(.users)
        ),
        OnboardingItemInfo(
            title: "NEVER Share Your Contact Info",
            description: "Perfect for when you need to communicate with a stranger briefly, but never want them to contact you again. 👋",
            pageIcon: Image.make(.userSecret)
        ),
        OnboardingItemInfo(
            title: "Talk To Anyone",
            description: "Anyone in the world can message you--without knowing your personal info.",
            pageIcon: Image.make(.globe)
        ),
        OnboardingItemInfo(
            title: "Free!",
            description: "Tap below to begin.",
            pageIcon: Image.make(.heart)
        )
    ]
    // swiftlint:enable line_length

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = ""

        try? VideoBackground.shared.play(view: view, videoName: "login", videoType: "mp4", darkness: 0.25)

        onboarding.backgroundColor = .clear
        onboarding.dataSource = self

        createAccountButton.configure(centerLabelText: "CREATE ACCOUNT")

        logInButton.configure(
            centerLabelText: "LOG IN",
            colors: PressableButton.ColorSet(button: Color.logInButtonRed, shadow: Color.logInButtonRedShadow)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
}

private extension WelcomeViewController {
    @IBAction func didTapCreateAccountButton(_ sender: Any) {
        let signUpViewController = SignUpViewController.make()
        navigationController?.pushViewController(signUpViewController, animated: true)
    }

    @IBAction func didTapLogInButton(_ sender: Any) {
        let logInViewController = LogInViewController.make()
        navigationController?.pushViewController(logInViewController, animated: true)
    }
}

extension WelcomeViewController: PaperOnboardingDataSource {
    func onboardingItemsCount() -> Int {
        return onboardingItems.count
    }

    func onboardingItem(at index: Int) -> OnboardingItemInfo {
        return onboardingItems[index]
    }
}
