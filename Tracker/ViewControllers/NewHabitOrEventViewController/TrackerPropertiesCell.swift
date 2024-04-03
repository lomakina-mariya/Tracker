
import Foundation
import UIKit

protocol TrackerPropertiesCellDelegate: AnyObject {
    func nextButtonTapped(at indexPath: IndexPath)
}

final class TrackerPropertiesCell: UITableViewCell {
    
    //MARK: - Properties
    private let propertiesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Категория"
        label.textColor = .ypBlack
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private  lazy var nextButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "chevron"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let properties = ["Категория", "Расписание"]
    private var indexPath: IndexPath?
    weak var delegate: TrackerPropertiesCellDelegate?
    
    //MARK: -  Helper
    func configure(indexPath: IndexPath) {
        addElements()
        setupConstraints()
        self.indexPath = indexPath
        propertiesTitleLabel.text = properties[indexPath.row]
    }
    
    //MARK: - Private Function
    private func addElements() {
        contentView.addSubview(propertiesTitleLabel)
        contentView.addSubview(nextButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            propertiesTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            propertiesTitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            propertiesTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            propertiesTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            nextButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nextButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            nextButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 43),
            nextButton.heightAnchor.constraint(equalToConstant: 43)
        ])
    }
    
    //MARK: - @objc Function
    @objc private func nextButtonTapped(_ sender: UIButton) {
        guard let indexPath = indexPath else { return }
        delegate?.nextButtonTapped(at: indexPath)
    }
}
