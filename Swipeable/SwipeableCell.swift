//
//  SwipeableCell.swift
//  Swipeable
//
//  Created by Ian Dundas on 25/10/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import UIKit

class SwipeableCell: UITableViewCell{
    
    enum SwipeSide{
        case none
        case left
        case right
    }
    
    // MARK: Constants
    
    static let id: String = "Cell"
    static let BoxWidth: CGFloat = 75
    static let DampingAmount: CGFloat = 0.15
    static let SnapAtPercentage: CGFloat = 0.44
    static let SnapAnimationDuration: TimeInterval = 0.4
    
    
    // MARK: Views
    
    let swipeableContentView: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = UIColor.white
        return $0
    }(UIView())

    fileprivate let scrollView: UIScrollView = {
        $0.backgroundColor = UIColor(red:0.16, green:0.58, blue:0.87, alpha:1.00)
        $0.showsHorizontalScrollIndicator = false
        return $0
    }(UIScrollView())
    
    fileprivate let leftButtonContainer: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = UIColor.purple
        return $0
    }(UIView())
    
    fileprivate let rightButtonContainer: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = UIColor.blue
        return $0
    }(UIView())
    
    fileprivate let leftButton: UIButton = {
        $0.backgroundColor = UIColor.red
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton(type: .custom))
    
    fileprivate let rightButton: UIButton = {
        $0.backgroundColor = UIColor.orange
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton(type: .custom))
    
    // MARK: Constraints
    
    var leftButtonContainerRightConstraint: NSLayoutConstraint! = nil
    var rightButtonContainerLeftConstraint: NSLayoutConstraint! = nil
    
    
    // MARK: Event or Button taps
    
    var successCallback: (()->())? = {
        print("Success!")
    }
    
    func didSwipePastSnapPoint(){
        successCallback?()
    }
    
    func didTapButton(){
        successCallback?()
    }
    
    
    // MARK: Drawing Subviews
    
    private var hasSetupSubviews = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !hasSetupSubviews{
            hasSetupSubviews = true
            setupSubviews()
        }
    }
    
    private func setupSubviews(){
        contentView.removeFromSuperview() // pah
        
        // scrollView setup:
        addSubview(scrollView)
        scrollView.delegate = self
        scrollView.constrainToEdgesOf(otherView: self)
        
        setNeedsLayout()
        layoutSubviews()
        
        
        // swipeableContentView setup:
        scrollView.addSubview(swipeableContentView)
        
        NSLayoutConstraint.activate([
            swipeableContentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            swipeableContentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            swipeableContentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            swipeableContentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: SwipeableCell.BoxWidth)
            ])
        
        
        // leftButtonContainer setup:
        addSubview(leftButtonContainer)
        
        NSLayoutConstraint.activate([
            leftButtonContainer.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            leftButtonContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            
            leftButtonContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: SwipeableCell.BoxWidth),
            leftButtonContainer.leftAnchor.constraint(lessThanOrEqualTo: scrollView.leftAnchor),
            ])
        
        leftButtonContainerRightConstraint = leftButtonContainer.rightAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 0)
        leftButtonContainerRightConstraint.isActive = true
        
        // left button setup:
        leftButton.addTarget(self, action: #selector(SwipeableCell.didTapButton), for: .touchUpInside)
        leftButtonContainer.addSubview(leftButton)
        
        leftButton.constrainToEdgesOf(otherView: leftButtonContainer)
        
        
        // rightButtonContainer setup:
        addSubview(rightButtonContainer)
        
        NSLayoutConstraint.activate([
            rightButtonContainer.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            rightButtonContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            
            rightButtonContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: SwipeableCell.BoxWidth),
            rightButtonContainer.rightAnchor.constraint(greaterThanOrEqualTo: scrollView.rightAnchor),
            ])
        
        rightButtonContainerLeftConstraint = rightButtonContainer.leftAnchor.constraint(equalTo: scrollView.rightAnchor, constant: 0)
        rightButtonContainerLeftConstraint.isActive = true
        
        
