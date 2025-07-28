//
//  ThreadJournal2App.swift
//  ThreadJournal2
//
//  Created by Eric Zhou on 2025-07-17.
//

import SwiftUI

@main
struct ThreadJournal2App: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ThreadListView(viewModel: makeThreadListViewModel())
        }
    }
    
    private func makeThreadListViewModel() -> ThreadListViewModel {
        let repository = persistenceController.makeThreadRepository()
        let createThreadUseCase = CreateThreadUseCase(repository: repository)
        let deleteThreadUseCase = DeleteThreadUseCaseImpl(repository: repository)
        
        return ThreadListViewModel(
            repository: repository,
            createThreadUseCase: createThreadUseCase,
            deleteThreadUseCase: deleteThreadUseCase
        )
    }
}
