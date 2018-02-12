import Segmentio

// todo: better error and success messages
// todo: format text views
class MainLoginViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var segmentedControl: Segmentio!

    private let loginViewController = LoginViewController.make()
    private let signUpViewController = SignUpViewController.make()
    private var currentViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let segmentioOptions = SegmentioOptions(
            backgroundColor: .clear,
            indicatorOptions: SegmentioIndicatorOptions(
                color: UIColor(red: 53/255, green: 152/255, blue: 217/255, alpha: 1)
            ),
            horizontalSeparatorOptions: SegmentioHorizontalSeparatorOptions(
                type: .bottom,
                color: .lightGray
            ),
            verticalSeparatorOptions: SegmentioVerticalSeparatorOptions(
                color: .clear
            ),
            segmentStates: SegmentioStates(
                defaultState: segmentioState,
                selectedState: segmentioState,
                highlightedState: segmentioState
            )
        )

        segmentedControl.setup(
            content: [
                SegmentioItem(title: "Sign Up", image: nil),
                SegmentioItem(title: "Log In", image: nil)
            ],
            style: .onlyLabel,
            options: segmentioOptions
        )

        segmentedControl.valueDidChange = { [weak self] _, index in
            guard let _self = self else {
                return
            }
            _self.currentViewController?.view.removeFromSuperview()
            _self.currentViewController?.removeFromParentViewController()
            switch index {
            case 0:
                _self.showViewController(_self.signUpViewController)
            case 1:
                _self.showViewController(_self.loginViewController)
            default:
                break
            }
        }

        segmentedControl.selectedSegmentioIndex = 0
    }
}

private extension MainLoginViewController {
    var segmentioState: SegmentioState {
        return SegmentioState(
            backgroundColor: .clear,
            titleFont: UIFont.systemFont(ofSize: UIFont.systemFontSize),
            titleTextColor: .lightGray
        )
    }

    func showViewController(_ viewController: UIViewController) {
        addChildViewController(viewController)
        viewController.didMove(toParentViewController: self)
        viewController.view.frame = contentView.bounds
        contentView.addSubview(viewController.view)
        currentViewController = viewController
    }
}
