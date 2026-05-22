//
//  BaseViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import SnapKit
import UIKit

@MainActor
class BaseViewController: UIViewController {

    // MARK: - State

    enum LoadingState: Equatable {
        case idle
        case loading
        case empty(message: String)
        case failed(message: String)
    }

    // MARK: - Properties

    var shouldDismissKeyboardOnTap: Bool {
        false
    }

    private var loadingState: LoadingState = .idle
    private lazy var keyboardDismissTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleKeyboardDismissTap))
        gesture.cancelsTouchesInView = false
        return gesture
    }()

    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    private let activityIndicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let messageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseView()
        setupNavigation()
        setupView()
        setupConstraints()
        bindViewModel()
        setupActions()
        bringBaseOverlayToFront()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Points

    func setupNavigation() {}

    func setupView() {}

    func setupConstraints() {}

    func bindViewModel() {}

    func setupActions() {}

    // MARK: - Public Methods

    func renderLoadingState(_ state: LoadingState) {
        guard loadingState != state else {
            return
        }

        loadingState = state

        switch state {
        case .idle:
            hideLoading()
            hideMessage()
        case .loading:
            showLoading()
            hideMessage()
        case .empty(let message):
            hideLoading()
            showMessage(message)
        case .failed(let message):
            hideLoading()
            showMessage(message)
        }
    }

    // MARK: - Setup

    private func setupBaseView() {
        view.backgroundColor = .systemBackground
        configureKeyboardDismissGestureIfNeeded()

        view.addSubview(dimmingView)
        view.addSubview(messageContainerView)
        dimmingView.addSubview(activityIndicatorView)
        messageContainerView.addSubview(messageLabel)

        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        activityIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        messageContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
        }

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configureKeyboardDismissGestureIfNeeded() {
        guard shouldDismissKeyboardOnTap else {
            return
        }

        view.addGestureRecognizer(keyboardDismissTapGesture)
    }

    private func bringBaseOverlayToFront() {
        view.bringSubviewToFront(messageContainerView)
        view.bringSubviewToFront(dimmingView)
    }

    // MARK: - Loading

    private func showLoading() {
        dimmingView.isHidden = false
        activityIndicatorView.startAnimating()

        UIView.animate(withDuration: 0.2) {
            self.dimmingView.alpha = 0.72
        }
    }

    private func hideLoading() {
        activityIndicatorView.stopAnimating()

        UIView.animate(withDuration: 0.2) {
            self.dimmingView.alpha = 0
        } completion: { [weak self] _ in
            self?.dimmingView.isHidden = true
        }
    }

    private func showMessage(_ message: String) {
        messageLabel.text = message
        messageContainerView.isHidden = false
    }

    private func hideMessage() {
        messageLabel.text = nil
        messageContainerView.isHidden = true
    }

    // MARK: - Actions

    @objc
    private func handleKeyboardDismissTap() {
        view.endEditing(true)
    }
}
