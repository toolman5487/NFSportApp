//
//  SoccerMatchLineupTeamCell.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/29.
//

import SnapKit
import UIKit

// MARK: - SoccerMatchLineupTeamCell

final class SoccerMatchLineupTeamCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "SoccerMatchLineupTeamCell"

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 16
        static let sectionSpacing: CGFloat = 16
        static let compactWidth: CGFloat = 360
        static let cornerRadius: CGFloat = 12
    }

    // MARK: - UI Components

    private let homeSummaryView = SoccerMatchLineupTeamSummaryView()
    private let awaySummaryView = SoccerMatchLineupTeamSummaryView()
    private let startersTitleLabel = makeSectionLabel(text: "Starting XI")
    private let pitchView = SoccerMatchLineupPitchView()
    private let substitutesContainerView = UIView()
    private let substitutesTitleLabel = makeSectionLabel(text: "Substitutes")
    private let homeSubstitutesView = SoccerMatchLineupSubstituteListView()
    private let awaySubstitutesView = SoccerMatchLineupSubstituteListView()

    private lazy var summaryStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [homeSummaryView, awaySummaryView])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    private lazy var substitutesColumnsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [homeSubstitutesView, awaySubstitutesView])
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    private lazy var substitutesStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [substitutesTitleLabel, substitutesColumnsStackView])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            summaryStackView,
            startersTitleLabel,
            pitchView,
            substitutesContainerView
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.sectionSpacing
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
        homeSummaryView.prepareForReuse()
        awaySummaryView.prepareForReuse()
        pitchView.prepareForReuse()
        homeSubstitutesView.prepareForReuse()
        awaySubstitutesView.prepareForReuse()
        substitutesContainerView.isHidden = true
    }

    // MARK: - Configuration

    func configure(with viewData: SoccerMatchDetailLineupsSectionViewData) {
        homeSummaryView.configure(with: viewData.homeTeam)
        awaySummaryView.configure(with: viewData.awayTeam)
        pitchView.configure(
            homeRows: viewData.homeTeam.formationRows,
            awayRows: viewData.awayTeam.formationRows
        )

        substitutesContainerView.isHidden = !viewData.hasSubstitutes
        homeSubstitutesView.configure(
            teamName: viewData.homeTeam.name,
            players: viewData.homeTeam.substitutes
        )
        awaySubstitutesView.configure(
            teamName: viewData.awayTeam.name,
            players: viewData.awayTeam.substitutes
        )

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateResponsiveLayout(for: bounds.width)
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        updateResponsiveLayout(for: layoutAttributes.frame.width)

        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let fittingSize = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        attributes.frame.size.height = ceil(fittingSize.height)
        return attributes
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = .secondaryBackgroundColor
        contentView.layer.cornerRadius = LayoutMetric.cornerRadius
        contentView.layer.masksToBounds = true

        contentView.addSubview(contentStackView)
        substitutesContainerView.addSubview(substitutesStackView)

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

        substitutesStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func updateResponsiveLayout(for width: CGFloat) {
        let usesVerticalColumns = width > 0 && width < LayoutMetric.compactWidth
        summaryStackView.axis = usesVerticalColumns ? .vertical : .horizontal
        summaryStackView.distribution = usesVerticalColumns ? .fill : .fillEqually

        substitutesColumnsStackView.axis = usesVerticalColumns ? .vertical : .horizontal
        substitutesColumnsStackView.distribution = usesVerticalColumns ? .fill : .fillEqually
    }

    private static func makeSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        label.numberOfLines = 1
        return label
    }
}

// MARK: - SoccerMatchLineupTeamSummaryView

private final class SoccerMatchLineupTeamSummaryView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let badgeHorizontalInset: CGFloat = 8
        static let badgeVerticalInset: CGFloat = 4
        static let contentSpacing: CGFloat = 8
        static let badgeCornerRadius: CGFloat = 8
    }

    // MARK: - UI Components

    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private let formationBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemFill
        view.layer.cornerRadius = LayoutMetric.badgeCornerRadius
        return view
    }()

    private let formationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let coachLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [teamNameLabel, formationBadgeView, coachLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
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

    // MARK: - Configuration

    func prepareForReuse() {
        teamNameLabel.text = nil
        formationLabel.text = nil
        coachLabel.text = nil
        formationBadgeView.isHidden = true
        coachLabel.isHidden = true
    }

    func configure(with viewData: SoccerMatchLineupTeamViewData) {
        teamNameLabel.text = viewData.name
        configureFormationBadge(text: viewData.formationText)
        configureCoachLabel(text: viewData.coachText)
    }

    private func configureFormationBadge(text: String?) {
        guard let text, !text.isEmpty else {
            formationLabel.text = nil
            formationBadgeView.isHidden = true
            return
        }

        formationLabel.text = text
        formationBadgeView.isHidden = false
    }

    private func configureCoachLabel(text: String?) {
        guard let text, !text.isEmpty else {
            coachLabel.text = nil
            coachLabel.isHidden = true
            return
        }

        coachLabel.text = text
        coachLabel.isHidden = false
    }

    // MARK: - Setup

    private func setupView() {
        formationBadgeView.addSubview(formationLabel)
        addSubview(stackView)

        formationLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: LayoutMetric.badgeVerticalInset,
                    left: LayoutMetric.badgeHorizontalInset,
                    bottom: LayoutMetric.badgeVerticalInset,
                    right: LayoutMetric.badgeHorizontalInset
                )
            )
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        formationBadgeView.setContentHuggingPriority(.required, for: .horizontal)
    }
}

