//
//  MainHomeSectionHeaderView.swift
//  NFSportApp
//
//  Created by Willy Hsu 2026/5/23.
//

import SnapKit
import UIKit

final class MainHomeSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "MainHomeSectionHeaderView"

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let lineSpacing: CGFloat = 12
        static let lineHeight: CGFloat = 1
        static let minimumLineWidth: CGFloat = 24
    }

    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .primaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let leadingLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let trailingLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(backgroundContainerView)
        backgroundContainerView.addSubview(leadingLineView)
        backgroundContainerView.addSubview(titleLabel)
        backgroundContainerView.addSubview(trailingLineView)

        backgroundContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(LayoutMetric.verticalInset)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(LayoutMetric.verticalInset)
        }

        leadingLineView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.trailing.equalTo(titleLabel.snp.leading).offset(-LayoutMetric.lineSpacing)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.equalTo(LayoutMetric.lineHeight)
            make.width.greaterThanOrEqualTo(LayoutMetric.minimumLineWidth)
        }

        trailingLineView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(LayoutMetric.lineSpacing)
            make.trailing.equalToSuperview().inset(LayoutMetric.horizontalInset)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.equalTo(LayoutMetric.lineHeight)
            make.width.greaterThanOrEqualTo(LayoutMetric.minimumLineWidth)
        }
    }
}
