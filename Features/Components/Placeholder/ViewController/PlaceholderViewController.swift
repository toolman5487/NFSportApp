//
//  PlaceholderViewController.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import SkeletonView
import SnapKit
import UIKit

@MainActor
final class PlaceholderViewController: UIViewController, TabBarRootViewController, TabBarContentScrollable, TabBarRootReselectHandling {

    // MARK: - Section

    private enum Section: Int, CaseIterable {
        case header
        case banner
        case sectionTitle
        case list

        var rowCount: Int {
            switch self {
            case .header, .banner, .sectionTitle:
                return 1
            case .list:
                return 4
            }
        }

        var rowHeight: CGFloat {
            switch self {
            case .header:
                return 80
            case .banner:
                return 160
            case .sectionTitle:
                return 36
            case .list:
                return 88
            }
        }
    }

    // MARK: - Properties

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .backgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderTopPadding = 0
        return tableView
    }()

    private let placeholderTitle: String
    private let itemConfiguration: TabBarItemConfiguration

    var tabBarItemConfiguration: TabBarItemConfiguration {
        itemConfiguration
    }

    var isScrolledAwayFromTop: Bool {
        tableView.contentOffset.y > -tableView.adjustedContentInset.top
    }

    // MARK: - Initialization

    init(
        title: String = "",
        tabBarItemConfiguration: TabBarItemConfiguration
    ) {
        self.placeholderTitle = title
        self.itemConfiguration = tabBarItemConfiguration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()
        tableView.showAnimatedGradientSkeleton()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableView.hideSkeleton()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .backgroundColor
        title = placeholderTitle

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PlaceholderHeaderCell.self, forCellReuseIdentifier: PlaceholderHeaderCell.reuseIdentifier)
        tableView.register(PlaceholderBannerCell.self, forCellReuseIdentifier: PlaceholderBannerCell.reuseIdentifier)
        tableView.register(PlaceholderSectionTitleCell.self, forCellReuseIdentifier: PlaceholderSectionTitleCell.reuseIdentifier)
        tableView.register(PlaceholderListCell.self, forCellReuseIdentifier: PlaceholderListCell.reuseIdentifier)
    }

    func scrollToTop(animated: Bool) {
        let topContentOffset = CGPoint(
            x: 0,
            y: -tableView.adjustedContentInset.top
        )
        tableView.setContentOffset(topContentOffset, animated: animated)
    }
}

// MARK: - UITableViewDataSource

extension PlaceholderViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }

        return section.rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch section {
        case .header:
            return tableView.dequeueReusableCell(
                withIdentifier: PlaceholderHeaderCell.reuseIdentifier,
                for: indexPath
            )
        case .banner:
            return tableView.dequeueReusableCell(
                withIdentifier: PlaceholderBannerCell.reuseIdentifier,
                for: indexPath
            )
        case .sectionTitle:
            return tableView.dequeueReusableCell(
                withIdentifier: PlaceholderSectionTitleCell.reuseIdentifier,
                for: indexPath
            )
        case .list:
            return tableView.dequeueReusableCell(
                withIdentifier: PlaceholderListCell.reuseIdentifier,
                for: indexPath
            )
        }
    }
}

// MARK: - UITableViewDelegate

extension PlaceholderViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else {
            return 0
        }

        return section.rowHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let section = Section(rawValue: section), section != .list else {
            return 0
        }

        return 16
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}

// MARK: - PlaceholderHeaderCell

private final class PlaceholderHeaderCell: UITableViewCell {

    static let reuseIdentifier = "PlaceholderHeaderCell"

    private let avatarSkeletonView = SkeletonPlaceholderFactory.makeSkeletonView(cornerRadius: 24)
    private let titleSkeletonView = SkeletonPlaceholderFactory.makeSkeletonView()
    private let subtitleSkeletonView = SkeletonPlaceholderFactory.makeSkeletonView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear

        let textStackView = UIStackView(arrangedSubviews: [titleSkeletonView, subtitleSkeletonView])
        textStackView.axis = .vertical
        textStackView.spacing = 8
        textStackView.alignment = .leading

        contentView.addSubview(avatarSkeletonView)
        contentView.addSubview(textStackView)

        avatarSkeletonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }

        textStackView.snp.makeConstraints { make in
            make.leading.equalTo(avatarSkeletonView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        titleSkeletonView.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.width.equalTo(160)
        }

        subtitleSkeletonView.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.width.equalTo(120)
        }
    }
}

// MARK: - PlaceholderBannerCell

private final class PlaceholderBannerCell: UITableViewCell {

    static let reuseIdentifier = "PlaceholderBannerCell"

    private let bannerSkeletonView = SkeletonPlaceholderFactory.makeSkeletonView(cornerRadius: 12)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(bannerSkeletonView)
        bannerSkeletonView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
    }
}

// MARK: - PlaceholderSectionTitleCell

private final class PlaceholderSectionTitleCell: UITableViewCell {

    static let reuseIdentifier = "PlaceholderSectionTitleCell"

    private let titleSkeletonView = SkeletonPlaceholderFactory.makeSkeletonView(cornerRadius: 4)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(titleSkeletonView)
        titleSkeletonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
            make.width.equalTo(120)
        }
    }
}

// MARK: - PlaceholderListCell

private final class PlaceholderListCell: UITableViewCell {

    static let reuseIdentifier = "PlaceholderListCell"

    private let thumbnailSkeletonView = SkeletonPlaceholderFactory.makeSkeletonView(cornerRadius: 8)
    private let titleSkeletonView = SkeletonPlaceholderFactory.makeSkeletonView()
    private let subtitleSkeletonView = SkeletonPlaceholderFactory.makeSkeletonView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear

        let textStackView = UIStackView(arrangedSubviews: [titleSkeletonView, subtitleSkeletonView])
        textStackView.axis = .vertical
        textStackView.spacing = 8
        textStackView.alignment = .leading

        contentView.addSubview(thumbnailSkeletonView)
        contentView.addSubview(textStackView)

        thumbnailSkeletonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(72)
        }

        textStackView.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailSkeletonView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        titleSkeletonView.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.width.equalToSuperview().multipliedBy(0.72)
        }

        subtitleSkeletonView.snp.makeConstraints { make in
            make.height.equalTo(12)
            make.width.equalToSuperview().multipliedBy(0.48)
        }
    }
}

// MARK: - SkeletonPlaceholderFactory

private enum SkeletonPlaceholderFactory {

    static func makeSkeletonView(cornerRadius: Float = 8) -> UIView {
        let view = UIView()
        view.isSkeletonable = true
        view.skeletonCornerRadius = cornerRadius
        view.layer.cornerRadius = CGFloat(cornerRadius)
        view.layer.masksToBounds = true
        view.backgroundColor = .secondaryBackgroundColor
        return view
    }
}
