
import UIKit

@MainActor
class StoreItemContainerViewController: UIViewController, UISearchResultsUpdating {
    
    @IBOutlet var tableContainerView: UIView!
    @IBOutlet var collectionContainerView: UIView!
    weak var collectionViewController: StoreItemCollectionViewController?
    
    let searchController = UISearchController()
    let storeItemController = StoreItemController()
    
    var tableViewDataSource: StoreItemTableViewDiffableDataSource!
    var collectionViewDataSource: UICollectionViewDiffableDataSource<String, StoreItem>!
    
    
    
    //    var items = [StoreItem]()
    
    var itemsSnapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
    
    
    //    var itemsSnapshot: NSDiffableDataSourceSnapshot<String, StoreItem> {
    //        var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
    //        snapshot.appendSections(["Results"])
    //        snapshot.appendItems(items)
    //
    //        return snapshot
    //    }
    
    //    let queryOptions = SearchScope.allCases
    
    var selectedSearchScope: SearchScope {
        
        let selectedIndex = searchController.searchBar.selectedScopeButtonIndex
        let searchScope = SearchScope.allCases[selectedIndex]
        
        return searchScope
        
    }
    
    
    // keep track of async tasks so they can be cancelled if appropriate.
    var searchTask: Task<Void, Never>? = nil
    var tableViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
    var collectionViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = true
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map({ $0.title })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let tableViewController = segue.destination as? StoreItemListTableViewController {
            configureTableViewDataSource(tableViewController.tableView)
        }
            
