//
//  AppStartViewModel.swift
//  Block-Jack
//

import Foundation
import Combine

final class AppStartViewModel: ObservableObject {
    
    @Published var isLoading: Bool = true
    @Published var initializationComplete: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startInitialization()
    }
    
    func startInitialization() {
        // Uygulama açılışında yapılacak kontroller (Dil, Ayarlar, Kayıtlı Oyun vb.)
        isLoading = true
        
        // Simülasyon: 1.5 saniye sonra yükleme tamamlanır
        Just(true)
            .delay(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isLoading = false
                self?.initializationComplete = true
            }
            .store(in: &cancellables)
    }
}
