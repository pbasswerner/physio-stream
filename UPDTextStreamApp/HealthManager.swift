//
//  HealthManager.swift
//  UPDTextStreamApp
//
//  Created by Paula Basswerner on 11/14/24.
//


import HealthKit

class HealthManager {
    var healthStore = HKHealthStore()
    //var workoutSession: HKWorkoutSession?
    //var workoutBuilder: HKLiveWorkoutBuilder?
    var heartRateQuery: HKAnchoredObjectQuery?
    
    
    func requestHealthKitAccess() {
        // Request permission to access heart rate data
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { (success, error) in
            if success {
                print("HealthKit authorization approved")
                //on health kit request approved? -> enable buttons and port info for connecting
            } else if let error = error {
                print("HealthKit authorization error: \(error)")
            }
        }
    }
    
    func startHeartRateQuery() {
        // Start the workout session
        //startWorkoutSession()
        print("Start Heart rate Query from manager started")
        // Define the heart rate type
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        // Create the anchored query for real-time heart rate monitoring
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
            self.processHeartRateSamples(samples)
        }
        
        // Set the update handler to receive real-time data
        query.updateHandler = { (query, samples, deletedObjects, anchor, error) in
            self.processHeartRateSamples(samples)
        }
        
        // Execute the query
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    
    
    func processHeartRateSamples(_ samples: [HKSample]?) {
        print("process heart rate called")
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        for sample in heartRateSamples {
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            let timestamp = sample.startDate
           
            print("HR: \(heartRate) at \(timestamp)")
        }
    }
    
    func outputHeartRateSampleDetails(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            print("No heart rate samples available.")
            return
        }

        for sample in heartRateSamples {
            // Heart rate value in beats per minute (bpm)
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            
            // Sample timestamps
            let startDate = sample.startDate
            let endDate = sample.endDate
            
            // Source (e.g., device or app that provided the data)
            let source = sample.sourceRevision.source.name
            
            // Optional metadata that may contain additional info
            let metadata = sample.metadata ?? [:]
            
            // Print sample details
            print("Heart Rate Sample:")
            print("  Heart Rate: \(heartRate) bpm")
            print("  Start Date: \(startDate)")
            print("  End Date: \(endDate)")
            print("  Source: \(source)")
            
            // Print metadata if available
            if !metadata.isEmpty {
                print("  Metadata:")
                for (key, value) in metadata {
                    print("    \(key): \(value)")
                }
            } else {
                print("  Metadata: None")
            }
            
            print("-----------------------------")
        }
    }
}


//    private func startWorkoutSession() {
//        // Define the workout configuration for indoor running
//        let configuration = HKWorkoutConfiguration()
//        configuration.activityType = .running
//        configuration.locationType = .indoor
//
//        // Initialize the workout session
//        do {
//            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
//            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
//            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
//
//            workoutSession?.delegate = self
//            workoutBuilder?.delegate = self
//
//            // Start the workout session and builder
//            workoutSession?.startActivity(with: Date())
//            workoutBuilder?.beginCollection(withStart: Date(), completion: { (success, error) in
//                if success {
//                    print("Workout session started.")
//                } else if let error = error {
//                    print("Failed to start workout session: \(error.localizedDescription)")
//                }
//            })
//        } catch {
//            print("Could not start workout session: \(error.localizedDescription)")
//        }
//    }

//// Add extensions to conform to HKWorkoutSessionDelegate and HKLiveWorkoutBuilderDelegate
//extension HealthManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
//    
//    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
//        print("Workout session failed: \(error.localizedDescription)")
//    }
//    
//    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
//        switch toState {
//        case .running:
//            print("Workout session is running.")
//        case .ended:
//            print("Workout session ended.")
//        default:
//            break
//        }
//    }
//    
//    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
//        // Called when workout builder collects an event (e.g., pause/resume)
//    }
//}
