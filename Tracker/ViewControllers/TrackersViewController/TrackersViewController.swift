
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
    
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var visibleCategories: [TrackerCategory] = []
    private var currentDate = Date()
    private var dataManager = DataManager.mocksTrackers
    
    private lazy var stubImageView: UIImageView = {
        let image = UIImage(named: "stub")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var stubLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var notFoundImageView: UIImageView = {
        let image = UIImage(named: "notFoundImage")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var notFoundLabel: UILabel = {
        let label = UILabel()
        label.text = "Ничего не найдено"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var searchTextField: UISearchTextField = {
        let textField = UISearchTextField()
        textField.textColor = .ypBlack
        textField.tintColor = .ypBlack
        textField.font = .systemFont(ofSize: 17, weight: .medium)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Поиск"
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
        dpicker.tintColor = .ypBlue
        dpicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        dpicker.translatesAutoresizingMaskIntoConstraints = false
        dpicker.heightAnchor.constraint(equalToConstant: 34).isActive = true
        dpicker.widthAnchor.constraint(equalToConstant: 97).isActive = true
        return dpicker
    }()
    
    private lazy var trackersCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(HeaderSectionView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        return collectionView
    }()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .ypWhite
        trackersCollectionView.delegate = self
        trackersCollectionView.dataSource = self
        addElements()
        createNavigationBar()
        setupConstraints()
        reloadData()
        conditionStubs()
        reloadPlaceholder()
        addTapGestureToHideKeyboard()
    }
    
    // MARK: - Private Function
    private func conditionStubs() {
        if categories.isEmpty {
            trackersCollectionView.isHidden = true
            stubLabel.isHidden = false
            stubImageView.isHidden = false
        } else {
            trackersCollectionView.isHidden = false
            stubLabel.isHidden = true
            stubImageView.isHidden = true
            notFoundImageView.isHidden = true
            notFoundLabel.isHidden = true
        }
    }
    
    private func reloadPlaceholder() {
        if !categories.isEmpty && visibleCategories.isEmpty {
            notFoundImageView.isHidden = false
            notFoundLabel.isHidden = false
            stubLabel.isHidden = true
            stubImageView.isHidden = true
        } else {
            notFoundImageView.isHidden = true
            notFoundLabel.isHidden = true
        }
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
            searchTextField.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func addElements(){
        view.addSubview(trackersCollectionView)
        view.addSubview(stubImageView)
        view.addSubview(stubLabel)
        view.addSubview(searchTextField)
        view.addSubview(notFoundImageView)
        view.addSubview(notFoundLabel)
        notFoundImageView.isHidden = true
        notFoundLabel.isHidden = true
    }
    
    private func createNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        navigationBar.topItem?.title = "Трекеры"
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
        categories = dataManager
        datePickerValueChanged()
    }
    
    private func isCompletedToday(id: UUID) -> Bool {
        return completedTrackers.contains {trackerRecord in
            isSameTracker(trackerRecord: trackerRecord, id: id)
        }
    }
    
    private func isSameTracker(trackerRecord: TrackerRecord, id: UUID) -> Bool {
        let isSameDay = Calendar.current.isDate(trackerRecord.date, inSameDayAs: currentDate)
        return trackerRecord.id == id && isSameDay && currentDate <= Date()
    }
    
    private func reloadVisibleCategories(text: String?, date: Date) {
        let calendar = Calendar.current
        let filterWeekday = calendar.component(.weekday, from: date)
        let filterText = (text ?? "").lowercased()
        visibleCategories = categories.compactMap { category in
            let trackers = category.trackers.filter { tracker in
                let textCondition = filterText.isEmpty ||
                tracker.name.lowercased().contains(filterText)
                let dateCondition = tracker.schedule.contains { weekday in
                    weekday?.numberValue == filterWeekday } ||
                tracker.schedule.isEmpty == true &&
                Calendar.current.isDate(tracker.dateEvent!, inSameDayAs: currentDate)
                return textCondition && dateCondition
            }
            if trackers.isEmpty {
                return nil
            }
            return TrackerCategory(
                title: category.title,
                trackers: trackers
            )
        }
        trackersCollectionView.reloadData()
        conditionStubs()
        reloadPlaceholder()
    }
    
    // MARK: - @objc Function
    @objc private func datePickerValueChanged() {
        currentDate = datePicker.date
        reloadVisibleCategories(text: searchTextField.text, date: currentDate)
    }
    
    @objc private func addTask() {
        let createTrackerVC = CreateTrackerViewController()
        createTrackerVC.delegate = self
        let navVC = UINavigationController(rootViewController: createTrackerVC)
        present(navVC, animated: true)
    }
}
// MARK: - Extension UICollectionViewDataSource
extension TrackersViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? HeaderSectionView else { return UICollectionReusableView() }
        let titleCategory = visibleCategories[indexPath.section].title
        view.titleLabel.text = titleCategory
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? TrackerCell else { return UICollectionViewCell() }
        let cellData = visibleCategories
        let tracker = cellData[indexPath.section].trackers[indexPath.row]
        cell.delegate = self
        let isCompletedToday = isCompletedToday(id: tracker.id)
        let completedDays = completedTrackers.filter { $0.id == tracker.id }.count
        cell.configure(with: tracker, isCompletedToday: isCompletedToday, completedDays: completedDays, indexPath: indexPath)
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
        let isCompletedToday = isCompletedToday(id: id)
        if isCompletedToday {
            completedTrackers.removeAll { trackerRecord in
                isSameTracker(trackerRecord: trackerRecord, id: id)
            }
        } else if currentDate <= Date() {
            let trackerRecord = TrackerRecord(id: id, date: currentDate)
            completedTrackers.append(trackerRecord)
        }
        trackersCollectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - Extension CreateTrackerViewControllerDelegate
extension TrackersViewController: CreateTrackerViewControllerDelegate {
    func updateListOfTrackers(newTracker: TrackerCategory) {
        let trackerOrEvent = addDateForEvent(newTracker: newTracker)
        let getExistCategory = categories.filter { $0.title == newTracker.title }
        var updateCategory = [trackerOrEvent]
        if !getExistCategory.isEmpty {
            updateCategory = [TrackerCategory(title: trackerOrEvent.title,
                                              trackers: getExistCategory[0].trackers + trackerOrEvent.trackers)]
        }
        let lastCategories = categories.filter { $0.title != newTracker.title }
        self.categories = lastCategories + updateCategory
        
        reloadVisibleCategories(text: "", date: currentDate)
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


