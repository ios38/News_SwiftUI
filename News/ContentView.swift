//
//  ContentView.swift
//  News
//
//  Created by Maksim Romanov on 28.05.2021.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var articlesViewModel: ArticlesViewModel

    var body: some View {
        List(articlesViewModel.articles) {article in
            Text(article.title)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
