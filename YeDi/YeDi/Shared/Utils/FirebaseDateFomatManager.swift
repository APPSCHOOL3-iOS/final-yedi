//
//  SingleTonDate.swift
//  YeDi
//
//  Created by 김성준 on 10/10/23.
//

import Foundation

final class FirebaseDateFomatManager {
    static var sharedDateFommatter: FirebaseDateFomatManager = FirebaseDateFomatManager()
    
    private init() {}
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter
    }()
    
    /// 지정한 dateformat 형식으로 DateInstace 반환 Method
    /// - Parameter from: 변환하고자 하는 Date형식의 string값
    /// - Parameter String: "yyyy-MM-dd'T'HH:mm:ssZ" 형식(Firebase date format)의  String
    /// - Returns: 라미터로 전달된 foramt String, 변환 실패시 ISO8601형식의 현재 날짜 반환
    func changeDateString(transition format: String, from string: String) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = dateFormatter.date(from: string) {
            dateFormatter.dateFormat = format
            return dateFormatter.string(from: date)
        } else {
            return dateFormatter.string(from: Date())
        }
    }
    
    /// 날짜형식의 스트링을 Date로 변환
    /// - Parameter date: ISO8601 형식(yyyy-MM-dd'T'HH:mm:ssZ) DateString
    ///  - Returns: 변환 실패시 현재날짜 기준 Date 인스턴스 반환
    func changeStringToDate(dateString: String) -> Date {
        if let date = dateFormatter.date(from: dateString) {
            return date
        } else {
            return Date()
        }
    }
    
    /// Firebase 날짜 포맷 Method
    ///  - Returns: ISO8601 형식(yyyy-MM-dd'T'HH:mm:ssZ) DateFormatter 반환
    func firebaseDateFormat() -> DateFormatter {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }
    
    /// Firebase에 저장할 Date 포맷에 맞는 String 반환 Method
    /// - Parameter date: date Instance
    /// - Returns date String: ISO8601 형식(yyyy-MM-dd'T'HH:mm:ssZ) date String
    func firebaseDate(from date: Date) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.string(from: date)
    }
}
