//
//  ExpandCollapseLayout.swift
//  CollectionViewAnimations
//
//  Created by Christian Noon on 10/29/15.
//  Copyright © 2015 Noondev. All rights reserved.
//

import UIKit

class ExpandCollapseLayout: UICollectionViewLayout {

    struct SectionLimit {
        let top: CGFloat
        let bottom: CGFloat
    }

    // MARK: - Properties

    var previousAttributes: [[UICollectionViewLayoutAttributes]] = []
    var currentAttributes: [[UICollectionViewLayoutAttributes]] = []

    var previousSectionAttributes: [UICollectionViewLayoutAttributes] = []
    var currentSectionAttributes: [UICollectionViewLayoutAttributes] = []

    var currentSectionLimits: [SectionLimit] = []

    let sectionHeight: CGFloat = 40

    var contentSize = CGSizeZero
    var selectedCellIndexPath: NSIndexPath?

    // MARK: - Preparation

    override func prepareLayout() {
        super.prepareLayout()

        print("-------------- PREPARE LAYOUT ---------------")

        previousAttributes = currentAttributes
        previousSectionAttributes = currentSectionAttributes

        contentSize = CGSizeZero
        currentAttributes = []
        currentSectionAttributes = []
        currentSectionLimits = []

        //============ COMPUTE CONTENT CELL ATTRIBUTES ===========

        if let collectionView = collectionView {
            let width = collectionView.bounds.size.width
            var y: CGFloat = 0

            for sectionIndex in 0..<collectionView.numberOfSections() {
                let itemCount = collectionView.numberOfItemsInSection(sectionIndex)
                let sectionTop = y

                // Add section header cell

                let indexPath = NSIndexPath(forItem: 0, inSection: sectionIndex)
                let attributes = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: SectionHeaderCell.kind,
                    withIndexPath: indexPath
                )

                attributes.zIndex = 1
                attributes.frame = CGRectMake(0, y, width, sectionHeight)

                currentSectionAttributes.append(attributes)

                y += sectionHeight

                // Add content cells

                var attributesList: [UICollectionViewLayoutAttributes] = []

                for itemIndex in 0..<itemCount {
                    let indexPath = NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
                    let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                    let size = CGSize(
                        width: width,
                        height: indexPath == selectedCellIndexPath ? 300.0 : 100.0
                    )

                    attributes.frame = CGRectMake(0, y, width, size.height)

                    attributesList.append(attributes)

                    y += size.height
                }

                let sectionBottom = y
                currentSectionLimits.append(SectionLimit(top: sectionTop, bottom: sectionBottom))

                currentAttributes.append(attributesList)
            }

            contentSize = CGSizeMake(width, y)

            //============ COMPUTE STICKY HEADER ATTRIBUTES ===========

            let collectionViewTop = collectionView.contentOffset.y // Stuck
            let aboveCollectionViewTop = collectionViewTop - sectionHeight

            for sectionIndex in 0..<collectionView.numberOfSections() {
                let sectionLimit = currentSectionLimits[sectionIndex]
                let sectionAttributes = currentSectionAttributes[sectionIndex]

                let sectionTop = sectionLimit.top
                let sectionBottom = sectionLimit.bottom - sectionHeight

                sectionAttributes.frame.origin.y = min(
                    max(sectionTop, collectionViewTop),
                    max(sectionBottom, aboveCollectionViewTop)
                )

                if sectionIndex == collectionView.numberOfSections() - 1 {
                    print("Last Section Attributes: \(sectionAttributes.frame)")
                }
            }
        }
    }

    // MARK: - Layout Attributes - Content Cell

    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return previousAttributes[itemIndexPath.section][itemIndexPath.item]
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return currentAttributes[indexPath.section][indexPath.item]
    }

    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributesForItemAtIndexPath(itemIndexPath)
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []

        for sectionIndex in 0..<(collectionView?.numberOfSections() ?? 0) {
            let sectionAttributes = currentSectionAttributes[sectionIndex]

            if CGRectIntersectsRect(rect, sectionAttributes.frame) {
                attributes.append(sectionAttributes)
            }

            for item in currentAttributes[sectionIndex] where CGRectIntersectsRect(rect, item.frame) {
                attributes.append(item)
            }
        }

        return attributes
    }

    // MARK: - Layout Attributes - Section Header Cell

    override func initialLayoutAttributesForAppearingSupplementaryElementOfKind(
        elementKind: String,
        atIndexPath elementIndexPath: NSIndexPath)
        -> UICollectionViewLayoutAttributes?
    {
        let attributes = previousSectionAttributes[elementIndexPath.section]

        if elementIndexPath.section == 3 {
            print("initial: \(elementIndexPath.section) \(attributes.frame)")
        }

        return attributes
    }

    override func layoutAttributesForSupplementaryViewOfKind(
        elementKind: String,
        atIndexPath indexPath: NSIndexPath)
        -> UICollectionViewLayoutAttributes?
    {
        let attributes = currentSectionAttributes[indexPath.section]

        if indexPath.section == 3 {
            print("layout: \(indexPath.section) \(attributes.frame)")
        }

        return attributes
    }

    override func finalLayoutAttributesForDisappearingSupplementaryElementOfKind(
        elementKind: String,
        atIndexPath elementIndexPath: NSIndexPath)
        -> UICollectionViewLayoutAttributes?
    {
        let attributes = layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: elementIndexPath)

        if elementIndexPath.section == 3 {
            print("final: \(elementIndexPath.section) \(attributes!.frame)")
        }

        return attributes
    }

    // MARK: - Invalidation

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
//        if let oldBounds = collectionView?.bounds where !CGSizeEqualToSize(oldBounds.size, newBounds.size) {
//            return true
//        }
//
//        return false

        return true
    }

    // MARK: - Animations

    override func prepareForAnimatedBoundsChange(oldBounds: CGRect) {
        super.prepareForAnimatedBoundsChange(oldBounds)
        print("prepareForAnimatedBoundsChange: \(oldBounds)")
    }

    override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
        print("finalizeAnimatedBoundsChange")
    }

    // MARK: - Collection View Info

    override func collectionViewContentSize() -> CGSize {
        return contentSize
    }

    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
        guard let selectedCellIndexPath = selectedCellIndexPath else {
            print("Returning proposed content offset: \(proposedContentOffset)")
            return proposedContentOffset
        }

        var finalContentOffset = proposedContentOffset

        if let frame = layoutAttributesForItemAtIndexPath(selectedCellIndexPath)?.frame {
            let collectionViewHeight = collectionView?.bounds.size.height ?? 0

            let collectionViewTop = proposedContentOffset.y
            let collectionViewBottom = collectionViewTop + collectionViewHeight

            let cellTop = frame.origin.y
            let cellBottom = cellTop + frame.size.height

            if cellBottom > collectionViewBottom {
                finalContentOffset = CGPointMake(0.0, collectionViewTop + (cellBottom - collectionViewBottom))
            } else if cellTop < collectionViewTop {
                finalContentOffset = CGPointMake(0.0, collectionViewTop - (collectionViewTop - cellTop))
            }
        }

        print("Returning custom offset: \(finalContentOffset)")

        return finalContentOffset
    }
}