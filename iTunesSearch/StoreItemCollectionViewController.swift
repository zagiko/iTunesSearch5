
import UIKit

class StoreItemCollectionViewController: UICollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(StoreItemCollectionViewSectionHeader.self, forSupplementaryViewOfKind: "Header", withReuseIdentifier: StoreItemCollectionViewSectionHeader.reuseIdentifier)
//
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3), heightDimension: .fractionalHeight(1))
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//
//        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.5))
//        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
//
//        let section = NSCollectionLayoutSection(group: group)
//        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
//        section.interGroupSpacing = 8
//
//        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(section: section)
    }
    
    func configureCollectionViewLayout(for searchScope: SearchScope) {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 8, leading: 16, bottom: 5, trailing: 16)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: searchScope.groupWidthDimension, heightDimension: .absolute(166))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: searchScope.groupItemCount)
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = searchScope.ortogonalScrollingBehavior
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(36))
        
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "Header", alignment: .topLeading)
        
        section.boundarySupplementaryItems = [headerItem]
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        collectionView.collectionViewLayout = layout
    
    }
    
    
    
    
}

extension SearchScope {
    
    var ortogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior {
        
        switch self {
        case .all:
            return .continuousGroupLeadingBoundary
        default:
            return .none
        }
    }
    
    var groupItemCount: Int {
        switch self {
        case .all:
            return 1
        default:
            return 3
            
        }
    }
    
    var groupWidthDimension: NSCollectionLayoutDimension {
        switch self {
        case .all:
            return .fractionalWidth(1/3)
        default:
            return .fractionalWidth(1.0)
        }
    }
}
