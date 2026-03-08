//
//  Toast.swift
//  File Cloud (iOS)
//
//  Created by Mike Skalnik on 3/22/24.
//

import SwiftUI

struct Toast: View {
    var loading: Bool?
    var image: String?
    var message: String?
    
    var body: some View {
        HStack {
            if (loading != nil && loading!) {
                ProgressView()
                    .padding(1)
                    .colorInvert()
            }
            if (image != nil) {
                Image(systemName: image!).colorInvert()
            }
            if (message != nil) {
                Text(message!).font(.headline).colorInvert()
            }
        }
        .padding()
        .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .opacity(0.8)
        )
        .transition(.opacity)
    }
}

#Preview("Loader") {
    Toast(loading: true)
}
#Preview("Loader w/text") {
    Toast(loading: true, message: "Progress…")
}
#Preview("Generic") {
    Toast(message: "Generic")
}
#Preview("With Image") {
    Toast(image: "checkmark.circle", message: "Success")
}
