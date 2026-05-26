//
//  TabBarView.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import SnapKit
import UIKit

struct TabBarSelectionEvent {
    let tab: AppTab
    let isReselection: Bool
}

final class TabBarView: UIView {

    // MARK: - Callbacks

    var onTabSelected: ((TabBarSelectionEvent) -> Void)?

    // MARK: - Properties

    private let feedbackGenerator = UISelectionFeedbackGenerator()

    private let blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemChromeMaterial)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()

    private var buttons: [TabBarButton] = []
    private var selectedTab: AppTab?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    func render(items: [TabBarItemViewData]) {
        selectedTab = items.first { item in
            item.isSelected
        }?.tab

        if buttons.count != items.count {
            rebuildButtons(for: items)
        }

        zip(buttons, items).forEach { button, item in
            button.configure(with: item)
        }
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear

        addSubview(blurView)
        blurView.contentView.addSubview(stackView)

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
    }

    // MARK: - Button Management

    private func rebuildButtons(for items: [TabBarItemViewData]) {
        buttons.forEach { button in
            stackView.removeArrangedSubview(button)
            button.removeFromSuperview()
        }

        buttons = items.map { item in
            let button = TabBarButton()
            button.configure(with: item)
            button.addTarget(self, action: #selector(prepareFeedback), for: .touchDown)
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            return button
        }
    }

    // MARK: - Actions

    @objc
    private func prepareFeedback() {
        handleFeedback(.prepare)
    }

    @objc
    private func handleTap(_ sender: TabBarButton) {
        guard let tab = sender.tab else {
            return
        }

        let isReselection = tab == selectedTab

        if !isReselection {
            handleFeedback(.selectionChanged)
        }

        onTabSelected?(
            TabBarSelectionEvent(
                tab: tab,
                isReselection: isReselection
            )
        )
    }

    // MARK: - Feedback

    private func handleFeedback(_ feedback: TabBarFeedback) {
        switch feedback {
        case .prepare:
            feedbackGenerator.prepare()
        case .selectionChanged:
            feedbackGenerator.selectionChanged()
        }
    }
}

// MARK: - TabBarFeedback

private enum TabBarFeedback {

    case prepare
    case selectionChanged
}