//        // left button setup:
//        rightButton.addTarget(self, action: #selector(SwipeableCell.didTapButton), for: .touchUpInside)
//        rightButtonContainer.addSubview(leftButton)
//        
//        leftButton.constrainToEdgesOf(otherView: leftButtonContainer)
        
        setNeedsLayout()
        layoutSubviews()
        
        scrollView.contentSize = CGSize(width: bounds.width + (SwipeableCell.BoxWidth * 2), height: scrollView.height)
        scrollView.contentOffset = restingContentOffset
    }
    
    
    fileprivate var restingContentOffset: CGPoint{
        return CGPoint(x: SwipeableCell.BoxWidth, y: 0)
    }
    fileprivate var calibratedX: CGFloat{
        return abs(scrollView.contentOffset.x - restingContentOffset.x)
    }
    fileprivate var isBeyondSnapPoint: Bool{
        return calibratedX >= (bounds.width * SwipeableCell.SnapAtPercentage)
    }
    
    fileprivate var scrollViewDirection: UIScrollView.TravelDirection = .none
    fileprivate var activeSide: SwipeSide {
        // TODO remove
        let localCalibratedX = (scrollView.contentOffset.x - restingContentOffset.x)
        if localCalibratedX == 0{
            return .none
        }
        else if localCalibratedX < 0{
            return .left
        }
        else {
            return .right
        }
    }
    fileprivate var lastContentOffset: CGFloat = 0
    fileprivate var hasSnappedOut: Bool = false
}


extension SwipeableCell: UIScrollViewDelegate{
    
    private func mutate(layoutConstraint: NSLayoutConstraint, constant: CGFloat, withAnimation: Bool){
        let mutation = {
            layoutConstraint.constant = constant
            self.layoutIfNeeded()
        }
        if withAnimation{
            UIView.animate(withDuration: SwipeableCell.SnapAnimationDuration, delay: 0, options: .curveEaseInOut,
                           animations: mutation, completion: nil)
        }
        else{
            mutation()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("Scrollview offset: \(scrollView.contentOffset.x)")
        scrollViewDirection = scrollView.scrollDirection(previousContentOffset: lastContentOffset)
        lastContentOffset = scrollView.contentOffset.x
        
        guard activeSide != .none else {return}
        let constraint: NSLayoutConstraint = activeSide == .left ? leftButtonContainerRightConstraint : rightButtonContainerLeftConstraint
        let inverter: CGFloat = activeSide == .left ? 1 : -1
        
        if isBeyondSnapPoint {
            mutate(layoutConstraint: constraint, constant: calibratedX * inverter, withAnimation: !hasSnappedOut)
            hasSnappedOut = true
        }
        else{
            let primaryOffset = min(calibratedX, SwipeableCell.BoxWidth)
            let dampedOffset: CGFloat = {
                if calibratedX > SwipeableCell.BoxWidth {
                    let remaining = calibratedX - SwipeableCell.BoxWidth
                    return remaining * SwipeableCell.DampingAmount
                }
                return 0
            }()
            let totalOffset = primaryOffset + dampedOffset
            
            mutate(layoutConstraint: constraint, constant: totalOffset * inverter, withAnimation: hasSnappedOut)
            hasSnappedOut = false
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool){
        if calibratedX < SwipeableCell.BoxWidth{
            print("direction: \(scrollViewDirection), side:\(activeSide)")
            switch (activeSide, scrollViewDirection) {
                case (.left, .right):
                    DispatchQueue.main.async {
                        scrollView.setContentOffset(CGPoint(x: SwipeableCell.BoxWidth, y: 0), animated: true)
                    }
                
                case (.right, .left):
                    DispatchQueue.main.async {
                        scrollView.setContentOffset(CGPoint(x: self.restingContentOffset.x+SwipeableCell.BoxWidth, y: 0), animated: true)
                    }
                
                default:
                    DispatchQueue.main.async {
                        scrollView.setContentOffset(self.restingContentOffset, animated: true)
                    }
                
            }
        }
        else if isBeyondSnapPoint {
            DispatchQueue.main.async {
                self.didSwipePastSnapPoint()
                self.scrollView.setContentOffset(self.restingContentOffset, animated: true)
            }
        }
    }
}
