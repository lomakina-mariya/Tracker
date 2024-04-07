import Foundation
import UIKit

protocol NewHabitOrEventViewControllerDelegate: AnyObject {
    func addNewTracker(newTracker: TrackerCategory)
}

final class NewHabitOrEventViewController: UIViewController {
    
    //MARK: - Properties
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
    }
    
    // MARK: - Private Function
    private func addElements(){
        view.addSubview(trackerNameInput)
        view.addSubview(restrictiveLabel)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
        view.addSubview(trackerProperties)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            trackerNameInput.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            trackerNameInput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            trackerNameInput.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            trackerNameInput.heightAnchor.constraint(equalToConstant: 75),
            
            restrictiveLabel.topAnchor.constraint(equalTo: trackerNameInput.bottomAnchor, constant: 8),
            restrictiveLabel.leadingAnchor.constraint(equalTo: trackerNameInput.leadingAnchor, constant: 28),
            restrictiveLabel.trailingAnchor.constraint(equalTo: trackerNameInput.trailingAnchor, constant: -28),
            restrictiveLabel.heightAnchor.constraint(equalToConstant: 22),
            
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.rightAnchor.constraint(equalTo: createButton.leftAnchor, constant: -8),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            
            trackerProperties.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            trackerProperties.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            trackerProperties.topAnchor.constraint(equalTo: restrictiveLabel.bottomAnchor, constant: 24),
            trackerProperties.heightAnchor.constraint(equalToConstant: eventMode ? 75 : 150)
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
            color: self.color ?? .ColorSelection17,
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