            if let collectionViewController = segue.destination as? StoreItemCollectionViewController {
                configureCollectionViewDataSource(collectionViewController.collectionView)
                collectionViewController.configureCollectionViewLayout(for: selectedSearchScope)
                
                self.collectionViewController = collectionViewController
        }
    }
    
    func configureTableViewDataSource(_ tableView: UITableView) {
        tableViewDataSource = StoreItemTableViewDiffableDataSource(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemTableViewCell
            
            self.tableViewImageLoadTasks[indexPath]?.cancel()
            self.tableViewImageLoadTasks[indexPath] = Task {
                await cell.configure(for: item, storeItemController: self.storeItemController)
                self.tableViewImageLoadTasks[indexPath] = nil
            }
            
            return cell
        })
    }
    
    func configureCollectionViewDataSource(_ collectionView: UICollectionView) {
        
        collectionViewDataSource = .init(collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Item", for: indexPath) as! ItemCollectionViewCell
            
            self.collectionViewImageLoadTasks[indexPath]?.cancel()
            self.collectionViewImageLoadTasks[indexPath] = Task {
                await cell.configure(for: item, storeItemController: self.storeItemController)
                self.collectionViewImageLoadTasks[indexPath] = nil
            }
            print(cell)
            return cell
        })
        
        collectionViewDataSource.supplementaryViewProvider = {
            collectionView, kind, indexPath -> UICollectionReusableView? in
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: "Header", withReuseIdentifier: StoreItemCollectionViewSectionHeader.reuseIdentifier, for: indexPath) as! StoreItemCollectionViewSectionHeader
            
            let title = self.itemsSnapshot.sectionIdentifiers[indexPath.section]
            headerView.setTitle(title)
            
            print(title)
            
            return headerView
            
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fetchMatchingItems), object: nil)
        perform(#selector(fetchMatchingItems), with: nil, afterDelay: 0.3)
    }
    
    @IBAction func switchContainerView(_ sender: UISegmentedControl) {
        tableContainerView.isHidden.toggle()
        collectionContainerView.isHidden.toggle()
    }
    
    func handleFetchedItems(_ items: [StoreItem]) async {

        let currentSnapshotItems = itemsSnapshot.itemIdentifiers

        let updateSnapshot = createSectionSnapshot(from: currentSnapshotItems + items)
        
        itemsSnapshot = updateSnapshot
        
        collectionViewController?.configureCollectionViewLayout(for: selectedSearchScope)

        await tableViewDataSource.apply(itemsSnapshot, animatingDifferences: true)

        await collectionViewDataSource.apply(itemsSnapshot, animatingDifferences: true)
        
    }
    
    func fetchAndHandleItemsForSearchScopes(_ searchScopes: [SearchScope], withSearchTerm searchTerm: String) async throws {
        
        try await withThrowingTaskGroup(of: (SearchScope, [StoreItem]).self) { group in
            for searchScope in searchScopes { group.addTask {
                
                try Task.checkCancellation()
                
                let query = [
                    "term": searchTerm,
                    "media": searchScope.mediaType,
                    "lang": "en_us",
                    "limit": "20"
                ]
                return (searchScope, try await
                        self.storeItemController.fetchItems(matching: query))
            }
            }
            
            for try await (searchScope, items) in group {
                try Task.checkCancellation()
                if searchTerm == self.searchController.searchBar.text &&
                    (self.selectedSearchScope == .all || searchScope == self.selectedSearchScope) {
                    await handleFetchedItems(items)
                    
                    
                }
            }
        }
    }
    
    
    func createSectionSnapshot(from items: [StoreItem]) -> NSDiffableDataSourceSnapshot<String, StoreItem> {
        
        let movies = items.filter{ $0.kind == "feature-movie" }
        let music = items.filter{ $0.kind == "song" || $0.kind == "album" }
        let apps = items.filter{ $0.kind == "software" }
        let books = items.filter{ $0.kind == "ebook" }
        
        let grouped: [(SearchScope, [StoreItem])] = [
            (.movies, movies),
            (.music, music),
            (.apps, apps),
            (.books, books)
        ]
        var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
        grouped.forEach { (scope, item)  in
            if item.count > 0 {
                snapshot.appendSections([ scope.title ])
                snapshot.appendItems(item, toSection: scope.title)
            }
        }
        return snapshot
    }
    
    
    
    @objc func fetchMatchingItems() {
        
        itemsSnapshot.deleteAllItems()
        
        let searchTerm = searchController.searchBar.text ?? ""
        
        let searchScopes: [SearchScope]
        
        if selectedSearchScope == .all {
            searchScopes = [.movies, .music, .apps, .books]
        } else {
            searchScopes = [selectedSearchScope]
        }
 
        
        
        //        let mediaType = queryOptions[searchController.searchBar.selectedScopeButtonIndex]
        
        // cancel any images that are still being fetched and reset the imageTask dictionaries
        
        collectionViewImageLoadTasks.values.forEach { task in task.cancel() }
        
        collectionViewImageLoadTasks = [:]
        
        tableViewImageLoadTasks.values.forEach { task in task.cancel() }
        
        tableViewImageLoadTasks = [:]
        
        // cancel existing task since we will not use the result
        
        searchTask?.cancel()
        
        searchTask = Task {
            
            if !searchTerm.isEmpty {
                
                do {
                    try await
                    fetchAndHandleItemsForSearchScopes(searchScopes, withSearchTerm: searchTerm)
                    
                } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    
                } catch is CancellationError {
                    
                } catch {
                    print(searchScopes)
                    print(error)
                }
                
            } else {
                await self.tableViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
                await self.collectionViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
                
            }
            searchTask = nil
        }
        
        // set up query dictionary
//        let query = [
//            "term": searchTerm,
//            "media": selectedSearchScope.mediaType,
//            "lang": "en_us",
//            "limit": "20"
//        ]
        
        //        do {
        //            // use the item controller to fetch items
        //            let items = try await storeItemController.fetchItems(matching: query)
        //
        //            if searchTerm == self.searchController.searchBar.text &&
        //
        //                query["media"] == selectedSearchScope.mediaType{
        //                //                        self.items = items
        //            }
        //
        //        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
        //            // ignore cancellation errors
        //
        //        } catch {
        //            // otherwise, print an error to the console
        //            print(error)
        //        }
        //        // apply data source changes
        //
        //        await tableViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
        //        await collectionViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
        //
        //    } else {
        //        await self.tableViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
        //        await self.collectionViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
        //    }
        //    searchTask = nil
        //}
        //}
        
    }
}
