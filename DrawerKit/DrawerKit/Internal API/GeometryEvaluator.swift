import UIKit

struct GeometryEvaluator {
    
    static func drawerFullY(configuration: DrawerConfiguration) -> CGFloat {
        switch configuration.fullExpansionBehaviour {
        case .coversFullScreen:
            return 0
        case .doesNotCoverStatusBar:
            return DrawerGeometry.statusBarHeight
        case let .leavesCustomGap(gap):
            return gap
        }
    }
    
    static func drawerPartialH(drawerPartialHeight: CGFloat,
                               containerViewHeight: CGFloat) -> CGFloat {
        return min(max(drawerPartialHeight, 0), containerViewHeight)
    }

    static func drawerPartialY(drawerPartialHeight: CGFloat,
                               containerViewHeight: CGFloat) -> CGFloat {
        let partialH = drawerPartialH(drawerPartialHeight: drawerPartialHeight,
                                      containerViewHeight: containerViewHeight)
        return containerViewHeight - partialH
    }

    static func upperMarkY(drawerPartialHeight: CGFloat,
                           containerViewHeight: CGFloat,
                           configuration: DrawerConfiguration) -> CGFloat {
        let fullY = drawerFullY(configuration: configuration)
        let partialY = drawerPartialY(drawerPartialHeight: drawerPartialHeight,
                                      containerViewHeight: containerViewHeight)
        return max(partialY - configuration.upperMarkGap, fullY)
    }

    static func lowerMarkY(drawerPartialHeight: CGFloat,
                           containerViewHeight: CGFloat,
                           configuration: DrawerConfiguration) -> CGFloat {
        let partialY = drawerPartialY(drawerPartialHeight: drawerPartialHeight,
                                      containerViewHeight: containerViewHeight)
        return min(partialY + configuration.lowerMarkGap, containerViewHeight)
    }

    static func clamped(_ positionY: CGFloat,
                        drawerPartialHeight: CGFloat,
                        containerViewHeight: CGFloat,
                        configuration: DrawerConfiguration) -> CGFloat {
        let fullY = drawerFullY(configuration: configuration)
        let upperY = upperMarkY(drawerPartialHeight: drawerPartialHeight,
                                containerViewHeight: containerViewHeight,
                                configuration: configuration)
        if smallerThanOrEqual(positionY, upperY) {
            return fullY
        }

        let lowerY = lowerMarkY(drawerPartialHeight: drawerPartialHeight,
                                containerViewHeight: containerViewHeight,
                                configuration: configuration)
        if greaterThanOrEqual(positionY, lowerY) {
            return containerViewHeight
        }

        let partialY = drawerPartialY(drawerPartialHeight: drawerPartialHeight,
                                      containerViewHeight: containerViewHeight)
        if smallerThanOrEqual(positionY, partialY) {
            return (configuration.supportsPartialExpansion ? partialY : fullY)
        } else {
            return (configuration.supportsPartialExpansion ? partialY : containerViewHeight)
        }
    }
}

extension GeometryEvaluator {
    static func drawerState(for positionY: CGFloat,
                            drawerPartialHeight: CGFloat,
                            containerViewHeight: CGFloat,
                            configuration: DrawerConfiguration,
                            clampToNearest: Bool = false) -> DrawerState {
        let fullY = drawerFullY(configuration: configuration)
        if smallerThanOrEqual(positionY, fullY) { return .fullyExpanded }
        if greaterThanOrEqual(positionY, containerViewHeight) { return .collapsed }

        let partialY = drawerPartialY(drawerPartialHeight: drawerPartialHeight,
                                      containerViewHeight: containerViewHeight)
        if equal(positionY, partialY) { return .partiallyExpanded }

        if clampToNearest {
            let posY = clamped(positionY,
                               drawerPartialHeight: drawerPartialHeight,
                               containerViewHeight: containerViewHeight,
                               configuration: configuration)
            return drawerState(for: posY,
                               drawerPartialHeight: drawerPartialHeight,
                               containerViewHeight: containerViewHeight,
                               configuration: configuration)
        } else {
            return .transitioning(currentDrawerY: positionY)
        }
    }

    static func drawerPositionY(for state: DrawerState,
                                drawerPartialHeight: CGFloat,
                                containerViewHeight: CGFloat,
                                drawerFullY: CGFloat) -> CGFloat {
        switch state {
        case .collapsed:
            return containerViewHeight
        case .partiallyExpanded:
            return drawerPartialY(drawerPartialHeight: drawerPartialHeight,
                                  containerViewHeight: containerViewHeight)
        case .fullyExpanded:
            return drawerFullY
        case let .transitioning(positionY):
            return positionY
        }
    }

    static func nextStateFrom(currentState: DrawerState,
                              speedY: CGFloat,
                              drawerPartialHeight: CGFloat,
                              containerViewHeight: CGFloat,
                              configuration: DrawerConfiguration) -> DrawerState {
        let isNotMoving = (speedY == 0)
        let isMovingUp = (speedY < 0) // recall that Y-axis points down
        let isMovingDown = (speedY > 0)

        let flickSpeedThreshold = configuration.flickSpeedThreshold
        let isMovingQuickly = (flickSpeedThreshold != 0) && (abs(speedY) > flickSpeedThreshold)
        let isMovingUpQuickly = isMovingUp && isMovingQuickly
        let isMovingDownQuickly = isMovingDown && isMovingQuickly

        let fullY = drawerFullY(configuration: configuration)

        let positionY = drawerPositionY(for: currentState,
                                        drawerPartialHeight: drawerPartialHeight,
                                        containerViewHeight: containerViewHeight,
                                        drawerFullY: fullY)

        let upperY = upperMarkY(drawerPartialHeight: drawerPartialHeight,
                                containerViewHeight: containerViewHeight,
                                configuration: configuration)

        let lowerY = lowerMarkY(drawerPartialHeight: drawerPartialHeight,
                                containerViewHeight: containerViewHeight,
                                configuration: configuration)

        let isAboveUpperMark = (positionY < upperY)
        let isAboveLowerMark = (positionY < lowerY)

        let supportsPartialExpansion = configuration.supportsPartialExpansion
        let dismissesInStages = configuration.dismissesInStages

        // === RETURN LOGIC STARTS HERE === //

        if isMovingUpQuickly { return .fullyExpanded }
        if isMovingDownQuickly { return .collapsed }

        if isAboveUpperMark {
            if isMovingUp || isNotMoving {
                return .fullyExpanded
            } else { // isMovingDown
                let inStages = supportsPartialExpansion && dismissesInStages
                return inStages ? .partiallyExpanded : .collapsed
            }
        }

        if isAboveLowerMark {
            if isMovingDown {
                return .collapsed
            } else { // isMovingUp || isNotMoving
                return (supportsPartialExpansion ? .partiallyExpanded : .fullyExpanded)
            }
        }

        return .collapsed
    }
}
