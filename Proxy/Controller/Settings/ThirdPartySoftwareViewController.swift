import ESOpenSourceLicensesKit

class ThirdPartySoftwareViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            target: self,
            action: #selector(close),
            image: Image.cancel
        )
        navigationItem.title = "Third-party Software"
        view = ESOpenSourceLicensesView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ThirdPartySoftwareViewController {
    @objc func close() {
        dismiss(animated: true)
    }
}
