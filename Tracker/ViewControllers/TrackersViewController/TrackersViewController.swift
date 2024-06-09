
import UIKit

final class TrackersViewController: UIViewController {
    
    //MARK: - Properties
    private struct CollectionParams {
        let cellCount: Int
        let height: CGFloat
        let leftInset: CGFloat
        let rightInset: CGFloat
        let cellSpacing: CGFloat
        
        init(cellCount: Int, height: CGFloat, leftInset: CGFloat, rightInset: CGFloat, cellSpacing: CGFloat) {
            self.cellCount = cellCount
            self.height = height
            self.leftInset = leftInset
            self.rightInset = rightInset
            self.cellSpacing = cellSpacing
        }
    }
    
    private let collectionParams = CollectionParams(
        cellCount: 2,
        height: 148,
        leftInset: 16,
        rightInset: -16,
        cellSpacing: 9
    )
    
    private var currentDate = Date().dateWithoutTime()
    private var completedFilter: Bool?
    private var trackersIsEmpty: Bool = true {
        didSet {
            conditionStubs()
        }
    }
    private var haveTrackersForToday = false
    private var viewModel: TrackersViewModel
    private var visibleCategories: [TrackerCategory] {
        return viewModel.categories
    }
    private var savedFilter: Filters?
    private lazy var stubImageView: UIImageView = {
        let image = UIImage(named: "stub")
        let imageView = UIImageView(image: image)
        return imageView
    }()
    
    private lazy var stubLabel: UILabel = {
        let label = UILabel()
        label.text = "stubLabel.text".localized
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .ypBlack
        return label
    }()
    
    private lazy var notFoundImageView: UIImageView = {
        let image = UIImage(named: "notFoundImage")
        let imageView = UIImageView(image: image)
        return imageView
    }()
    
    private lazy var notFoundLabel: UILabel = {
        let label = UILabel()
        label.text = "notFoundLabel.text".localized
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .ypBlack
        return label
    }()
    
    private lazy var searchTextField: UISearchTextField = {
        let textField = UISearchTextField()
        textField.textColor = .ypBlack
        textField.tintColor = .ypBlack
        textField.font = .systemFont(ofSize: 17, weight: .medium)
        textField.placeholder = "searchTrackerTextField.placeholder".localized
        if traitCollection.userInterfaceStyle == .dark {
            textField.attributedPlaceholder = NSAttributedString(
                string: "searchTrackerTextField.placeholder".localized,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
                )
        }
        textField.backgroundColor = .clear
        textField.delegate = self
        return textField
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let dpicker = UIDatePicker()
        dpicker.datePickerMode = .date
        dpicker.preferredDatePickerStyle = .compact
        dpicker.locale = Locale(identifier: "ru_RU")
        dpicker.calendar.firstWeekday = 2
        dpicker.layer.cornerRadius = 8
        dpicker.clipsToBounds = true
        dpicker.tintColor = .ypBlue
        dpicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        dpicker.translatesAutoresizingMaskIntoConstraints = false
        dpicker.heightAnchor.constraint(equalToConstant: 34).isActive = true
        dpicker.widthAnchor.constraint(equalToConstant: 97).isActive = true
        return dpicker
    }()
    
