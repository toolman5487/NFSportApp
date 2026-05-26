//
//  ContentStateView.swift
//  NFSportApp
//
//  Created by Codex on 2026/5/26.
//

import SnapKit
import UIKit

// MARK: - ContentStateView

@MainActor
final class ContentStateView: UIView {

    // MARK: - State

    enum State {
        case hidden
        case loading(title: String, subtitle: String?)
        case message(
            style: MessageStyle,
            systemImageName: String?,
            title: String,
            subtitle: String?
        )
    }

    enum MessageStyle {
        case information
        case warning
        case error

        var defaultSystemImageName: String {
            switch self {
            case .information:
                return "info.circle"

            case .warning:
                return "exclamationmark.triangle"

            case .error:
                return "ladybug.slash.fill"
            }
        }

        var tintColor: UIColor {
            switch self {
            case .information:
                return .secondaryLabelColor

            case .warning:
                return .systemOrange

            case .error:
                return .systemRed
            }
        }
    }

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let iconSize: CGFloat = 40
        static let spacing: CGFloat = 12
        static let textSpacing: CGFloat = 4
    }

    // MARK: - UI Components

    private let activityIndicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabelColor
        imageView.isAccessibilityElement = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabelColor
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.textSpacing
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageView, activityIndicatorView, textStackView])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = LayoutMetric.spacing
        return stackView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Rendering

    func render(_ state: State) {
        switch state {
        case .hidden:
            isHidden = true
            activityIndicatorView.stopAnimating()

        case .loading(let title, let subtitle):
            isHidden = false
            imageView.isHidden = true
            activityIndicatorView.startAnimating()
            renderText(title: title, subtitle: subtitle)

        case .message(let style, let systemImageName, let title, let subtitle):
            isHidden = false
            imageView.isHidden = false
            activityIndicatorView.stopAnimating()
            imageView.tintColor = style.tintColor
            imageView.image = UIImage(systemName: systemImageName ?? style.defaultSystemImageName)
            renderText(title: title, subtitle: subtitle)
        }
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear

        addSubview(stackView)

        imageView.snp.makeConstraints { make in
            make.size.equalTo(LayoutMetric.iconSize)
        }

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func renderText(title: String, subtitle: String?) {
        titleLabel.text = title

        let normalizedSubtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        subtitleLabel.text = normalizedSubtitle
        subtitleLabel.isHidden = normalizedSubtitle?.isEmpty ?? true
    }
}
