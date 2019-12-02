//
//  LocationSearchController.swift
//  MapsDirectionGooglePlaces
//
//  Created by Hrabowskie, Rj on 11/26/19.
//  Copyright © 2019 Hrabowskie, Rj. All rights reserved.
//

import SwiftUI
import UIKit
import LBTATools
import MapKit
import Combine

class LocationSearchCell: LBTAListCell<MKMapItem> {
    override var item: MKMapItem! {
        didSet {
            nameLabel.text = item.name
            addressLabel.text = item.address()
        }
    }
    
    let nameLabel = UILabel(text: "Name", font: .boldSystemFont(ofSize: 16))
    let addressLabel = UILabel(text:"Address", font: .systemFont(ofSize: 14))
    
    override func setupViews() {
        stack(nameLabel,
              addressLabel).withMargins(.allSides(16))
        addSeparatorView(leftPadding: 16)
    }
}

class LocationSearchController: LBTAListController<LocationSearchCell, MKMapItem> {
    var selectionHandler: ((MKMapItem) -> ())?
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.popViewController(animated: true)
        let mapItem = self.items[indexPath.item]
        selectionHandler?(mapItem)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.becomeFirstResponder()
        performLocalSearch()
        setupSearchBar()
    }
    
    let searchTextField = IndentedTextField(placeholder: "Enter search term", padding: 12)
    let backIcon = UIButton(image: #imageLiteral(resourceName: "back_arrow"), tintColor: .black, target: self, action: #selector(handleBack)).withWidth(32)
    
    @objc fileprivate func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    let navBarHeight: CGFloat = 66
    
    fileprivate func setupSearchBar() {
        let navBar = UIView(backgroundColor: .white)
        view.addSubview(navBar)
        navBar.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: -navBarHeight, right: 0))
        
        // Fix scrollbar insets
        collectionView.verticalScrollIndicatorInsets.top = navBarHeight
        
        let container = UIView(backgroundColor: .clear)
        navBar.addSubview(container)
        container.fillSuperviewSafeAreaLayoutGuide()
        container.hstack(backIcon, searchTextField, spacing: 12).withMargins(.init(top: 0, left: 16, bottom: 16, right: 16))
        searchTextField.layer.borderWidth = 2
        searchTextField.layer.borderColor = UIColor.lightGray.cgColor
        searchTextField.layer.cornerRadius = 5
        
        setupSearchListener()
    }
    
    var listener: AnyCancellable!
    
    fileprivate func setupSearchListener() {
        // Search throttling
        listener = NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: searchTextField).debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] (_) in
                self?.performLocalSearch()
        }
        // Stop listening to text changes
        listener.cancel()
    }
    
    // Fix items under search bar
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: navBarHeight, left: 0, bottom: 0, right: 0)
    }
    
    fileprivate func performLocalSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTextField.text
        let search = MKLocalSearch.init(request: request)
        search.start { (resp, err) in
            if let err = err {
                print("Failed search:", err)
                return
            }
            self.items = resp?.mapItems ?? []
        }
    }
}

extension LocationSearchController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width, height: 70)
    }
}

struct LocationSearchController_Previews: PreviewProvider {
    static var previews: some View {
        ContainerView().edgesIgnoringSafeArea(.all)
    }
    
    struct ContainerView: UIViewControllerRepresentable {
        func makeUIViewController(context: UIViewControllerRepresentableContext<LocationSearchController_Previews.ContainerView>) -> UIViewController {
            LocationSearchController()
        }
        
        func updateUIViewController(_ uiViewController: LocationSearchController_Previews.ContainerView.UIViewControllerType, context: UIViewControllerRepresentableContext<LocationSearchController_Previews.ContainerView>) {
            
        }
    }
}
