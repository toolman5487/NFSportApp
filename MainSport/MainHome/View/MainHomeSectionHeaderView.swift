//
//  MainHomeSectionHeaderView.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import SDWebImage
import SkeletonView
import SnapKit
import UIKit

// MARK: - MainHomeSectionHeaderView

final class MainHomeSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "MainHomeSectionHeaderView"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let logoSize: CGFloat = 28
        static let contentSpacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = .primaryLabel
        imageView.isHidden = true
        return imageView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [logoImageView, titleLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = LayoutMetric.contentSpacing
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

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        logoImageView.sd_cancelCurrentImageLoad()
        logoImageView.image = nil
        logoImageView.isHidden = true
        logoImageView.tintColor = .primaryLabel
        titleLabel.text = nil
    }

    // MARK: - Configuration

    func configure(
        title: String,
        logoURL: URL?,
        fallbackSystemImageName: String
    ) {
        titleLabel.text = title
        let fallbackImage = makeFallbackImage(systemImageName: fallbackSystemImageName)

        switch logoURL {
        case .some(let logoURL):
            logoImageView.isHidden = false
            logoImageView.sd_setImage(with: logoURL, placeholderImage: fallbackImage)

        case .none:
            logoImageView.sd_cancelCurrentImageLoad()
            logoImageView.image = fallbackImage
            logoImageView.isHidden = false
        }
    }

    // MARK: - Private Methods

    private func makeFallbackImage(systemImageName: String) -> UIImage? {
        let image = UIImage(systemName: systemImageName)
            ?? UIImage(systemName: "sportscourt")
            ?? UIImage(systemName: "trophy")
        return image?.withRenderingMode(.alwaysTemplate)
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        addSubview(backgroundContainerView)
        backgroundContainerView.addSubview(contentStackView)

        backgroundContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        logoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutMetric.logoSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(LayoutMetric.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().inset(LayoutMetric.horizontalInset)
            make.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
        }
    }
}

// MARK: - MainHomeSectionSkeletonHeaderView

final class MainHomeSectionSkeletonHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "MainHomeSectionSkeletonHeaderView"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let logoSize: CGFloat = 28
        static let titleWidth: CGFloat = 160
        static let titleHeight: CGFloat = 28
        static let spacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        view.isSkeletonable = true
        return view
    }()

    private let logoView = MainHomeSkeletonFactory.makeSkeletonView(cornerRadius: 14)
    private let titleView = MainHomeSkeletonFactory.makeSkeletonView(cornerRadius: 8)

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [logoView, titleView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = LayoutMetric.spacing
        stackView.isSkeletonable = true
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

    // MARK: - Lifecycle

    override func didMoveToWindow() {
        super.didMoveToWindow()

        switch window {
        case .some:
            backgroundContainerView.layoutIfNeeded()
            backgroundContainerView.showAnimatedGradientSkeleton()

        case .none:
            backgroundContainerView.hideSkeleton()
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundContainerView.hideSkeleton()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        isSkeletonable = true
        addSubview(backgroundContainerView)
        backgroundContainerView.addSubview(stackView)

        backgroundContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        logoView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutMetric.logoSize)
        }

        titleView.snp.makeConstraints { make in
            make.width.equalTo(LayoutMetric.titleWidth)
            make.height.equalTo(LayoutMetric.titleHeight)
        }

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(LayoutMetric.horizontalInset)
            make.trailing.lessThanOrEqualToSuperview().inset(LayoutMetric.horizontalInset)
        }
    }
}