    lazy var trackersCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = .ypWhite
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(HeaderSectionView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        return collectionView
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .ypBlue
        button.setTitle("buttonFilters.title".localized, for: .normal)
        button.tintColor = .ypWhite
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.clipsToBounds = true
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    init(viewModel: TrackersViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        
        trackersIsEmpty = visibleCategories.isEmpty
        viewModel.categoriesBinding = { [weak self] _ in
            guard let self = self else { return }
            self.reloadPlaceholder()
            self.trackersCollectionView.reloadData()
        }
        trackersCollectionView.delegate = self
        trackersCollectionView.dataSource = self
        addElements()
        createNavigationBar()
        setupConstraints()
        addTapGestureToHideKeyboard()
        savedFilter = loadFilter()
        useSelectedFilter(selectedFilter: savedFilter ?? Filters.allTrackers)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.screenOpen()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.screenClose()
    }
    
    // MARK: - Private Function
    private func conditionStubs() {
        if trackersIsEmpty {
            trackersCollectionView.isHidden = true
            filterButton.isHidden = true
            stubLabel.isHidden = false
            stubImageView.isHidden = false
        } else {
            trackersCollectionView.isHidden = false
            filterButton.isHidden = false
            stubLabel.isHidden = true
            stubImageView.isHidden = true
            notFoundImageView.isHidden = true
            notFoundLabel.isHidden = true
        }
    }
    
    private func reloadPlaceholder() {
        if !trackersIsEmpty && visibleCategories.isEmpty {
            notFoundImageView.isHidden = false
            notFoundLabel.isHidden = false
            stubLabel.isHidden = true
            stubImageView.isHidden = true
        } else {
            notFoundImageView.isHidden = true
            notFoundLabel.isHidden = true
        }
        haveTrackersForToday = checkTrackersForToday()
        filterButton.isHidden = !haveTrackersForToday
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            trackersCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: collectionParams.leftInset),
            trackersCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: collectionParams.rightInset),
            trackersCollectionView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 34),
            trackersCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            stubImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stubImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            notFoundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notFoundImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            stubLabel.centerXAnchor.constraint(equalTo: stubImageView.centerXAnchor),
            stubLabel.topAnchor.constraint(equalTo: stubImageView.bottomAnchor, constant: 8),
            
            notFoundLabel.centerXAnchor.constraint(equalTo: notFoundImageView.centerXAnchor),
            notFoundLabel.topAnchor.constraint(equalTo: notFoundImageView.bottomAnchor, constant: 8),
            
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            searchTextField.heightAnchor.constraint(equalToConstant: 36),
            
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func addElements(){
        [trackersCollectionView,
         stubImageView,
         stubLabel,
         searchTextField,
         notFoundImageView,
         notFoundLabel,
         filterButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        notFoundImageView.isHidden = true
        notFoundLabel.isHidden = true
    }
    
    private func createNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        navigationBar.topItem?.title = "trackers.title".localized
        navigationBar.prefersLargeTitles = true
        navigationBar.topItem?.largeTitleDisplayMode = .always
        
        let leftButton = UIBarButtonItem(
            image: UIImage(named: "plus"),
            style: .plain,
            target: self,
            action: #selector(self.addTask)
        )
        leftButton.tintColor = .ypBlack
        navigationItem.leftBarButtonItem = leftButton
        
        let rightButton = UIBarButtonItem(customView: datePicker)
        navigationItem.rightBarButtonItem = rightButton
    }
    
    private func reloadData() {
        datePickerValueChanged()
    }
    
    private func reloadVisibleCategories(text: String?, date: Date) {
        viewModel.updateCategories(with: date, text: text ?? "", completedFilter: self.completedFilter)
    }
    
    private func checkStoreIsEmpty() {
        self.trackersIsEmpty = !viewModel.haveTrackers(for: Date.distantPast)
    }
    
    private func checkTrackersForToday() -> Bool {
        return viewModel.haveTrackers(for: currentDate)
    }
    
    private func loadFilter() -> Filters {
        if let savedFilterString = UserDefaults.standard.string(forKey: "selectedFilter"),
           let savedFilter = Filters(rawValue: savedFilterString) {
            return savedFilter
        }
        return Filters.allTrackers
    }
    
    private func showEditingViewController(selectedTracker: Tracker, categoryTitle: String, daysCounter: String) {
        self.viewModel.editButtonTapped()
        let trackerEditViewController = NewHabitOrEventViewController()
        trackerEditViewController.eventMode = selectedTracker.dateEvent != nil
        trackerEditViewController.categoryTitle = categoryTitle
        trackerEditViewController.editingTracker = selectedTracker
        trackerEditViewController.daysCounter = daysCounter
        trackerEditViewController.editingDelegate = self
        let navVC = UINavigationController(rootViewController: trackerEditViewController)
        self.present(navVC, animated: true)
    }
    
    private func showAlert(for selectedTracker: Tracker) {
        let alert = UIAlertController(title: nil, message: "delete.confirmation".localized, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "delete".localized, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.deleteTracker(selectedTracker)
            self.checkStoreIsEmpty()
            self.reloadVisibleCategories(text: "", date: self.currentDate)
        }
    
        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - @objc Function
    @objc private func datePickerValueChanged() {
        currentDate = datePicker.date.dateWithoutTime()
        reloadVisibleCategories(text: searchTextField.text, date: currentDate)
    }
    
    @objc private func addTask() {
        viewModel.addButtonTapped()
        let createTrackerVC = CreateTrackerViewController()
        createTrackerVC.delegate = self
        let navVC = UINavigationController(rootViewController: createTrackerVC)
        present(navVC, animated: true)
    }
    
    @objc private func filterButtonTapped() {
        viewModel.filterButtonTapped()
        let filtersVC = FiltersViewController()
        filtersVC.delegate = self
        filtersVC.selectedFilter = self.savedFilter
        let navVC = UINavigationController(rootViewController: filtersVC)
        present(navVC, animated: true)
    }
}
// MARK: - Extension UICollectionViewDataSource
extension TrackersViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.categories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? HeaderSectionView else { return UICollectionReusableView() }
        let titleCategory = visibleCategories[indexPath.section].title
        view.titleLabel.text = titleCategory
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? TrackerCell else { return UICollectionViewCell() }
        let category = visibleCategories[indexPath.section]
        let tracker = category.trackers[indexPath.row]
        cell.delegate = self
        let completedDays = viewModel.completedDays(for: tracker.id)
        cell.configure(with: tracker, category: category.title, isCompletedToday: completedDays.completed, completedDays: completedDays.number , indexPath: indexPath)
        return cell
    }
}

