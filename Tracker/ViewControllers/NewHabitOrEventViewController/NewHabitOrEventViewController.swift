import Foundation
import UIKit

protocol NewHabitOrEventViewControllerDelegate: AnyObject {
    func addNewTracker(newTracker: TrackerCategory)
}

final class NewHabitOrEventViewController: UIViewController {
    //MARK: - Private struct
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
    
    private let collParams = CollectionParams(
        cellCount: 6,
        height: 204,
        leftInset: 18,
        rightInset: 18,
        cellSpacing: 5
    )
    
    //MARK: - View
    private  lazy var trackerNameInput: UITextField = {
        let textField = UITextField()
        textField.textColor = .ypBlack
        textField.tintColor = .ypBlack
        textField.font = .systemFont(ofSize: 17, weight: .regular)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Введите название трекера"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.backgroundColor = .ypLightGray.withAlphaComponent(0.3)
        textField.clipsToBounds = true
        textField.layer.cornerRadius = 16
        textField.delegate = self
        return textField
    }()
    
    private let restrictiveLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.textColor = .ypRed
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private  lazy var createButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .ypGray
        button.isEnabled = false
        button.setTitle("Создать", for: .normal)
        button.tintColor = .ypWhite
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.clipsToBounds = true
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private  lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.setTitle("Отменить", for: .normal)
        button.tintColor = .ypRed
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ypRed.cgColor
        button.clipsToBounds = true
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var trackerProperties: UITableView = {
        let tableView = UITableView()
        tableView.register(TrackerPropertiesCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.layer.masksToBounds = true
        tableView.layer.cornerRadius = 16
        tableView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.textColor = .ypBlack
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emojiCollection: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(EmojiCollectionCell.self, forCellWithReuseIdentifier: "emojiCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let colorLabel: UILabel = {
        let label = UILabel()
        label.text = "Цвет"
        label.textColor = .ypBlack
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var colorCollection: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(ColorCollectionCell.self, forCellWithReuseIdentifier: "colorCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.delaysContentTouches = false
        return scrollView
    }()

    private let contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .ypWhite
        return contentView
    }()
    
    
    //MARK: - Properties
    private let colorArray: [UIColor] = [.CS1, .CS2, .CS3, .CS4, .CS5, .CS6, .CS7, .CS8, .CS9, .CS10, .CS11, .CS12, .CS13, .CS14, .CS15, .CS16, .CS17, .CS18]
    private let emojiArray: [String] = ["🙂", "😻", "🌺", "🐶", "❤️", "😱", "😇", "😡", "🥶", "🤔", "🙌", "🍔", "🥦", "🏓", "🥇", "🎸", "🏝️", "😪"]
    private var isTrackerNameFilled: Bool = false
    private var categoryTitle: String?
    private var color: UIColor?
    private var emoji: String?
    private var schedule: [Weekdays?] = []
    var eventMode: Bool = false
    weak var delegate: NewHabitOrEventViewControllerDelegate?
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .ypWhite
        addElements()
        createNavigationBar()
        setupConstraints()
        addTapGestureToHideKeyboard()
        trackerProperties.dataSource = self
        trackerProperties.delegate = self
        emojiCollection.dataSource = self
        emojiCollection.delegate = self
        colorCollection.dataSource = self
        colorCollection.delegate = self
        emojiCollection.allowsMultipleSelection = false
        colorCollection.allowsMultipleSelection = false
    }
    
    // MARK: - Private Function
    private func addElements(){
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(trackerNameInput)
        contentView.addSubview(restrictiveLabel)
        contentView.addSubview(trackerProperties)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(emojiCollection)
        contentView.addSubview(colorCollection)
        contentView.addSubview(colorLabel)
        contentView.addSubview(cancelButton)
        contentView.addSubview(createButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            trackerNameInput.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 16),
            trackerNameInput.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            trackerNameInput.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            trackerNameInput.heightAnchor.constraint(equalToConstant: 75),
            
            restrictiveLabel.topAnchor.constraint(equalTo: trackerNameInput.bottomAnchor),
            restrictiveLabel.leadingAnchor.constraint(equalTo: trackerNameInput.leadingAnchor, constant: 28),
            restrictiveLabel.trailingAnchor.constraint(equalTo: trackerNameInput.trailingAnchor, constant: -28),
            restrictiveLabel.heightAnchor.constraint(equalToConstant: 22),
            
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.topAnchor.constraint(equalTo: colorCollection.bottomAnchor, constant: 16),
            createButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.rightAnchor.constraint(equalTo: createButton.leftAnchor, constant: -8),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.topAnchor.constraint(equalTo: colorCollection.bottomAnchor, constant: 16),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            trackerProperties.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            trackerProperties.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            trackerProperties.topAnchor.constraint(equalTo: trackerNameInput.bottomAnchor, constant: 24),
            trackerProperties.heightAnchor.constraint(equalToConstant: eventMode ? 75 : 150),
            
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            emojiLabel.topAnchor.constraint(equalTo: trackerProperties.bottomAnchor, constant: 32),
            emojiLabel.widthAnchor.constraint(equalToConstant: 52),
            emojiLabel.heightAnchor.constraint(equalToConstant: 18),
            
            emojiCollection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emojiCollection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emojiCollection.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor),
            emojiCollection.heightAnchor.constraint(equalToConstant: collParams.height),
            
            colorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            colorLabel.topAnchor.constraint(equalTo: emojiCollection.bottomAnchor, constant: 16),
            colorLabel.widthAnchor.constraint(equalToConstant: 48),
            colorLabel.heightAnchor.constraint(equalToConstant: 18),
            
            colorCollection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorCollection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorCollection.topAnchor.constraint(equalTo: colorLabel.bottomAnchor),
            colorCollection.heightAnchor.constraint(equalToConstant: collParams.height),
            
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func createNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        navigationBar.topItem?.title = eventMode ? "Новое нерегулярное событие" : "Новая привычка"
    }
    
