import UIKit
import WQNetworkActivityIndicator

class WebViewController: UIViewController {
    private lazy var activityIndicatorView: UIActivityIndicatorView? = UIActivityIndicatorView(view)

    init(title: String, urlString: String) {
        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            target: self,
            action: #selector(close),
            image: Image.cancel
        )
        navigationItem.title = title

        guard let url = URL(string: urlString) else {
            return
        }

        let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        let urlRequest = URLRequest(url: url)

        webView.delegate = self
        webView.loadRequest(urlRequest)

        view.addSubview(webView)

        activityIndicatorView?.startAnimatingAndBringToFront()

        WQNetworkActivityIndicator.shared.show()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension WebViewController {
    @objc func close() {
        WQNetworkActivityIndicator.shared.hide()
        dismiss(animated: true)
    }
}

extension WebViewController: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicatorView?.removeFromSuperview()
        activityIndicatorView = nil
        WQNetworkActivityIndicator.shared.hide()
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        activityIndicatorView?.removeFromSuperview()
        activityIndicatorView = nil
        WQNetworkActivityIndicator.shared.hide()
    }
}