// MARK: - Extension UICollectionViewDelegate
extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.bounds.width - collectionParams.cellSpacing) / CGFloat(collectionParams.cellCount),
                      height: collectionParams.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionParams.cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let selectedIndexPath = indexPaths.first else { return nil }
        let selectedTrackerCategory = visibleCategories[selectedIndexPath.section]
        let selectedTracker = selectedTrackerCategory.trackers[selectedIndexPath.item]
        let cell = collectionView.cellForItem(at: indexPaths[0]) as? TrackerCell
        
        return UIContextMenuConfiguration(actionProvider:  { _ in
            let title = selectedTrackerCategory.title == "Закрепленные" ? "unpin".localized : "pin".localized
            let pinAction = UIAction(title: title, image: nil) { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.togglePin(selectedTracker)
                //self.reloadVisibleCategories(text: "", date: self.currentDate)
            }
            let editAction = UIAction(title: "edit".localized, image: nil) { [weak self] _ in
                guard let self = self else { return }
                self.showEditingViewController(selectedTracker: selectedTracker, categoryTitle: selectedTrackerCategory.title, daysCounter: cell?.counterLabel.text ?? "")
            }
            let deleteAction = UIAction(title: "delete".localized, image: nil, attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.showAlert(for: selectedTracker)
            }
            return UIMenu(title: "", children: [pinAction, editAction, deleteAction])
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, highlightPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell else { return nil }
        let targetPreview = UITargetedPreview(view: cell.mainView)
        return targetPreview
    }
}

// MARK: - Extension UUITextFieldDelegate
extension TrackersViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        reloadVisibleCategories(text: searchTextField.text, date: currentDate)
        return true
    }
}

// MARK: - Extension TrackerCellDelegate
extension TrackersViewController: TrackerCellDelegate {
    func completeTracker(id: UUID, at indexPath: IndexPath) {
        viewModel.completeTracker(id: id, date: currentDate)
        self.reloadVisibleCategories(text: "", date: currentDate)
    }
}

// MARK: - Extension CreateTrackerViewControllerDelegate
extension TrackersViewController: CreateTrackerViewControllerDelegate, NewHabitOrEventViewControllerDelegate {
    func addNewTracker(newTracker: TrackerCategory) {
        let trackerOrEvent = addDateForEvent(newTracker: newTracker)
        viewModel.addNewTracker(trackerOrEvent.trackers[0], with: trackerOrEvent)
        self.reloadVisibleCategories(text: "", date: currentDate)
        checkStoreIsEmpty()
    }
    
    private func addDateForEvent(newTracker: TrackerCategory) -> TrackerCategory {
        let tracker = newTracker.trackers[0]
        if tracker.schedule.isEmpty {
            var event = tracker
            event.dateEvent = currentDate
            return TrackerCategory(
                title: newTracker.title,
                trackers: [event])
        }
        else { return newTracker }
    }
}

// MARK: - Extension CreateTrackerViewControllerDelegate
extension TrackersViewController: FiltersViewControllerDelegate {
    func useSelectedFilter(selectedFilter: Filters) {
        savedFilter = selectedFilter
        switch selectedFilter {
        case Filters.todayTrackers:
            completedFilter = nil
            datePicker.date = Date()
            self.reloadData()
        case Filters.completedTrackers:
            completedFilter = true
            self.reloadVisibleCategories(text: "", date: currentDate)
        case Filters.unCompletedTrackers:
            completedFilter = false
            self.reloadVisibleCategories(text: "", date: currentDate)
        default:
            completedFilter = nil
            self.reloadData()
        }
    }
 
}
