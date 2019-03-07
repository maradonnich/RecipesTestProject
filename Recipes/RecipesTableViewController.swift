//
//  RecipesTableViewController.swift
//  Recipes
//
//  Created by Andrey Dolgushin on 04/03/2019.
//  Copyright © 2019 Andrey Dolgushin. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SkeletonView
import AlamofireImage

final class RecipesTableViewController: FetchedResultsTableViewController {
    
    enum RecipesSortMethod: Int {
        case sortByName = 0
        case sortByLastUpdated = 1
        
        func sortDescriptor() -> NSSortDescriptor {
            switch self {
            case .sortByName:
                return NSSortDescriptor(key: #keyPath(Recipe.name), ascending: true)
            case .sortByLastUpdated:
                return NSSortDescriptor(key: #keyPath(Recipe.lastUpdated), ascending: false)
            }
        }
    }
    
    // MARK: - Outlets
    @IBOutlet weak var sortControl: UISegmentedControl!
    
    // MARK: - Properties
    /// Current **CoreData** persitant container.
    public var container: NSPersistentContainer = AppDelegate.shared.persistentContainer {
        didSet {
            updateUI()
        }
    }
    /// Current fetched results controller.
    fileprivate var fetchedResultsCocntroller: NSFetchedResultsController<Recipe>?
    fileprivate var fetchRequestPredicate: NSPredicate?
    fileprivate var fetchRequestSortDescriptor: NSSortDescriptor = RecipesSortMethod.sortByName.sortDescriptor()
    fileprivate var searchController = UISearchController(searchResultsController: nil)
    /// Switch method of sorting
    public var sorting: RecipesSortMethod = .sortByName {
        didSet {
            self.fetchRequestSortDescriptor = self.sorting.sortDescriptor()
            self.updateUI()
        }
    }
    /// Current search text
    fileprivate var searchText: String?
    fileprivate var isFirstLaunch: Bool = true
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Recipes"
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        // Table view init
        self.tableView.register(UINib(nibName: RecipesTableViewCell.nimbName(), bundle: nil), forCellReuseIdentifier: RecipesTableViewCell.reuseIdentifier())
        self.tableView.isSkeletonable = true
        
        // Search result controller init
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = "Search text"
        self.navigationItem.searchController = self.searchController
        self.definesPresentationContext = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isFirstLaunch {
            self.isFirstLaunch = !self.isFirstLaunch
            
            self.tableView.showAnimatedSkeleton()
            // start recipes request
            self.update()
        }
    }

    // MARK: - Helpers
    /// Update model's data
    func update() {
        Alamofire.request(RecipesAPIRouter.getAllRecipes()).validate().responseJSON { [weak self] response in
            let json = response.result.value as? [String: AnyObject]
            let (success, error) = RecipesAPIRouter.validate(responseJSON: response)
            
            // If request
            if success {
                if let json = json {
                    // Make all hard work off the main queue
                    self?.container.performBackgroundTask{ context in
                        if let recipesArray = json[RecipesAPIRouter.ResponseAttributeNames.recipesArray] as? [[String: AnyObject]] {
                            for recipeAttrs in recipesArray {
                                let _ = Recipe(recipeInfo: recipeAttrs, insertInto: context)
                            }
                            try? context.save()
                            DispatchQueue.main.async {
                                self?.tableView.hideSkeleton()
                                self?.updateUI()
                            }
                        }
                    }
                }
            } else {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    /// Update controller User Interface.
    func updateUI() {
        let fetchRequest: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        fetchRequest.sortDescriptors = [self.fetchRequestSortDescriptor]
        if let predicate = self.fetchRequestPredicate {
            fetchRequest.predicate = predicate
        }
        self.fetchedResultsCocntroller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                    managedObjectContext: self.container.viewContext,
                                                                    sectionNameKeyPath: nil,
                                                                    cacheName: nil)
        self.fetchedResultsCocntroller?.delegate = self
        try? self.fetchedResultsCocntroller?.performFetch()
        self.tableView.reloadData()
    }
    
    // MARK: - Action handlers
    @IBAction func sortControlUpdated(_ sender: UISegmentedControl) {
        self.sorting = RecipesSortMethod(rawValue: sender.selectedSegmentIndex) ?? .sortByName
    }
    
}

// MARK: - Table view data source
extension RecipesTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsCocntroller?.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = self.fetchedResultsCocntroller?.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        }
        // Set some skeleton cell numbers to show table loading process
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipesTableViewCell.reuseIdentifier(), for: indexPath) as! RecipesTableViewCell
        
