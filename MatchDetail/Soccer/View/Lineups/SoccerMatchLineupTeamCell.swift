//
//  SoccerMatchLineupTeamCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - SoccerMatchLineupTeamCell

final class SoccerMatchLineupTeamCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "SoccerMatchLineupTeamCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 12
        static let verticalInset: CGFloat = 10
        static let columnSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 8
        static let photoSize: CGFloat = 36
        static let centerWidth: CGFloat = 82
    }

    // MARK: - UI Components

    private let homeTeamLabel = makeTeamLabel(alignment: .left)
    private let awayTeamLabel = makeTeamLabel(alignment: .right)
    private let homeMetaLabel = makeMetaLabel(alignment: .left)
    private let awayMetaLabel = makeMetaLabel(alignment: .right)
    private let positionLabel = makePositionLabel()

    private let homePlayerView = SoccerMatchLineupPlayerColumnView(alignment: .left)
    private let awayPlayerView = SoccerMatchLineupPlayerColumnView(alignment: .right)

    private lazy var homeHeaderStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [homeTeamLabel, homeMetaLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        return stackView
    }()

    private lazy var awayHeaderStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [awayTeamLabel, awayMetaLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        return stackView
    }()

    private lazy var headerStackView: UIStackView = {
        let spacerView = UIView()
        let stackView = UIStackView(arrangedSubviews: [homeHeaderStackView, spacerView, awayHeaderStackView])
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = LayoutMetric.columnSpacing
        return stackView
    }()

    private lazy var rowStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [homePlayerView, positionLabel, awayPlayerView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = LayoutMetric.columnSpacing
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerStackView, rowStackView])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.rowSpacing
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
        homeTeamLabel.text = nil
        awayTeamLabel.text = nil
        homeMetaLabel.text = nil
        awayMetaLabel.text = nil
        positionLabel.text = nil
        headerStackView.isHidden = false
        homeMetaLabel.isHidden = true
        awayMetaLabel.isHidden = true
        homePlayerView.prepareForReuse()
        awayPlayerView.prepareForReuse()
    }

    // MARK: - Configuration

    func configure(
        with viewData: SoccerMatchLineupComparisonRowViewData,
        showsTeamHeader: Bool,
        homeTeamName: String,
        awayTeamName: String,
        homeMetaText: String?,
        awayMetaText: String?
    ) {
        headerStackView.isHidden = !showsTeamHeader
        homeTeamLabel.text = homeTeamName
        awayTeamLabel.text = awayTeamName
        configureMetaLabel(homeMetaLabel, text: homeMetaText)
        configureMetaLabel(awayMetaLabel, text: awayMetaText)

        positionLabel.text = viewData.positionTitle
        positionLabel.isHidden = viewData.positionTitle == nil

        homePlayerView.configure(with: viewData.homePlayer)
        awayPlayerView.configure(with: viewData.awayPlayer)
    }

    private func configureMetaLabel(_ label: UILabel, text: String?) {
        if let text, !text.isEmpty {
            label.text = text
            label.isHidden = false
        } else {
            label.text = nil
            label.isHidden = true
        }
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .secondaryBackgroundColor
        contentView.layer.cornerRadius = 12

        contentView.addSubview(contentStackView)

        headerStackView.arrangedSubviews[1].snp.makeConstraints { make in
            make.width.equalTo(LayoutMetric.centerWidth)
        }

        positionLabel.snp.makeConstraints { make in
            make.width.equalTo(LayoutMetric.centerWidth)
        }

        homePlayerView.snp.makeConstraints { make in
            make.width.equalTo(awayPlayerView)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: LayoutMetric.verticalInset,
                    left: LayoutMetric.horizontalInset,
                    bottom: LayoutMetric.verticalInset,
                    right: LayoutMetric.horizontalInset
                )
            )
        }
    }

    // MARK: - Factories

    private static func makeTeamLabel(alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.textAlignment = alignment
        return label
    }

    private static func makeMetaLabel(alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.textAlignment = alignment
        return label
    }

    private static func makePositionLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }
}

// MARK: - SoccerMatchLineupPlayerColumnView

private final class SoccerMatchLineupPlayerColumnView: UIView {

    // MARK: - UI Components

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.tintColor = .secondaryLabel
        imageView.layer.cornerRadius = LayoutMetric.photoSize / 2
        imageView.backgroundColor = .tertiarySystemFill
        return imageView
    }()

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.84
        label.numberOfLines = 2
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [numberLabel, nameLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [photoImageView, textStackView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private let alignment: NSTextAlignment

    // MARK: - Initialization

    init(alignment: NSTextAlignment) {
        self.alignment = alignment
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func prepareForReuse() {
        photoImageView.sd_cancelCurrentImageLoad()
        photoImageView.image = nil
        numberLabel.text = nil
        nameLabel.text = nil
        isHidden = false
    }

    func configure(with viewData: SoccerMatchLineupPlayerViewData?) {
        guard let viewData else {
            prepareForReuse()
            isHidden = true
            return
        }

        numberLabel.text = viewData.numberText
        numberLabel.isHidden = viewData.numberText == nil
        nameLabel.text = viewData.displayName

        let placeholderImage = UIImage(systemName: "person.crop.circle.fill")?.withRenderingMode(.alwaysTemplate)
        if let photoURL = viewData.photoURL {
            photoImageView.sd_setImage(with: photoURL, placeholderImage: placeholderImage)
        } else {
            photoImageView.sd_cancelCurrentImageLoad()
            photoImageView.image = placeholderImage
        }
    }

    // MARK: - Setup

    private func setupView() {
        numberLabel.textAlignment = alignment
        nameLabel.textAlignment = alignment

        if alignment == .right {
            stackView.removeArrangedSubview(photoImageView)
            stackView.insertArrangedSubview(photoImageView, at: 1)
        }

        addSubview(stackView)

        photoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutMetric.photoSize)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private enum LayoutMetric {
        static let photoSize: CGFloat = 36
    }
}
