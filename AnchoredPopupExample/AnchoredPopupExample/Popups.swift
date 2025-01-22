//
//  Popups.swift
//  AnchoredPopupExample
//
//  Created by Alisa Mylnikova on 22.01.2025.
//

import SwiftUI

struct MainMenuView: View {

    var body: some View {
        ZStack {
            Color.popupDarkViolet
                .cornerRadius(30)

            VStack(alignment: .leading, spacing: 0) {
                Label {
                    Text("Start workout").chakra(15, .white)
                } icon: {
                    Image(.mainMenuDumbbell)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)

                Color.popupViolet.frame(height: 1)
                    .padding(16, 12)

                Label {
                    Text("Record your exercises ").chakra(15, .white)
                } icon: {
                    Image(.mainMenuCamera)
                }
                .padding(.horizontal, 20)

                Color.popupViolet.frame(height: 1)
                    .padding(16, 12)

                Label {
                    Text("Watch lesson").chakra(15, .white)
                } icon: {
                    Image(.mainMenuLibrary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                ZStack{
                    Circle().foregroundStyle(.popupViolet)
                        .size(60)
                    Image(.cross)
                }
            }
        }
        .fixedSize()
    }
}
