
import Foundation
import UIKit

final class StatisticsViewController: UIViewController {
    private var listOfTrackers = [String]()
    
    //MARK: - UI
    private lazy var stubImageView: UIImageView = {
        let image = UIImage(named: "stub2")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var stubLabel: UILabel = {
        let label = UILabel()
        label.text = "Анализировать пока нечего"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor(named: "Black")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var navigationBar: UINavigationBar = {
        let navigationBar = navigationController?.navigationBar ?? UINavigationBar()
        navigationBar.topItem?.title = "Статистика"
        navigationBar.prefersLargeTitles = true
        navigationBar.topItem?.largeTitleDisplayMode = .always
        return navigationBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        
        setupView()
        setupConstraints()
    }
    
    private func setupView(){
        view.addSubview(stubImageView)
        view.addSubview(stubLabel)
        view.addSubview(navigationBar)
    }
    
    
    private func setupConstraints() {
        stubImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stubImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stubImageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        stubImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        stubLabel.topAnchor.constraint(equalTo: stubImageView.bottomAnchor, constant: 8).isActive = true
        stubLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        stubLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        stubLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true
    }
}
