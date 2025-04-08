//
//  ViewController.swift
//  WepinWidget
//
//  Created by hyunjung on 03/10/2025.
//  Copyright (c) 2025 hyunjung. All rights reserved.
//

import UIKit
import WepinLogin
import WepinWidget // WepinWidgetManager가 포함된 모듈

class ViewController: UIViewController {
    // WepinWidget 인스턴스 및 설정값들
    var wepinWidget: WepinWidget?
    var selectedLanguage: String = "en"
    
    var appId: String = "WEPIN_APP_ID"
    var appKey: String = "WEPIN_APP_KEY"
    
    var lifecycle: WepinLifeCycle = .notInitialized
    
    // Login Provider 정보
    let providerInfos: [LoginProviderInfo] = [
        LoginProviderInfo(provider: "google", clientId: "GOOGLE_CLIENT_ID"),
        LoginProviderInfo(provider: "apple", clientId: "APPLE_CLIENT_ID"),
        LoginProviderInfo(provider: "discord", clientId: "DISCORD_CLIENT_ID"),
        LoginProviderInfo(provider: "naver", clientId: "NAVER_CLIENT_ID"),
        LoginProviderInfo(provider: "facebook", clientId: "FACEBOOK_CLIENT_ID"),
        LoginProviderInfo(provider: "line", clientId: "LINE_CLIENT_ID")
    ]
    ////
    ///
    // UI Components
    var lifecycleView: UILabel!
    var lifecycleIndicator: UIActivityIndicatorView!
    var scrollView: UIScrollView!
    var stackView: UIStackView!
    var settingsContainerView: UIView!
    var statusLabel: UILabel!
    var appIdTextField: UITextField!
    var appKeyTextField: UITextField!
    var languageSegmentedControl: UISegmentedControl!
    
    var allButtons: [UIButton] = []
    var lifecycleButtonMap: [WepinLifeCycle: [UIButton]] = [:]
    
