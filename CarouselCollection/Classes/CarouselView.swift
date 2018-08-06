//
//  CarouselView.swift
//  CarouselCollection
//
//  Created by anan on 2018/7/26.
//  Copyright © 2018年 anshao. All rights reserved.
//

import UIKit

/**
 *  cell相关协议方法
 **/
@objc protocol CarouselViewDelegate: NSObjectProtocol {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    @objc optional func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
}

class CarouselView: UIView {
    
    /*
     *  MARK: - 定义变量
     */
    // 屏幕的宽高
    fileprivate let kScreenW = UIScreen.main.bounds.size.width
    fileprivate let kScreenH = UIScreen.main.bounds.size.height
    
    // 标识当前索引值，默认为 0
    fileprivate var currentIndex: Int = 0
    // 开始/结束拖拽时的x坐标值，默认为 0
    fileprivate var dragStartX: CGFloat = 0
    fileprivate var dragEndX: CGFloat = 0
    // 记录cell的总个数，默认为 0
    fileprivate var dataCount: Int = 0
    // 标识是否已经计算了 expandCellCount，默认为 false
    fileprivate var isCalculateExpandCellCount: Bool = false
    
    // 标识是哪个section下的功能，默认为第0个
    public var section: Int = 0
    // 是否以page为基础滑动（即滑动一屏），默认为 false
    public var isPagingEnabled: Bool = false
    // 代理
    weak var delegate: CarouselViewDelegate?
    // item距屏幕两侧的间距，默认为 15
    public var sectionMargin: CGFloat = 15 {
        didSet {
            carouselLayout.sectionInset = UIEdgeInsets(top: 0, left: sectionMargin, bottom: 0, right: sectionMargin)
        }
    }
    // item与item之间的间距，默认为 10
    public var itemSpacing: CGFloat = 10 {
        didSet {
            carouselLayout.minimumLineSpacing = itemSpacing
            carouselLayout.minimumInteritemSpacing = itemSpacing
        }
    }
    
    // 控件
    public lazy var carouselCollection: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.carouselLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
//        collectionView.isPagingEnabled = true // 不用这个
        return collectionView
    }()
    fileprivate lazy var carouselLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 0, left: sectionMargin, bottom: 0, right: sectionMargin)
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    // 数据源
    public var dataSource: [Any] = [] {
        didSet {
            // 计算cell的总数量
            self.dataCount = dataSource.count
            calculateTotalCell()
        }
    }
    // 若要循环滚动效果，则需更改cell的总数量
    public var expandCellCount: Int = 0 {
        didSet {
            calculateTotalCell()
        }
    }
    // 从第几个cell开始显示的位置
    public var startPosition: Int = 0 {
        didSet {
            if dataSource.count > 0 {
                startPosition = dataSource.count * startPosition
            }
            initCellPosition()
        }
    }
    // item的宽高
    fileprivate var itemWidth: CGFloat {
        get {
            return (kScreenW-sectionMargin*2)
        }
    }
    fileprivate var itemHeight: CGFloat {
        get {
            return self.carouselCollection.frame.size.height - 1
        }
    }

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 *  初始化
 **/
extension CarouselView {
    /*
     *  MARK: - 初始化UI
     */
    fileprivate func setupUI() {
        
        // 设置 UICollectionView
        carouselCollection.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.addSubview(carouselCollection)
        // 设置 item 的宽高（这里的高度是根据collectionView来的，所以必须在collectionView设置frame之后设置，否则显示错误）
//        carouselLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
    }
}

/**
 *  UICollectionViewDelegate, UICollectionViewDataSource
 **/
