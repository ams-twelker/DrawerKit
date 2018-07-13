import UIKit

extension PresentationController {
    
    var containerViewBounds: CGRect {
        return containerView?.bounds ?? .zero
    }

    var containerViewSize: CGSize {
        return containerViewBounds.size
    }
    
    var drawerFullY: CGFloat {
        return GeometryEvaluator.drawerFullY(configuration: configuration)
    }

    var containerViewHeight: CGFloat {
        return containerViewSize.height
    }

    var drawerPartialHeight: CGFloat {
        guard let presentedVC = presentedViewController as? DrawerPresentable else { return 0 }
        let drawerPartialH = presentedVC.heightOfPartiallyExpandedDrawer
        return GeometryEvaluator.drawerPartialH(drawerPartialHeight: drawerPartialH,
                                                containerViewHeight: containerViewHeight)
    }

    var drawerPartialY: CGFloat {
        return GeometryEvaluator.drawerPartialY(drawerPartialHeight: drawerPartialHeight,
                                                containerViewHeight: containerViewHeight)
    }

    var upperMarkY: CGFloat {
        return GeometryEvaluator.upperMarkY(drawerPartialHeight: drawerPartialHeight,
                                            containerViewHeight: containerViewHeight,
                                            configuration: configuration)
    }

    var lowerMarkY: CGFloat {
        return GeometryEvaluator.lowerMarkY(drawerPartialHeight: drawerPartialHeight,
                                            containerViewHeight: containerViewHeight,
                                            configuration: configuration)
    }

    var currentDrawerState: DrawerState {
        get {
            return GeometryEvaluator.drawerState(for: currentDrawerY,
                                                 drawerPartialHeight: drawerPartialHeight,
                                                 containerViewHeight: containerViewHeight,
                                                 configuration: configuration)
        }

        set {
            currentDrawerY =
                GeometryEvaluator.drawerPositionY(for: newValue,
                                                  drawerPartialHeight: drawerPartialHeight,
                                                  containerViewHeight: containerViewHeight,
                                                  drawerFullY: drawerFullY)
        }
    }

    var currentDrawerY: CGFloat {
        get {
            let posY = presentedView?.frame.origin.y ?? drawerFullY
            return min(max(posY, drawerFullY), containerViewHeight)
        }

        set {
            let posY = min(max(newValue, drawerFullY), containerViewHeight)
            presentedView?.frame.origin.y = posY
        }
    }
    
    func dimmingViewAlpha(at state: DrawerState) -> CGFloat {
        return backgroundDimmingAlpha * linearValue(at: state, from: .collapsed, to: .partiallyExpanded)
    }
    
    func handleViewAlpha(at state: DrawerState) -> CGFloat {
        return triangularValue(at: state)
    }

    private func triangularValue(at state: DrawerState) -> CGFloat {
        guard drawerPartialY != drawerFullY
            && drawerPartialY != containerViewHeight
            && drawerFullY != containerViewHeight
            else { return 0 }

        let positionY =
            GeometryEvaluator.drawerPositionY(for: state,
                                              drawerPartialHeight: drawerPartialHeight,
                                              containerViewHeight: containerViewHeight,
                                              drawerFullY: drawerFullY)

        let fraction: CGFloat
        if supportsPartialExpansion {
            if positionY < drawerPartialY {
                fraction = (positionY - drawerFullY) / (drawerPartialY - drawerFullY)
            } else {
                fraction = 1 - (positionY - drawerPartialY) / (containerViewHeight - drawerPartialY)
            }
        } else {
            fraction = 1 - (positionY - drawerFullY) / (containerViewHeight - drawerFullY)
        }

        return fraction
    }
    
    private func linearValue(at state: DrawerState, from beginningState: DrawerState, to endingState: DrawerState) -> CGFloat {
        let positionY = GeometryEvaluator.drawerPositionY(for: state,
                                                          drawerPartialHeight: drawerPartialHeight,
                                                          containerViewHeight: containerViewHeight,
                                                          drawerFullY: drawerFullY)
        
        let beginningY: CGFloat
        switch beginningState {
        case .collapsed:
            beginningY = containerViewHeight
        case .partiallyExpanded:
            beginningY = drawerPartialY
        case .fullyExpanded:
            beginningY = drawerFullY
        case .transitioning(_):
            assertionFailure("Beginning state cannot be transitioning")
            return 0
        }
        
        let endingY: CGFloat
        switch endingState {
        case .collapsed:
            endingY = containerViewHeight
        case .partiallyExpanded:
            endingY = drawerPartialY
        case .fullyExpanded:
            endingY = drawerFullY
        case .transitioning(_):
            assertionFailure("Ending state cannot be transitioning")
            return 0
        }
        
        let fraction: CGFloat
        
        if positionY >= beginningY {
            fraction = 0
        } else if positionY <= endingY {
            fraction = 1
        } else {
            fraction = 1 - (endingY - positionY) / (endingY - beginningY)
        }
        
        return fraction
    }
}
