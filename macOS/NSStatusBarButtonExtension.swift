import AppKit

extension NSStatusBarButton {
    open override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        NSApp.sendAction(#selector(AppDelegate.dragEntered(_:)), to: nil, from: sender)
        
        return .copy
    }

    open override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        NSApp.sendAction(#selector(AppDelegate.prepareDrag(_:)), to: nil, from: sender)
        
        if NSURL.init(from: sender.draggingPasteboard)?.standardized != nil {
            return true
        } else {
            return false
        }
    }

    open override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        NSApp.sendAction(#selector(AppDelegate.performDrag(_:)), to: nil, from: sender)

        return true
    }
    
    open override func draggingExited(_ sender: NSDraggingInfo?) {
        NSApp.sendAction(#selector(AppDelegate.dragExit(_:)), to: nil, from: nil)
    }
}