// MARK: - SoccerMatchLineupPitchView

private final class SoccerMatchLineupPitchView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 12
        static let verticalInset: CGFloat = 16
        static let rowSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 16
        static let centerDividerHeight: CGFloat = 40
        static let centerCircleSize: CGFloat = 40
        static let penaltyBoxWidth: CGFloat = 120
        static let penaltyBoxHeight: CGFloat = 36
        static let cornerRadius: CGFloat = 12
    }

    // MARK: - UI Components

    private let topPenaltyBoxView = SoccerMatchLineupPitchView.makeFieldLineView()
    private let bottomPenaltyBoxView = SoccerMatchLineupPitchView.makeFieldLineView()
    private let centerLineView = SoccerMatchLineupPitchView.makeFieldLineView()
    private let centerCircleView = SoccerMatchLineupPitchView.makeFieldCircleView()
    private let centerDividerView = UIView()

    private lazy var awayRowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.rowSpacing
        return stackView
    }()

    private lazy var homeRowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.rowSpacing
        return stackView
    }()

    private lazy var fieldStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            awayRowsStackView,
            centerDividerView,
            homeRowsStackView
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.sectionSpacing
        return stackView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func prepareForReuse() {
        awayRowsStackView.removeAllArrangedSubviews()
        homeRowsStackView.removeAllArrangedSubviews()
        awayRowsStackView.isHidden = false
        homeRowsStackView.isHidden = false
        centerDividerView.isHidden = false
    }

    func configure(
        homeRows: [SoccerMatchLineupFormationRowViewData],
        awayRows: [SoccerMatchLineupFormationRowViewData]
    ) {
        prepareForReuse()

        awayRows.forEach { row in
            awayRowsStackView.addArrangedSubview(SoccerMatchLineupFormationRowView(row: row))
        }

        homeRows.reversed().forEach { row in
            homeRowsStackView.addArrangedSubview(SoccerMatchLineupFormationRowView(row: row))
        }

        awayRowsStackView.isHidden = awayRows.isEmpty
        homeRowsStackView.isHidden = homeRows.isEmpty
        centerDividerView.isHidden = awayRows.isEmpty || homeRows.isEmpty
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }

    // MARK: - Setup

    private func setupView() {
        layer.cornerRadius = LayoutMetric.cornerRadius
        layer.masksToBounds = true

        addSubview(topPenaltyBoxView)
        addSubview(bottomPenaltyBoxView)
        addSubview(fieldStackView)
        centerDividerView.addSubview(centerLineView)
        centerDividerView.addSubview(centerCircleView)

        topPenaltyBoxView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(LayoutMetric.penaltyBoxWidth)
            make.height.equalTo(LayoutMetric.penaltyBoxHeight)
        }

        bottomPenaltyBoxView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(LayoutMetric.penaltyBoxWidth)
            make.height.equalTo(LayoutMetric.penaltyBoxHeight)
        }

        fieldStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: LayoutMetric.verticalInset,
                    left: LayoutMetric.horizontalInset,
                    bottom: LayoutMetric.verticalInset,
                    right: LayoutMetric.horizontalInset
                )
            )
        }

        centerDividerView.snp.makeConstraints { make in
            make.height.equalTo(LayoutMetric.centerDividerHeight)
        }

        centerLineView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(1)
        }

        centerCircleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(LayoutMetric.centerCircleSize)
        }
    }

    private func updateColors() {
        backgroundColor = UIColor.systemGreen.withAlphaComponent(0.18)
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.28).cgColor
    }

    private static func makeFieldLineView() -> UIView {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.44).cgColor
        return view
    }

    private static func makeFieldCircleView() -> UIView {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.44).cgColor
        view.layer.cornerRadius = LayoutMetric.centerCircleSize / 2
        return view
    }
}

// MARK: - SoccerMatchLineupFormationRowView

