//
//  CMReservationViewModel.swift
//  YeDi
//
//  Created by SONYOONHO on 2023/10/19.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

final class CMReservationViewModel: ObservableObject {
    @Published var dates: [Date] = []
    @Published var openingTime: Int = 0
    @Published var closingTime: Int = 0
    @Published var impossibleTime: Set<Int> = []
    
    private let db = Firestore.firestore()
    private var closedDay: ClosedDay = ClosedDay(id: "", designerUid: "", closedDay: [])
    private var currentUserUid: String? {
        return Auth.auth().currentUser?.uid
    }
    
    func createReservation(reservation: Reservation) async {
        guard let uid = currentUserUid else { return }
        do {
            var updatedReservation = reservation
            updatedReservation.clientUID = uid
            try db.collection("reservations").addDocument(from: updatedReservation)
        } catch {
            print("createReservation Error: \(error)")
        }
    }
    
    @MainActor
    func fetchCalendar(designerUID: String) async {
        do {
            let querySnapshot = try await db.collection("closedDays").whereField("designerUid", isEqualTo: designerUID).getDocuments()
            for document in querySnapshot.documents {
                closedDay = try document.data(as: ClosedDay.self)
            }
            
            for day in closedDay.closedDay {
                let date = FirebaseDateFormatManager.sharedDateFormmatter.changeStringToDate(dateString: day)
                self.dates.append(date)
            }
        } catch {
            print("fetchCalendar Error: \(error)")
        }
    }
    
    @MainActor
    func fetchOperatingTime(designerUID: String) async {
        do {
            let querySnapshot = try await db.collection("designers").document(designerUID).collection("shop").getDocuments()
            
            for document in querySnapshot.documents {
                if let openingHour = document.data()["openingHour"] as? String,
                   let closingHour = document.data()["closingHour"] as? String {
                    self.openingTime = Int(openingHour) ?? 9
                    self.closingTime = Int(closingHour) ?? 21
                }
            }
        } catch {
            print("fetchOperatingTime Error: \(error)")
        }
    }

    @MainActor
    func fetchAvailableReservationTime(date: Date, designerUID: String) async {
        do {
            let startDateString = FirebaseDateFormatManager.sharedDateFormmatter.firebaseDate(from: date)
            let endDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            let endDateString = FirebaseDateFormatManager.sharedDateFormmatter.firebaseDate(from: endDate)
            let querySnapShot = try await db.collection("reservations").whereField("designerUID", isEqualTo: designerUID).whereField("reservationTime", isGreaterThanOrEqualTo: startDateString).whereField("reservationTime", isLessThan: endDateString).getDocuments()
            self.impossibleTime = []
            for document in querySnapShot.documents {
                let reservationTime = try document.data(as: Reservation.self).reservationTime
                guard let hour = extractHoursFromTimeString(reservationTime) else { return }
                self.impossibleTime.insert(hour)
            }
            await fetchBreakTime(designerUID: designerUID)
        } catch {
            
        }
    }
    
    private func fetchBreakTime(designerUID: String) async {
        do {
            let querySnapshot = try await db.collection("breakTimes").whereField("designerUID", isEqualTo: designerUID).getDocuments()
            for document in querySnapshot.documents {
                if let breakTimes = document.data()["selectedTime"] as? [String] {
                    let timeInts = breakTimes.compactMap { timeString in
                        let components = timeString.components(separatedBy: ":")
                        if let hour = Int(components.first ?? "") {
                            return hour
                        } else {
                            return nil
                        }
                    }
                    self.impossibleTime.formUnion(Set(timeInts))
                }
            }
        } catch {
            
        }
    }

    private func extractHoursFromTimeString(_ timeString: String) -> Int? {
       let date = FirebaseDateFormatManager.sharedDateFormmatter.changeStringToDate(dateString: timeString)
            // Calendar를 사용하여 Date에서 시간 구성 요소를 추출
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour], from: date)
            
            if let hour = components.hour {
                return hour
            }
        
        return nil
    }
}
