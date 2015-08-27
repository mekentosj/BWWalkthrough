/*
The MIT License (MIT)
Copyright (c) 2015 Yari D'areglia @bitwaker
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import UIKit

//  MARK: Walkthrough View Controller
@objc class BWWalkthroughViewController: UIViewController {
    
    //  MARK: Properties - State
    
    /** Index of the current page.  */
    var currentPage: Int {
        get{
            let page = Int((scrollView.contentOffset.x / view.bounds.size.width))
            return page
        }
    }
    /// Object interested in updates to the walkthrough, such as switching pages, or closing it.
    weak var delegate: BWWalkthroughViewControllerDelegate?
    /// Title for 'close' button when the end of the walkthrough has been reached.
    var finalCloseButtonTitle: String?
    /// The close button title pulled from the storyboard.
    private var standardCloseButtonTitle: String?
    /// The view controllers for the views in our scroll view.
    private var controllers = [UIViewController]()
    /// The last horizontal layout constraint for the last view in the scroll view to the right edge of the scroll view
    private var lastViewConstraint:NSArray?
    
    //  MARK: Properties - Subviews
    
    /// The button that allows for closing the walkthough.
    @IBOutlet var closeButton: UIButton?
    /// A control that shows the user which page they are on relative to the other pages / total number of pages
    @IBOutlet var pageControl:UIPageControl?
    /// A button that navigates the scroll view back to the previous page.
    @IBOutlet var prevButton:UIButton?
    /// A button that navigates the scroll view to the next page.
    @IBOutlet var nextButton:UIButton?
    /// A scroll view containing the walkthrough pages.
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        
        scrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.pagingEnabled = true
        scrollView.keyboardDismissMode = .OnDrag
        
        return scrollView
    }()
    
    //	MARK: View Lifecycle
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //  this needs to happen in viewDidAppear because otherwise the constraints will be incorrect
        updateViewControllers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  inset the scroll view as the first view in the hierarchy
        view.insertSubview(scrollView, atIndex: 0)
        
        //  set up the scroll view to cover the entirety of the main view
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[scrollView]|", options:nil, metrics: nil, views: ["scrollView": scrollView]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrollView]|", options:nil, metrics: nil, views: ["scrollView": scrollView]))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
        scrollView.delegate = self
        
        //  configure page control
        pageControl?.numberOfPages = controllers.count
        pageControl?.currentPage = 0
        
        updateButtons()
    }
    
    //	MARK: Actions
    
    @IBAction private func nextPage() {
        
        if (currentPage + 1) < controllers.count {
            
            delegate?.walkthroughNextButtonPressed?()
            
            var frame = scrollView.frame
            frame.origin.x = CGFloat(currentPage + 1) * frame.size.width
            scrollView.scrollRectToVisible(frame, animated: true)
        }
    }
    
    @IBAction private func prevPage() {
        
        if currentPage > 0 {
            
            delegate?.walkthroughPrevButtonPressed?()
            
            var frame = scrollView.frame
            frame.origin.x = CGFloat(currentPage - 1) * frame.size.width
            scrollView.scrollRectToVisible(frame, animated: true)
        }
    }
    
    @IBAction private func close(sender: AnyObject){
        delegate?.walkthroughCloseButtonPressed?()
    }
    
    //	MARK: Walkthrough Page Management
    
    /**
        Updates the scroll view with the current view controllers to be displayed.
     */
    private func updateViewControllers() {
        
        if scrollView.bounds == CGRect.zeroRect {
            return
        }
        
        scrollView.removeConstraints(scrollView.constraints())
        (scrollView.subviews as! [UIView]).map { $0.removeFromSuperview() }
        
        let metrics = ["w": scrollView.bounds.width, "h": scrollView.bounds.height]
        
        for viewControllerIndex in 0..<controllers.count {
            let viewController = controllers[viewControllerIndex]
            let view = viewController.view
            
            view.setTranslatesAutoresizingMaskIntoConstraints(false)
            view.removeHeightWidthConstraints()
            scrollView.addSubview(view)
            
            let viewsDictionary = ["view": view]
            
            //  define height and width
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[view(h)]", options:nil, metrics: metrics, views: viewsDictionary))
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[view(w)]", options:nil, metrics: metrics, views: viewsDictionary))
            
            //  define scroll view content size vertically
            scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options:nil, metrics: nil, views: viewsDictionary))
            
            //  position first view at beginning of scroll view
            if viewControllerIndex == 0 {
                scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]", options:nil, metrics: nil, views: viewsDictionary))
            } else {
                //  position subsequent views after the previous view
                let previousViewController = controllers[viewControllerIndex - 1]
                let previousView = previousViewController.view
                
                scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[previousView][view]", options:nil, metrics: nil, views: ["previousView": previousView, "view": view]))
                
                //  if we added the 'final constraints' before, we remove them
                if let finalConstraints = lastViewConstraint {
                    scrollView.removeConstraints(finalConstraints as [AnyObject])
                }
                
                lastViewConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:[view]|", options: nil, metrics: nil, views: viewsDictionary)
                scrollView.addConstraints(lastViewConstraint! as [AnyObject])
            }
        }
        
        view.updateConstraintsIfNeeded()
    }
    
    /**
        Adds a new page to the walkthrough.
    
        :param: viewController      A view controller which manages a view to be added as a page to the walkthrough.
    */
    func addViewController(viewController: UIViewController) {
        
        controllers.append(viewController)
        
        updateViewControllers()
    }
    
    /**
        Update the UI to reflect the current walkthrough situation.
    **/
    
    private func updateUI(){
        
        //  get the current page
        
        pageControl?.currentPage = currentPage
        
        //  notify delegate about the new page
        
        delegate?.walkthroughPageDidChange?(currentPage)
        
        //  hide / show navigation buttons
        
        updateButtons()
    }
    
    /**
        Updates navigation and control buttons (next / previous / close)
    */
    private func updateButtons() {
        
        nextButton?.hidden = currentPage == controllers.count - 1
        
        if currentPage == 0 {
            prevButton?.hidden = true
        } else {
            prevButton?.hidden = false
        }
        
        if let finalTitle = finalCloseButtonTitle {
            
            if standardCloseButtonTitle == nil {
                standardCloseButtonTitle = closeButton?.titleLabel?.text
            }
            
            let title = currentPage == controllers.count - 1 ? finalTitle : standardCloseButtonTitle
            closeButton?.setTitle(title, forState: .Normal)
        }
    }
}

