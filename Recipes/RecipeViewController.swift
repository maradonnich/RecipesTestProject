//
//  RecipeViewController.swift
//  Recipes
//
//  Created by Andrey Dolgushin on 06/03/2019.
//  Copyright © 2019 Andrey Dolgushin. All rights reserved.
//

import UIKit
import AlamofireImage

final class RecipeViewController: UIViewController {
    
    // MARK: Constants
    struct Constants {
        static let imagesCollectionViewReuseIdentificator = "RecipeViewControllerCollectionViewCell"
    }

    // MARK: - Outlets
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var recipeDescription: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var instructions: UILabel!
    @IBOutlet weak var difficulty: Indicator!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var imagesPageControl: UIPageControl!
    
    // MARK: - Properties
    var recipe: Recipe? {
        didSet {
            self.navigationItem.title = self.recipe?.name
            self.updateUI()
        }
    }
    fileprivate var imageViewsArray = [UIImageView]()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.imagesCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Constants.imagesCollectionViewReuseIdentificator)
        self.imagesCollectionView.dataSource = self
        self.imagesCollectionView.delegate = self
        
        self.view.isSkeletonable = true
        self.setSkeletonAppearance(animated: true)
        
        self.updateUI()
    }


    // MARK: - Helpers
    func setSkeletonAppearance(animated: Bool) {
        self.difficulty?.isHidden = animated
        self.instructionsLabel?.isHidden = animated
        
        animated ? self.view?.showAnimatedSkeleton() : self.view?.hideSkeleton()
    }
    
    func updateUI() {
        self.setSkeletonAppearance(animated: false)
        
        self.name?.text                     = self.recipe?.name
        self.recipeDescription?.text        = self.recipe?.recipeDescription
        self.instructions?.attributedText   = self.recipe?.instructions?.htmlAttributed(using: UIFont.systemFont(ofSize: 16))
        self.difficulty?.value              = UInt(self.recipe?.difficulty ?? 3)
        
        // clear all internal collection view cell subviews
        for imageView in self.imageViewsArray {
            imageView.removeFromSuperview()
        }
        self.imageViewsArray.removeAll()
        
        self.imagesCollectionView?.reloadData()
        
        self.imagesPageControl?.numberOfPages = self.recipe?.images?.count ?? 0
        self.imagesPageControl?.currentPage = 0
    }
}

// MARK: - Collection View data source implementation
extension RecipeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.recipe?.images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.imagesCollectionViewReuseIdentificator, for: indexPath)
        
        // initialize new image view container
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: collectionView.bounds.size))
        imageView.backgroundColor = UIColor.groupTableViewBackground
        let networkIndicator = UIActivityIndicatorView(style: .whiteLarge)
        networkIndicator.hidesWhenStopped = true
        networkIndicator.startAnimating()
        imageView.addSubview(networkIndicator)
        networkIndicator.center = CGPoint(x: 0.5*imageView.bounds.size.width, y: 0.5*imageView.bounds.size.height)
        cell.addSubview(imageView)
        self.imageViewsArray.append(imageView)
        
        // load image and stop network indicator animation
        if let url = self.recipe?.images?[indexPath.row] {
            imageView.af_setImage(
                withURL: url,
                placeholderImage: nil,
                filter: AspectScaledToFillSizeFilter(size: imageView.bounds.size),
                imageTransition: .crossDissolve(0.5),
                completion: { response in
                    if response.result.isSuccess {
                        imageView.image = response.result.value
                    }
                    networkIndicator.stopAnimating()
                    networkIndicator.removeFromSuperview()
            })
        }
        return cell
    }
}

// MARK: - Collection View delegate
extension RecipeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - Collection View Flow Layout
extension RecipeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - Scroll View delegate
extension RecipeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Set UIPageControl to the right position
        let number = Int(round(scrollView.contentOffset.x/scrollView.bounds.size.width))
        self.imagesPageControl.currentPage = number
    }
}


// MARK: - Nib file instantiation protocol implementation
extension RecipeViewController: NibInstantiable {
    static func nimbName() -> String {
        return String(describing: self)
    }
    
    static func instantiateFromNib() -> RecipeViewController {
        return RecipeViewController(nibName: nimbName(), bundle: nil)
    }
}
