
import Foundation
import UIKit


class StoreItemCollectionViewSectionHeader: UICollectionReusableView {
    
    static let reuseIdentifier = "StoreItemCollectionViewSectionHeader"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .blue
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        return label
        
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    private func setupView() {
        backgroundColor = .white
        
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 22),
                                     titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                                     titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                                     titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                                    ])
    }
    
    
    
    
    
}
