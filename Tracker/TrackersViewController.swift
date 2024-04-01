
import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - Private Properties
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
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MMMM.yy"
        return formatter
    }()
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var visibleCategories: [TrackerCategory] = []
    private var currentDate = Date()
    private var dataManager = DataManager.mocksTrackers
    
    //MARK: - UI
    
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
        dpicker.widthAnchor.constraint(equalToConstant: 95).isActive = true
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
//        self.addTapGestureToHideKeyboard()
        trackersCollectionView.delegate = self
        trackersCollectionView.dataSource = self
        view.backgroundColor = .ypWhite
        addElements()
        createNavigationBar()
        setupConstraints()
        reloadData()
        conditionStubs()
    }
    
    // MARK: - Private Function
    private func conditionStubs() {
        if visibleCategories.isEmpty {
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
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(trackersCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: collectionParams.leftInset))
        constraints.append(trackersCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: collectionParams.rightInset))
        constraints.append(trackersCollectionView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 34))
        constraints.append(trackersCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
        
        constraints.append(stubImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(stubImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor))
        
        constraints.append(notFoundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(notFoundImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor))
        
        constraints.append(stubLabel.centerXAnchor.constraint(equalTo: stubImageView.centerXAnchor))
        constraints.append(stubLabel.topAnchor.constraint(equalTo: stubImageView.bottomAnchor, constant: 8))
        
        constraints.append(notFoundLabel.centerXAnchor.constraint(equalTo: notFoundImageView.centerXAnchor))
        constraints.append(notFoundLabel.topAnchor.constraint(equalTo: notFoundImageView.bottomAnchor, constant: 8))
        
        constraints.append(searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        constraints.append(searchTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16))
        constraints.append(searchTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16))
        constraints.append(searchTextField.heightAnchor.constraint(equalToConstant: 36))
        
        NSLayoutConstraint.activate(constraints)
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
           return trackerRecord.id == id && isSameDay
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
                    weekday?.numberValue == filterWeekday
                } == true
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
        reloadPlaceholder()
    }
    
    @objc private func datePickerValueChanged() {
        currentDate = datePicker.date
        reloadVisibleCategories(text: searchTextField.text, date: currentDate)
    }
            
    @objc private func addTask() {
        let createTrackerVC = CreateTrackerViewController()
        //createTrackerVC.updateDelegate = self
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

// MARK: - UICollectionViewDelegate
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

// MARK: - UUITextFieldDelegate
extension TrackersViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        reloadVisibleCategories(text: searchTextField.text, date: currentDate)
        return true
    }
}

// MARK: - TrackerCellDelegate
extension TrackersViewController: TrackerCellDelegate {
    func completeTracker(id: UUID, at indexPath: IndexPath) {
        let isCompletedToday = isCompletedToday(id: id)
        if isCompletedToday {
            completedTrackers.removeAll { trackerRecord in
                isSameTracker(trackerRecord: trackerRecord, id: id)
            }
        } else {
            let trackerRecord = TrackerRecord(id: id, date: currentDate)
            completedTrackers.append(trackerRecord)
        }
        trackersCollectionView.reloadItems(at: [indexPath])
    }
}


