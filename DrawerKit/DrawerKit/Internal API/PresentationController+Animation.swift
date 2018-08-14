import UIKit

extension PresentationController {
    func animateTransition(to endingState: DrawerState, animateAlongside: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        let startingState = currentDrawerState
        
        let endingDimmingViewAlpha = dimmingViewAlpha(at: endingState)
        
        let (startingPositionY, endingPositionY) = positionsY(startingState: startingState,
                                                              endingState: endingState)

        let animator = makeAnimator(startingPositionY: startingPositionY,
                                    endingPositionY: endingPositionY)

        let presentingVC = presentingViewController
        let presentedVC = presentedViewController

        let presentedViewFrame = presentedView?.frame ?? .zero

        var startingFrame = presentedViewFrame
        startingFrame.origin.y = startingPositionY

        var endingFrame = presentedViewFrame
        endingFrame.origin.y = endingPositionY

        let geometry = AnimationSupport.makeGeometry(containerBounds: containerViewBounds,
                                                     startingFrame: startingFrame,
                                                     endingFrame: endingFrame,
                                                     presentingVC: presentingVC,
                                                     presentedVC: presentedVC)

        let info = AnimationSupport.makeInfo(startDrawerState: startingState,
                                             targetDrawerState: endingState,
                                             configuration,
                                             geometry,
                                             animator.duration,
                                             endingPositionY < startingPositionY)

        let endingHandleViewAlpha = handleViewAlpha(at: endingState)
        let autoAnimatesDimming = configuration.handleViewConfiguration?.autoAnimatesDimming ?? false
        if autoAnimatesDimming { self.handleView?.alpha = handleViewAlpha(at: startingState) }

        let presentingAnimationActions = self.presentingDrawerAnimationActions
        let presentedAnimationActions = self.presentedDrawerAnimationActions

        AnimationSupport.clientPrepareViews(presentingDrawerAnimationActions: presentingAnimationActions,
                                            presentedDrawerAnimationActions: presentedAnimationActions,
                                            info)

        targetDrawerState = endingState

        animator.addAnimations {
            self.currentDrawerY = endingPositionY
            if autoAnimatesDimming { self.handleView?.alpha = endingHandleViewAlpha }
            if self.backgroundDimmingAlpha != 0 { self.dimmingView?.alpha = endingDimmingViewAlpha }
            AnimationSupport.clientAnimateAlong(presentingDrawerAnimationActions: presentingAnimationActions,
                                                presentedDrawerAnimationActions: presentedAnimationActions,
                                                info)
            animateAlongside?()
        }

        animator.addCompletion { endingPosition in
            if autoAnimatesDimming { self.handleView?.alpha = endingHandleViewAlpha }

            let isStartingStateCollapsed = (startingState == .collapsed)
            let isEndingStateCollapsed = (endingState == .collapsed)

            let shouldDismiss =
                (isStartingStateCollapsed && endingPosition == .start) ||
                    (isEndingStateCollapsed && endingPosition == .end)

            if shouldDismiss {
                self.presentedViewController.dismiss(animated: true)
            }

            if endingPosition != .end {
                self.targetDrawerState = GeometryEvaluator.drawerState(for: self.currentDrawerY,
                                                                       drawerPartialHeight: self.drawerPartialY,
                                                                       containerViewHeight: self.containerViewHeight,
                                                                       configuration: self.configuration)
            }

            AnimationSupport.clientCleanupViews(presentingDrawerAnimationActions: presentingAnimationActions,
                                                presentedDrawerAnimationActions: presentedAnimationActions,
                                                endingPosition,
                                                info)

            completion?()
        }

        animator.startAnimation()
    }
    
    func addBackgroundDimmingAnimationEnding(at endingState: DrawerState) {
        guard backgroundDimmingAlpha != 0
            && drawerPartialY != drawerFullY
            && endingState != currentDrawerState
            else { return }
        
        let startingState = currentDrawerState
        let (startingPositionY, endingPositionY) = positionsY(startingState: startingState,
                                                              endingState: endingState)
        
        let animator = makeAnimator(startingPositionY: startingPositionY,
                                    endingPositionY: endingPositionY)
        
        let endingDimmingViewAlpha = dimmingViewAlpha(at: endingState)
        animator.addAnimations {
            self.dimmingView?.alpha = endingDimmingViewAlpha
        }
        
        animator.startAnimation()
    }

    private func makeAnimator(startingPositionY: CGFloat,
                              endingPositionY: CGFloat) -> UIViewPropertyAnimator {
        let duration =
            AnimationSupport.actualTransitionDuration(from: startingPositionY,
                                                      to: endingPositionY,
                                                      containerViewHeight: containerViewHeight,
                                                      configuration: configuration)

        return UIViewPropertyAnimator(duration: duration,
                                      timingParameters: timingCurveProvider)
    }

    private func positionsY(startingState: DrawerState,
                            endingState: DrawerState) -> (starting: CGFloat, ending: CGFloat) {
        let startingPositionY =
            GeometryEvaluator.drawerPositionY(for: startingState,
                                              drawerPartialHeight: drawerPartialHeight,
                                              containerViewHeight: containerViewHeight,
                                              drawerFullY: drawerFullY)

        let endingPositionY =
            GeometryEvaluator.drawerPositionY(for: endingState,
                                              drawerPartialHeight: drawerPartialHeight,
                                              containerViewHeight: containerViewHeight,
                                              drawerFullY: drawerFullY)

        return (startingPositionY, endingPositionY)
    }
}
