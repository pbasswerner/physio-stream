//
//  DataManager.swift
//  UPDTextStreamApp
//
//  Created by Paula Basswerner on 11/19/24.
//

import Foundation


class DataManager {
    static let shared = DataManager()
    private let fileName = "appraisals.json"
    
    private var appraisals: [AppraisalEntry] = []
    
    private init() {
        loadAppraisals()
    }
    
    // Save a new entry
    func saveAppraisal(_ entry: AppraisalEntry) {
        appraisals.append(entry)
        saveToDisk()
    }
    
    // Retrieve all entries
    func getAppraisals() -> [AppraisalEntry] {
        return appraisals
    }
    
    // Clear saved data
    func clearAppraisals() {
        appraisals.removeAll()
        saveToDisk()
    }
    
    // Load from disk
    private func loadAppraisals() {
        let fileURL = getFileURL()
        if let data = try? Data(contentsOf: fileURL),
           let savedAppraisals = try? JSONDecoder().decode([AppraisalEntry].self, from: data) {
            appraisals = savedAppraisals
        }
    }
    
    // Save to disk
    private func saveToDisk() {
        let fileURL = getFileURL()
        if let data = try? JSONEncoder().encode(appraisals) {
            try? data.write(to: fileURL)
        }
    }
    
    // Get file URL in the app's documents directory
    private func getFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(fileName)
    }
}
