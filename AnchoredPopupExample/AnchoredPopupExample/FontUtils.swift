//
//  FontUtils.swift
//  ExyteApp
//
//  Created by Alisa Mylnikova on 26.10.2023.
//

import SwiftUI

extension Text {
    func chakra(_ size: CGFloat, _ color: Color = .black) -> some View {
        self.font(.custom("ChakraPetch-Regular", size: size))
            .foregroundStyle(color)
    }

    func chakraMedium(_ size: CGFloat, _ color: Color = .black) -> some View {
        self.font(.custom("ChakraPetch-Medium", size: size))
            .foregroundStyle(color)
    }

    func plex(_ size: CGFloat, _ color: Color = .black) -> some View {
        self.font(.custom("IBMPlexMono-Regular", size: size))
            .foregroundStyle(color)
    }

    func plexMedium(_ size: CGFloat, _ color: Color = .black) -> some View {
        self.font(.custom("IBMPlexMono-Medium", size: size))
            .foregroundStyle(color)
    }

    func plexBold(_ size: CGFloat, _ color: Color = .black) -> some View {
        self.font(.custom("IBMPlexMono-Bold", size: size))
            .foregroundStyle(color)
    }
}