    private func checkFullFill() {
        var allFullFill = false
        if eventMode == false {
            allFullFill = !schedule.isEmpty && isTrackerNameFilled
        } else {
            allFullFill = isTrackerNameFilled
        }
        createButton.isEnabled = allFullFill
        createButton.backgroundColor = allFullFill ? .ypBlack : .ypGray
    }
    
    // MARK: - @objc Function
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func createButtonTapped() {
        let newTracker = Tracker(
            id: UUID(),
            name: trackerNameInput.text ?? "",
            color: self.color ?? .CS17,
            emoji: self.emoji ?? "❤️",
            schedule: self.schedule)
        let category = TrackerCategory(
            title: self.categoryTitle ?? "Отдых",
            trackers: [newTracker])
        delegate?.addNewTracker(newTracker: category)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Extension UITableViewDataSource
extension NewHabitOrEventViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventMode ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TrackerPropertiesCell else {
            return UITableViewCell()
        }
        cell.backgroundColor = .ypLightGray.withAlphaComponent(0.3)
        let lastCell = eventMode ? 0 : 1
        if indexPath.row == lastCell {
            cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.width, bottom: 0, right: 0)
        }
        cell.configure(indexPath: indexPath)
        if indexPath.row == 1 {
            let detailsText = schedule.count == 7 ? "Каждый день" : schedule.map { $0!.shortDayName }.joined(separator: ", ")
            cell.setup(detailsText: detailsText)
        }
        cell.delegate = self
        return cell
    }
}

// MARK: - Extension UITableViewDelegate
extension NewHabitOrEventViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        nextButtonTapped(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(75)
    }
}

// MARK: - Extension TrackerPropertiesCellDelegate
extension NewHabitOrEventViewController: TrackerPropertiesCellDelegate {
    func nextButtonTapped(at indexPath: IndexPath) {
        if indexPath.row == 1 {
            let scheduleVC = ScheduleViewController()
            scheduleVC.delegate = self
            scheduleVC.initialSelectedWeekdays = schedule
            let navVC = UINavigationController(rootViewController: scheduleVC)
            present(navVC, animated: true)
        }
    }
}

// MARK: - Extension UITextFieldDelegate
extension NewHabitOrEventViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentText = textField.text else {
            return true
        }
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        isTrackerNameFilled = !newText.isEmpty
        checkFullFill()
        
        let maxLength = 38
        restrictiveLabel.isHidden = newText.count < maxLength
        return newText.count <= maxLength
    }
}

// MARK: - Extension ScheduleViewControllerDelegate
extension NewHabitOrEventViewController: ScheduleViewControllerDelegate {
    func didSelectWeekdays(_ weekdays: [Weekdays]) {
        schedule = weekdays
        schedule.sort { $0?.numberValueRus ?? 0 < $1?.numberValueRus ?? 0 }
        trackerProperties.reloadData()
        checkFullFill()
    }
}

// MARK: - Extension UICollectionViewDataSource
extension NewHabitOrEventViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojiCollection {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emojiCell", for: indexPath) as? EmojiCollectionCell else { return UICollectionViewCell() }
            let emoji = emojiArray[indexPath.row]
            cell.configure(emoji: emoji)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorCell", for: indexPath) as? ColorCollectionCell else { return UICollectionViewCell() }
            let color = colorArray[indexPath.row]
            cell.configure(color: color)
            return cell
        }
    }
}

// MARK: - Extension UICollectionViewDelegate
extension NewHabitOrEventViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: collParams.leftInset, bottom: 24, right: collParams.rightInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingWidth: CGFloat = collParams.leftInset + collParams.rightInset + CGFloat((collParams.cellCount - 1)) * collParams.cellSpacing
        let availableWidth = collectionView.frame.width - paddingWidth
        let cellWidth =  availableWidth / CGFloat(collParams.cellCount)
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collParams.cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if collectionView == emojiCollection {
            emoji = emojiArray[indexPath.row]
            cell?.contentView.backgroundColor = .ypLightGray
        } else {
            color = colorArray[indexPath.row]
            cell?.contentView.layer.borderWidth = 3
            cell?.contentView.layer.borderColor = UIColor.ypGreen.withAlphaComponent(0.3).cgColor
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if collectionView == emojiCollection {
            cell?.contentView.backgroundColor = .ypWhite
        } else {
            color = colorArray[indexPath.row]
            cell?.contentView.layer.borderWidth = 0
            cell?.contentView.layer.borderColor = UIColor.ypGreen.withAlphaComponent(0.3).cgColor
        }
    }
    
}