        // Configure the cell...
        if let recipe = self.fetchedResultsCocntroller?.object(at: indexPath) {
            let nameAttributed = NSMutableAttributedString(string: recipe.name ?? "")
            let descriptionAttributed = NSMutableAttributedString(string: recipe.recipeDescription ?? "")
            
            // Find out whether we have search text mathes in the fields, and if yes mark it
            if let searchText = self.searchText {
                if let name = recipe.name,
                    let range = name.range(of: searchText, options: .caseInsensitive) {
                    nameAttributed.addAttributes([.backgroundColor : UIColor.yellow], range: NSRange(range, in: name))
                }
                if let description = recipe.recipeDescription,
                    let range = description.range(of: searchText, options: .caseInsensitive) {
                    descriptionAttributed.addAttributes([.backgroundColor : UIColor.yellow], range: NSRange(range, in: description))
                }
            }
            
            // cell details init
            cell.title.attributedText               = nameAttributed
            cell.recipeDescription.attributedText   = descriptionAttributed
            cell.lastUpdated = cell.lastUpdateFormatted(lastUpdate: recipe.lastUpdated)
            
            if let imageURL = recipe.images?.first {
                cell.mainImageNetworkIndicator.isHidden = false
                cell.mainImageNetworkIndicator.startAnimating()
                
                cell.mainImage?.af_setImage(
                    withURL: imageURL,
                    placeholderImage: nil,
                    filter: AspectScaledToFillSizeFilter(size: cell.mainImage.bounds.size),
                    completion: { response in
                        if response.result.isSuccess {
                            cell.mainImage.image = response.result.value
                        }
                        cell.mainImageNetworkIndicator.stopAnimating()
                })
            }
        }
        
        return cell
    }
}

// MARK: - Table view delegate
extension RecipesTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recipeVC = RecipeViewController.instantiateFromNib()
        recipeVC.recipe = self.fetchedResultsCocntroller?.object(at: indexPath)
        
        self.navigationController?.pushViewController(recipeVC, animated: true)
    }
}

// MARK: - Search Results Updating delegate
extension RecipesTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        var predicate: NSPredicate?
        
        self.searchText = searchController.searchBar.text
        
        if let searchText = self.searchText {
            if !searchText.isEmpty {
                predicate = NSPredicate(format: "\(#keyPath(Recipe.name)) contains[c] %@ OR \(#keyPath(Recipe.recipeDescription)) contains[c] %@ OR \(#keyPath(Recipe.instructions)) contains[c] %@", searchText, searchText, searchText)
            } else {
                self.searchText = nil
            }
        }
        self.fetchRequestPredicate = predicate
        self.updateUI()
    }
}

// MARK: - Skeleton table view data source (inherited from UITableViewDataSource)
extension RecipesTableViewController: SkeletonTableViewDataSource {
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return self.numberOfSections(in: collectionSkeletonView)
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableView(skeletonView, numberOfRowsInSection: section)
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return RecipesTableViewCell.reuseIdentifier()
    }
}

// MARK: - Nib file instantiation protocol implementation
extension RecipesTableViewController: NibInstantiable {
    static func nimbName() -> String {
        return String(describing: self)
    }
    
    static func instantiateFromNib() -> RecipesTableViewController {
        return RecipesTableViewController(nibName: nimbName(), bundle: nil)
    }
}
