//
//  UploadView.swift
//  File Cloud
//
//  Created by Mike Skalnik on 6/11/22.
//

import SwiftUI

struct UploadView: View {
    @State private var showingPhotoLibrary = false
    @State private var image = UIImage()
    
    var body: some View {
        VStack {
            Button(action: {
                self.showingPhotoLibrary = true
            }) {
                Image(systemName: "photo")
                Text("Upload from Photos")
            }
            .modifier(BigButtonModifier())
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$image)
        }
    }
}

struct BigButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 60)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
            .font(.title)
            .padding(.horizontal)
    }
}

struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}
