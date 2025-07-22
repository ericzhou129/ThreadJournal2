//
//  ShareSheet.swift
//  ThreadJournal2
//
//  UIActivityViewController wrapper for SwiftUI to share files
//

import SwiftUI
import UIKit

/// SwiftUI wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var onDismiss: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}