    let buttonConfigs: [(title: String, selector: Selector, lifecycle: [WepinLifeCycle])] = [
        ("Initialize", #selector(initializeTapped), [.notInitialized, .initializing]),
        ("Check Initialization Status", #selector(checkInitStatusTapped), [.notInitialized, .initializing, .initialized, .loginBeforeRegister, .login, .beforeLogin]),
        ("LoginWithUI", #selector(loginWithUITapped), [.initialized]),
        ("LoginWithUI (with Email)", #selector(loginWithUIWithEmailTapped), [.initialized]),
        ("LoginWithUI (with Providers)", #selector(loginWithUIProvidersTapped), [.initialized]),
        ("Register", #selector(registerTapped), [.loginBeforeRegister]),
        ("Open Widget", #selector(openWidgetTapped), [.login]),
        ("Get Account", #selector(getAccountTapped), [.login]),
        ("Get Balance", #selector(getBalanceTapped), [.login]),
        ("Get NFTs", #selector(getNFTsTapped), [.login]),
        ("Get NFTs (Refresh)", #selector(getNFTsRefreshTapped), [.login]),
        ("Select Account & Send", #selector(selectAccountSendTapped), [.login]),
        ("Select Account & Receive", #selector(selectAccountReceiveTapped), [.login]),
        ("CloseWidget", #selector(closeWidgetTapped), [.login]),
        ("Logout", #selector(logoutTapped), [.loginBeforeRegister, .login]),
        ("GetStatus", #selector(getStatusTapped), [.initializing, .initialized, .login, .loginBeforeRegister, .beforeLogin]),
        ("Finalize", #selector(finalizeTapped), [.initializing, .initialized, .login, .loginBeforeRegister, .beforeLogin]),
    ]

    
    // 상태 및 계정 선택 관련 변수
    var settingsIsVisible: Bool = false
    var fetchedAccounts: [WepinAccount] = []
    var currentActionType: ActionType? = nil
    
    enum ActionType {
        case send, receive
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = .white
        // UI 구성
        setupUI()
        // 초기 설정 시 wepinWidget 생성 (Apply Changes 버튼을 누르기 전까지는 nil일 수 있음)
        let params = WepinWidgetParams(viewController: self, appId: appId, appKey: appKey)
        do {
            wepinWidget = try WepinWidget(wepinWidgetParams: params)
        } catch {
            updateStatus("WepinWidget init error: \(error.localizedDescription)")
        }
        updateLifecycleUI(status: lifecycle)
    }
    
    func setupUI() {
        // 상단 영역: 버튼 및 설정 패널이 포함된 스크롤 가능한 컨테이너 (화면의 50% 차지)
        let topContainer = UIView()
        topContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topContainer)
        
        // 하단 영역: 상태 레이블이 위치할 컨테이너
        let bottomContainer = UIView()
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomContainer)
        
        NSLayoutConstraint.activate([
            // 상단 영역: safeArea의 top부터 view의 50% 높이까지
            topContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            // 하단 영역: 상단 컨테이너 바로 아래부터 safeArea의 bottom까지
            bottomContainer.topAnchor.constraint(equalTo: topContainer.bottomAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let topFixedStack = UIStackView()
        topFixedStack.axis = .vertical
        topFixedStack.spacing = 8
        topFixedStack.translatesAutoresizingMaskIntoConstraints = false
        topContainer.addSubview(topFixedStack)
        
        NSLayoutConstraint.activate([
            topFixedStack.topAnchor.constraint(equalTo: topContainer.topAnchor),
            topFixedStack.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor),
            topFixedStack.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor),
        ])
        
        // 상단 영역에 기존 UI 구성 요소 추가
        // 타이틀 레이블
        let titleLabel = UILabel()
        titleLabel.text = "Wepin Widget Test"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        topFixedStack.addArrangedSubview(titleLabel)
        
        let lifecycleStack = UIStackView()
        lifecycleStack.axis = .horizontal
        lifecycleStack.alignment = .center
        lifecycleStack.spacing = 8
        lifecycleStack.translatesAutoresizingMaskIntoConstraints = false
        
        lifecycleView = UILabel()
        lifecycleView.text = "Lifecycle: Not Initialized"
        lifecycleView.font = UIFont.systemFont(ofSize: 14)
        lifecycleView.textAlignment = .center
        lifecycleView.textColor = .darkGray
        
        lifecycleIndicator = UIActivityIndicatorView(activityIndicatorStyle: .medium)
        lifecycleIndicator.hidesWhenStopped = true
        lifecycleIndicator.stopAnimating()
        
        lifecycleStack.addArrangedSubview(lifecycleView)
        lifecycleStack.addArrangedSubview(lifecycleIndicator)
        
        topFixedStack.addArrangedSubview(lifecycleStack)
        
        
        // 상단 컨테이너 내부에 스크롤뷰 추가
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        topContainer.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topFixedStack.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: topContainer.bottomAnchor)
        ])
        
        // 스크롤뷰 내에 버튼 및 설정 패널을 담을 스택뷰 추가
        let buttonStackView = UIStackView()
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 16
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            buttonStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        
        
        // 설정 패널 토글 버튼
        let toggleSettingsButton = UIButton(type: .system)
        toggleSettingsButton.setTitle("Open Settings", for: .normal)
        toggleSettingsButton.addTarget(self, action: #selector(toggleSettings(_:)), for: .touchUpInside)
        buttonStackView.addArrangedSubview(toggleSettingsButton)
        
        // 설정 패널 뷰 (기존 구성과 동일)
        settingsContainerView = UIView()
        settingsContainerView.backgroundColor = .white
        settingsContainerView.layer.cornerRadius = 8
        settingsContainerView.layer.shadowColor = UIColor.black.cgColor
        settingsContainerView.layer.shadowOpacity = 0.2
        settingsContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        settingsContainerView.isHidden = true
        settingsContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        let settingsStack = UIStackView()
        settingsStack.axis = .vertical
        settingsStack.spacing = 8
        settingsStack.translatesAutoresizingMaskIntoConstraints = false
        settingsContainerView.addSubview(settingsStack)
        NSLayoutConstraint.activate([
            settingsStack.topAnchor.constraint(equalTo: settingsContainerView.topAnchor, constant: 16),
            settingsStack.leadingAnchor.constraint(equalTo: settingsContainerView.leadingAnchor, constant: 16),
            settingsStack.trailingAnchor.constraint(equalTo: settingsContainerView.trailingAnchor, constant: -16),
            settingsStack.bottomAnchor.constraint(equalTo: settingsContainerView.bottomAnchor, constant: -16)
        ])
        
        let settingsTitle = UILabel()
        settingsTitle.text = "Settings"
        settingsTitle.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        settingsStack.addArrangedSubview(settingsTitle)
        
        let languageLabel = UILabel()
        languageLabel.text = "Select Language"
        settingsStack.addArrangedSubview(languageLabel)
        
        languageSegmentedControl = UISegmentedControl(items: ["en", "ko", "ja"])
        languageSegmentedControl.selectedSegmentIndex = 0
        languageSegmentedControl.addTarget(self, action: #selector(languageChanged(_:)), for: .valueChanged)
        settingsStack.addArrangedSubview(languageSegmentedControl)
        
        let appIdLabel = UILabel()
        appIdLabel.text = "App ID"
        settingsStack.addArrangedSubview(appIdLabel)
        
        appIdTextField = UITextField()
        appIdTextField.borderStyle = .roundedRect
        appIdTextField.text = appId
        settingsStack.addArrangedSubview(appIdTextField)
        
        let appKeyLabel = UILabel()
        appKeyLabel.text = "App Key"
        settingsStack.addArrangedSubview(appKeyLabel)
        
        appKeyTextField = UITextField()
        appKeyTextField.borderStyle = .roundedRect
        appKeyTextField.text = appKey
        settingsStack.addArrangedSubview(appKeyTextField)
        
        let applyChangesButton = UIButton(type: .system)
        applyChangesButton.setTitle("Apply Changes", for: .normal)
        applyChangesButton.addTarget(self, action: #selector(applySettings), for: .touchUpInside)
        settingsStack.addArrangedSubview(applyChangesButton)
        
        buttonStackView.addArrangedSubview(settingsContainerView)
        
        func createFunctionButton(title: String, action: Selector) -> UIButton {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.layer.cornerRadius = 8
            button.backgroundColor = .systemBlue
            button.tintColor = .white
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.addTarget(self, action: action, for: .touchUpInside)
            return button
        }
        
        for config in buttonConfigs {
            let button = createFunctionButton(title: config.title, action: config.selector)
            allButtons.append(button)
            buttonStackView.addArrangedSubview(button)
            for lifecycle in config.lifecycle {
                lifecycleButtonMap[lifecycle, default: []].append(button)
            }
        }
        
        // ✅ ScrollView 추가 (하단)
        let textWrapperScrollView = UIScrollView()
        textWrapperScrollView.translatesAutoresizingMaskIntoConstraints = false
        textWrapperScrollView.layer.borderColor = UIColor.lightGray.cgColor
        textWrapperScrollView.layer.borderWidth = 1
        textWrapperScrollView.layer.cornerRadius = 8
        textWrapperScrollView.clipsToBounds = true
        bottomContainer.addSubview(textWrapperScrollView)

        // ✅ Label 추가
        statusLabel = UILabel()
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.textColor = .black
        statusLabel.text = "Status: Not Initialized"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        textWrapperScrollView.addSubview(statusLabel)

        // ✅ AutoLayout 설정
        NSLayoutConstraint.activate([
            // ScrollView Constraints
            textWrapperScrollView.topAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: 8),
            textWrapperScrollView.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 16),
            textWrapperScrollView.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -16),
            textWrapperScrollView.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor, constant: -8),
            
            // Label Constraints (ScrollView Content)
            statusLabel.topAnchor.constraint(equalTo: textWrapperScrollView.topAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: textWrapperScrollView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: textWrapperScrollView.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: textWrapperScrollView.bottomAnchor),
            statusLabel.widthAnchor.constraint(equalTo: textWrapperScrollView.widthAnchor)
        ])
    }
    
    func runWithLifecycleRefresh(_ task: @escaping () async throws -> Void) {
        Task {
            do {
                try await task()
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
            _ = await refreshStatus()
        }
    }
    
    // MARK: - UI 액션 처리
    @objc func toggleSettings(_ sender: UIButton) {
        settingsIsVisible.toggle()
        settingsContainerView.isHidden = !settingsIsVisible
        let newTitle = settingsIsVisible ? "Close Settings" : "Open Settings"
        sender.setTitle(newTitle, for: .normal)
    }
    
    @objc func languageChanged(_ sender: UISegmentedControl) {
        if let language = sender.titleForSegment(at: sender.selectedSegmentIndex) {
            selectedLanguage = language
            // WepinWidget에 changeLanguage 기능이 있다면 호출 (SDK 문서에 맞게 수정)
            wepinWidget?.changeLanguage(language)
        }
    }
    
    @objc func applySettings() {
        // 텍스트필드의 값으로 설정값 갱신
        appId = appIdTextField.text ?? appId
        appKey = appKeyTextField.text ?? appKey
        let params = WepinWidgetParams(viewController: self, appId: appId, appKey: appKey)
        do {
            wepinWidget = try WepinWidget(wepinWidgetParams: params)
            updateStatus("Settings Applied")
        } catch {
            updateStatus("Error: \(error.localizedDescription)")
        }
    }
    
    @objc func initializeTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil. Apply settings first.")
                return
            }
            let attributes = WepinWidgetAttribute(defaultLanguage: self.selectedLanguage, defaultCurrency: "USD")
            do {
                let result = try await widget.initialize(attributes: attributes)
                self.updateStatus(result ? "Initialized" : "Initialization Failed")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func checkInitStatusTapped() {
        // SDK 내 isInitialized 여부에 따라 상태 확인
        if let widget = wepinWidget, widget.isInitialized() {
            updateStatus("Widget is Initialized")
        } else {
            updateStatus("Not Initialized")
        }
    }
    
    @objc func getStatusTapped() {
        Task {
            let statusResult = await self.refreshStatus()
            updateStatus("Status: \(statusResult)")
        }
    }
    
    func updateLifecycleUI(status: WepinLifeCycle) {
        DispatchQueue.main.async {
            self.lifecycleView.text = "Lifecycle: \(status.rawValue)"

            self.allButtons.forEach { $0.isHidden = true }

            // 해당 상태에 해당하는 버튼만 표시
            self.lifecycleButtonMap[self.lifecycle]?.forEach { $0.isHidden = false }

            // 공통 버튼 always 표시
            self.lifecycleButtonMap[.beforeLogin]?.forEach { $0.isHidden = false }
        }
    }
    
    @objc func loginWithUITapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let user = try await widget.loginWithUI(viewController: self, loginProviders: [])
                self.updateStatus("Logged in: \(user)")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func loginWithUIWithEmailTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let user = try await widget.loginWithUI(viewController: self, loginProviders: [], email: "73cdc13f1535@drmail.in")
                self.updateStatus("Logged in with email: \(user)")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func loginWithUIProvidersTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let user = try await widget.loginWithUI(viewController: self, loginProviders: self.providerInfos)
                self.updateStatus("Logged in (with providers): \(user)")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func registerTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let result = try await widget.register(viewController: self)
                self.updateStatus("Registered: \(result)")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func getAccountTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let accounts = try await widget.getAccounts()
                self.updateStatus("Accounts: \(accounts)")
                self.fetchedAccounts = accounts
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func getBalanceTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let balance = try await widget.getBalance()
                self.updateStatus("Balance: \(balance)")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func getNFTsTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let nfts = try await widget.getNFTs(refresh: false)
                self.updateStatus("NFTs: \(nfts)")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func getNFTsRefreshTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let nfts = try await widget.getNFTs(refresh: true)
                self.updateStatus("NFTs (Refresh): \(nfts)")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func selectAccountSendTapped() {
        currentActionType = .send
        fetchAndShowAccountSelection()
    }
    
    @objc func selectAccountReceiveTapped() {
        currentActionType = .receive
        fetchAndShowAccountSelection()
    }
    
    func fetchAndShowAccountSelection() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let accounts = try await widget.getAccounts()
                self.fetchedAccounts = accounts
                let alert = UIAlertController(title: "Select an Account", message: nil, preferredStyle: .actionSheet)
                for account in accounts {
                    let title = "\(account.network): \(account.address)"
                    let action = UIAlertAction(title: title, style: .default) { _ in
                        self.handleAccountSelection(account: account)
                    }
                    alert.addAction(action)
                }
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(cancel)
                self.present(alert, animated: true)
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func handleAccountSelection(account: WepinAccount) {
        guard let actionType = currentActionType else { return }
        Task {
            guard let widget = wepinWidget else {
                updateStatus("WepinWidget is nil.")
                return
            }
                do {
                    if actionType == .send {
//                        let result = try await widget.send(viewController: self, account: account)
                        let result = try await widget.send(viewController: self, account: account)
                        updateStatus("Send success: \(result)")
                    } else if actionType == .receive {
                        let result = try await widget.receive(viewController: self, account: account)
                        updateStatus("Receive success: \(result)")
                    }
                } catch {
                    updateStatus("Error: \(error.localizedDescription)")
                }
        }
    }
    
    @objc func openWidgetTapped() {
        Task {
            guard let widget = wepinWidget else {
                updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let result = try await widget.openWidget(viewController: self)
                updateStatus(result ? "Widget Opened" : "Open Widget Failed")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func closeWidgetTapped() {
        do {
            try wepinWidget?.closeWidget()
            updateStatus("Widget Closed")
        } catch {
            updateStatus("Error: \(error.localizedDescription)")
        }
    }
    
    @objc func finalizeTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let result = try await widget.finalize()
                self.updateStatus("Finalized: \(result)")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func logoutTapped() {
        runWithLifecycleRefresh {
            guard let widget = self.wepinWidget, let login = widget.login else {
                self.updateStatus("WepinWidget is nil.")
                return
            }
            do {
                let result = try await login.logoutWepin()
                self.updateStatus("Logout: \(result)")
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
    
    private func refreshStatus() async -> WepinLifeCycle {
        lifecycleIndicator.startAnimating()
        
        defer {
            lifecycleIndicator.stopAnimating()
        }
        
        guard let widget = wepinWidget else {
            updateStatus("WepinWidget is nil.")
            self.lifecycle = .notInitialized
            updateLifecycleUI(status: lifecycle)
            return lifecycle
        }
        do {
            let statusResult = try await widget.getStatus()
//            updateStatus("Status: \(statusResult)")
            self.lifecycle = statusResult
            updateLifecycleUI(status: lifecycle)
            return lifecycle
        } catch {
//            updateStatus("Error: \(error.localizedDescription)")
            self.lifecycle = .notInitialized
            updateLifecycleUI(status: lifecycle)
            return lifecycle
        }
    }
        

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