extension CarouselView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // 获取外部数据
        if delegate != nil && ((delegate?.responds(to: #selector(CarouselViewDelegate.collectionView(_:cellForItemAt:)))) ?? false) {
            let cell = delegate?.collectionView(collectionView, cellForItemAt: indexPath)
            if let tempCell = cell {
                return tempCell
            }
        }
        
        // 返回默认
        return collectionView.dequeueReusableCell(withReuseIdentifier: "other", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 返回点击事件
        if delegate != nil && ((delegate?.responds(to: #selector(CarouselViewDelegate.collectionView(_:didSelectItemAt:)))) ?? false) {
            delegate?.collectionView!(collectionView, didSelectItemAt: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        // 获取外部数据
        if delegate != nil && ((delegate?.responds(to: #selector(CarouselViewDelegate.collectionView(_:layout:sizeForItemAt:)))) ?? false) {
            let itemSize = delegate?.collectionView!(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
            if let tempItemSize = itemSize {
                return tempItemSize
            }
        }
        
        // 返回默认
        return CGSize(width: itemWidth, height: itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // 获取外部数据
        if delegate != nil && ((delegate?.responds(to: #selector(CarouselViewDelegate.collectionView(_:layout:insetForSectionAt:)))) ?? false) {
            let inset = delegate?.collectionView!(collectionView, layout: collectionViewLayout, insetForSectionAt: section)
            if let tempInset = inset {
                return tempInset
            }
        }
        
        // 返回默认
        return UIEdgeInsets(top: 0, left: sectionMargin, bottom: 0, right: sectionMargin)
    }
}

/**
 *  UIScrollViewDelegate
 **/
extension CarouselView: UIScrollViewDelegate {
    /*
     *  MARK: - 手指拖动开始
     */
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 记录拖拽开始时的x坐标的
        self.dragStartX = scrollView.contentOffset.x
    }
    
    /*
     *  MARK: - 手指拖动结束
     */
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 判断是否按page滑动
        if !isPagingEnabled {
            return
        }
        
        // 记录拖拽结束时的x坐标的
        self.dragEndX = scrollView.contentOffset.x
        // 主线程刷新UI
        DispatchQueue.main.async {
            self.fixCellToCenter()
        }
    }
}

/**
 *  计算cell的位置
 **/
extension CarouselView {
    
    /*
     *  MARK: - 计算显示cell的总数
     */
    fileprivate func calculateTotalCell() {
        // 判断是否有数据，有则进行计算
        if dataSource.count > 0 {
            // 要额外添加的cell数量大于0，且没有计算过dataCount属性值，且dataCount值等于元数据的个数
            if (self.expandCellCount > 0 && !isCalculateExpandCellCount && dataCount <= dataSource.count) {
                // 计算cell的总数
                self.dataCount = self.dataCount * self.expandCellCount
                
                // 更新标识
                self.isCalculateExpandCellCount = true
                
                // 刷新
                self.carouselCollection.reloadData()
                
                initCellPosition()
                return
            }
        }
        
        self.isCalculateExpandCellCount = false
    }
    
    /*
     *  MARK: - 初始化cell的位置
     */
    public func initCellPosition() {
        // 设置显示的位置(数据大于1条时，初始滚动到中间位置)
        if dataSource.count <= 1 && startPosition <= 0 {
            return
        }
        
        // 若是循环滑动的话，则初始时先让cell滑动到某一位置
        if startPosition > 0 && startPosition < dataCount {
            let scrollToIndexPath = IndexPath(item: startPosition, section: section)
            currentIndex = startPosition
            self.carouselCollection.scrollToItem(at: scrollToIndexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
        }
    }
    
    /*
     *  MARK: - 滑动cell时，计算该显示的cell
     */
    fileprivate func fixCellToCenter() {
        // 最小滚动距离（用来确定滚动的距离，从而决定是否滚动到下一页/上一页）
        let dragMinimumDistance = kScreenW / 2.0 - calculateWidth(60.0)
        
        // 判断滚动的方向
        if dragStartX - dragEndX >= dragMinimumDistance {
            // 向右
            currentIndex = currentIndex - 1
        } else if dragEndX - dragStartX >= dragMinimumDistance {
            // 向左
            currentIndex = currentIndex + 1
        }
        
        let maximumIndex = carouselCollection.numberOfItems(inSection: section) - 1
        currentIndex = currentIndex <= 0 ? 0 : currentIndex
        currentIndex = currentIndex >= maximumIndex ? maximumIndex : currentIndex
        
        // 滚动到具体的item，并居中显示
        let indexPath = IndexPath(item: currentIndex, section: section)
        carouselCollection.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
    }
}

/**
 *  按比例计算宽高
 **/
extension CarouselView {
    /*
     *  MARK: - 计算宽度
     *
     *  @param actualWidth: 实际的宽度
     *  return 返回计算的宽度
     */
    fileprivate func calculateWidth(_ actualWidth: CGFloat) -> CGFloat {
        return (actualWidth * kScreenW / 375.0)
    }
    
    /*
     *  MARK: - 计算高度
     *
     *  @param actualHeight: 实际的高度
     *  return 返回计算的高度
     */
    fileprivate func calculateHeight(_ actualHeight: CGFloat) -> CGFloat {
        return (actualHeight * kScreenH / 667.0)
    }
}