private final class SoccerMatchLineupFormationRowView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let titleBottomSpacing: CGFloat = 4
        static let playerSpacing: CGFloat = 4
    }

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private lazy var playersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = LayoutMetric.playerSpacing
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, playersStackView])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.titleBottomSpacing
        return stackView
    }()

    // MARK: - Initialization

    init(row: SoccerMatchLineupFormationRowViewData) {
        super.init(frame: .zero)
        setupView()
        configure(with: row)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    private func configure(with row: SoccerMatchLineupFormationRowViewData) {
        titleLabel.text = row.title
        row.players.forEach { player in
            playersStackView.addArrangedSubview(SoccerMatchLineupPlayerChipView(player: player))
        }
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - SoccerMatchLineupPlayerChipView

private final class SoccerMatchLineupPlayerChipView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let contentInset: CGFloat = 4
        static let contentSpacing: CGFloat = 4
        static let numberSize: CGFloat = 24
        static let minimumHeight: CGFloat = 64
        static let cornerRadius: CGFloat = 8
    }

    // MARK: - UI Components

    private let numberContainerView = UIView()

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.backgroundColor = .systemBackground
        label.layer.cornerRadius = LayoutMetric.numberSize / 2
        label.layer.masksToBounds = true
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.78
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [numberContainerView, nameLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.contentSpacing
        return stackView
    }()

    // MARK: - Initialization

    init(player: SoccerMatchLineupPlayerViewData) {
        super.init(frame: .zero)
        setupView()
        configure(with: player)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    private func configure(with player: SoccerMatchLineupPlayerViewData) {
        numberLabel.text = player.numberText ?? "-"
        nameLabel.text = player.shortDisplayName
        accessibilityLabel = [
            player.displayName,
            player.numberText,
            player.positionText
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.82)
        layer.cornerRadius = LayoutMetric.cornerRadius
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.withAlphaComponent(0.24).cgColor
        isAccessibilityElement = true

        addSubview(stackView)
        numberContainerView.addSubview(numberLabel)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LayoutMetric.contentInset)
            make.height.greaterThanOrEqualTo(LayoutMetric.minimumHeight)
        }

        numberLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(LayoutMetric.numberSize)
        }
    }
}

// MARK: - SoccerMatchLineupSubstituteListView

private final class SoccerMatchLineupSubstituteListView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let contentSpacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.text = "No substitutes"
        return label
    }()

    private lazy var playersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = LayoutMetric.contentSpacing
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [teamNameLabel, playersStackView])
        stackView.axis = .vertical
        stackView.alignment = .fill
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

    // MARK: - Configuration

    func prepareForReuse() {
        teamNameLabel.text = nil
        playersStackView.removeAllArrangedSubviews()
    }

    func configure(
        teamName: String,
        players: [SoccerMatchLineupPlayerViewData]
    ) {
        prepareForReuse()
        teamNameLabel.text = teamName

        guard !players.isEmpty else {
            playersStackView.addArrangedSubview(emptyLabel)
            return
        }

        players.forEach { player in
            playersStackView.addArrangedSubview(SoccerMatchLineupSubstituteRowView(player: player))
        }
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - SoccerMatchLineupSubstituteRowView

private final class SoccerMatchLineupSubstituteRowView: UIView {

    // MARK: - Layout Metrics

    private enum LayoutMetric {
        static let horizontalInset: CGFloat = 8
        static let verticalInset: CGFloat = 8
        static let contentSpacing: CGFloat = 8
        static let numberWidth: CGFloat = 36
        static let minimumHeight: CGFloat = 40
        static let cornerRadius: CGFloat = 8
    }

    // MARK: - UI Components

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.82
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .primaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private let positionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.textAlignment = .right
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [numberLabel, nameLabel, positionLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = LayoutMetric.contentSpacing
        return stackView
    }()

    // MARK: - Initialization

    init(player: SoccerMatchLineupPlayerViewData) {
        super.init(frame: .zero)
        setupView()
        configure(with: player)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    private func configure(with player: SoccerMatchLineupPlayerViewData) {
        numberLabel.text = player.numberText ?? "-"
        nameLabel.text = player.displayName
        positionLabel.text = player.positionText
        positionLabel.isHidden = player.positionText == nil
        accessibilityLabel = [
            player.displayName,
            player.numberText,
            player.positionText
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .secondarySystemFill
        layer.cornerRadius = LayoutMetric.cornerRadius
        isAccessibilityElement = true

        addSubview(stackView)

        numberLabel.snp.makeConstraints { make in
            make.width.equalTo(LayoutMetric.numberWidth)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: LayoutMetric.verticalInset,
                    left: LayoutMetric.horizontalInset,
                    bottom: LayoutMetric.verticalInset,
                    right: LayoutMetric.horizontalInset
                )
            )
            make.height.greaterThanOrEqualTo(LayoutMetric.minimumHeight)
        }
    }
}

// MARK: - UIStackView Convenience

private extension UIStackView {

    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach { view in
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}
