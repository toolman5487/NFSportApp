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
        backgroundContainerView.addSubview(titleLabel)

        backgroundContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(8)
        }
    }
}