//  MARK: UIScrollViewDelegate Methods
extension BWWalkthroughViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(sv: UIScrollView) {
        
        for var i=0; i < controllers.count; i++ {
            
            if let vc = controllers[i] as? BWWalkthroughPage{
                
                let mx = ((scrollView.contentOffset.x + view.bounds.size.width) - (view.bounds.size.width * CGFloat(i))) / view.bounds.size.width
                
                // While sliding to the "next" slide (from right to left), the "current" slide changes its offset from 1.0 to 2.0 while the "next" slide changes it from 0.0 to 1.0
                // While sliding to the "previous" slide (left to right), the current slide changes its offset from 1.0 to 0.0 while the "previous" slide changes it from 2.0 to 1.0
                // The other pages update their offsets whith values like 2.0, 3.0, -2.0... depending on their positions and on the status of the walkthrough
                // This value can be used on the previous, current and next page to perform custom animations on page's subviews.
                
                // print the mx value to get more info.
                // println("\(i):\(mx)")
                
                // We animate only the previous, current and next page
                if(mx < 2 && mx > -2.0){
                    vc.walkthroughDidScroll(scrollView.contentOffset.x, offset: mx)
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        updateUI()
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        updateUI()
    }
}

extension BWWalkthroughViewController: WalkthroughPageDelegate {
    func walkthroughPageRequestsDismissal(walkthroughPage: BWWalkthroughPage) {
        close(self)
    }
}

extension UIView {
    func removeHeightWidthConstraints() {
        for constraint in constraints() as! [NSLayoutConstraint] {
            if constraint.firstAttribute == .Width || constraint.secondAttribute == .Width ||
                constraint.firstAttribute == .Height || constraint.secondAttribute == .Height {
                    removeConstraint(constraint)
            }
        }
    }
}
