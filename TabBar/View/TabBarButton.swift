//
//  TabBarButton.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import SnapKit
import UIKit

final class TabBarButton: UIControl {

    // MARK: - Properties

    private(set) var tab: AppTab?

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        imageView.tintColor = .secondaryLabelColor
        return imageView
    }()

    private let badgeLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .badgeTextColor
        label.backgroundColor = .badgeBackgroundColor
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override var isHighlighted: Bool {
        didSet {
            alpha = 1
        }
    }

    // MARK: - Public Methods

    func configure(with item: TabBarItemViewData) {
        tab = item.tab
        iconImageView.image = UIImage(systemName: item.systemImageName)
        badgeLabel.text = "\(item.badgeCount)"
        badgeLabel.isHidden = item.badgeCount == 0

        let tintColor: UIColor = item.isSelected ? .primaryLabel : .secondaryLabelColor
        iconImageView.tintColor = tintColor
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(iconImageView)
        addSubview(badgeLabel)

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(32)
        }

        badgeLabel.snp.makeConstraints { make in
            make.centerX.equalTo(iconImageView.snp.trailing).offset(4)
            make.centerY.equalTo(iconImageView.snp.top)
            make.height.greaterThanOrEqualTo(16)
        }
    }
}

// MARK: - PaddingLabel

private final class PaddingLabel: UILabel {

    var insets = UIEdgeInsets.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        textAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize

        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
