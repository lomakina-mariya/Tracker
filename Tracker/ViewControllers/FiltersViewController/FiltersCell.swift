
import Foundation
import UIKit

final class FiltersCell: UITableViewCell {
    
    //MARK: - Properties
    private let filterTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ypBlack
        label.font = .systemFont(ofSize: 17, weight: .regular)
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "checkmark")?.withRenderingMode(.alwaysOriginal))
        imageView.isHidden = true
        return imageView
    }()
    
    private let separatorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "custom_separator")
        return imageView
    }()
   
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        contentView.backgroundColor = .ypLightGray.withAlphaComponent(0.3)
        addElements()
        setupConstraints()
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: -  Function
    private func addElements() {
        [filterTitleLabel, checkmarkImageView, separatorImageView].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            filterTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            filterTitleLabel.heightAnchor.constraint(equalToConstant: 24),
            filterTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            filterTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            separatorImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorImageView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func configure(text: String) {
        filterTitleLabel.text = text
    }
    
    func setCheckmarkVisible(_ visible: Bool) {
        checkmarkImageView.isHidden = !visible
    }
    
    func hideSeparatorImageView() {
        separatorImageView.isHidden = true
    }
}

