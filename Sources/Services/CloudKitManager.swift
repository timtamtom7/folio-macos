import Foundation
import CloudKit

final class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.folio.reader")
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Feed Sync
    
    func saveFeed(_ feed: Feed, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let record = CKRecord(recordType: "Feed")
        record["feedId"] = feed.id.uuidString as CKRecordValue
        record["title"] = feed.title as CKRecordValue
        record["url"] = feed.url.absoluteString as CKRecordValue
        record["siteUrl"] = feed.siteUrl?.absoluteString as CKRecordValue?
        record["iconUrl"] = feed.iconUrl?.absoluteString as CKRecordValue?
        record["lastFetchedAt"] = feed.lastFetchedAt.map { $0.timeIntervalSince1970 } as CKRecordValue?
        
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
            } else if let savedRecord = savedRecord {
                completion(.success(savedRecord))
            }
        }
    }
    
    func fetchFeeds(completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let query = CKQuery(recordType: "Feed", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        privateDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 100) { result in
            switch result {
            case .success(let queryResult):
                let records = queryResult.matchResults.compactMap { try? $0.1.get() }
                completion(.success(records))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func deleteFeed(_ feedId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let query = CKQuery(recordType: "Feed", predicate: NSPredicate(format: "feedId == %@", feedId.uuidString))
        
        privateDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { result in
            switch result {
            case .success(let queryResult):
                if let record = queryResult.matchResults.first?.1 {
                    if let fetchedRecord = try? record.get() {
                        self.privateDatabase.delete(withRecordID: fetchedRecord.recordID) { _, error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                completion(.success(()))
                            }
                        }
                    } else {
                        completion(.success(()))
                    }
                } else {
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Annotation Sync
    
    func saveAnnotation(_ annotation: Annotation, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let record = CKRecord(recordType: "Annotation")
        record["annotationId"] = annotation.id.uuidString as CKRecordValue
        record["articleId"] = annotation.articleId.uuidString as CKRecordValue
        record["content"] = annotation.content as CKRecordValue
        record["selectedText"] = annotation.selectedText as CKRecordValue?
        record["highlightColor"] = annotation.highlightColor as CKRecordValue?
        record["createdAt"] = annotation.createdAt as CKRecordValue
        record["updatedAt"] = annotation.updatedAt as CKRecordValue
        
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
            } else if let savedRecord = savedRecord {
                completion(.success(savedRecord))
            }
        }
    }
    
    func fetchAnnotations(completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let query = CKQuery(recordType: "Annotation", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        privateDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 100) { result in
            switch result {
            case .success(let queryResult):
                let records = queryResult.matchResults.compactMap { try? $0.1.get() }
                completion(.success(records))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Read State Sync
    
    func saveReadState(articleId: UUID, isRead: Bool, readAt: Date, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let query = CKQuery(recordType: "ReadState", predicate: NSPredicate(format: "articleId == %@", articleId.uuidString))
        
        privateDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { result in
            switch result {
            case .success(let queryResult):
                let record: CKRecord
                if let existingResult = queryResult.matchResults.first?.1,
                   let existingRecord = try? existingResult.get() {
                    record = existingRecord
                } else {
                    record = CKRecord(recordType: "ReadState")
                    record["articleId"] = articleId.uuidString as CKRecordValue
                }
                
                record["isRead"] = isRead as CKRecordValue
                record["readAt"] = readAt as CKRecordValue
                
                self.privateDatabase.save(record) { savedRecord, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let savedRecord = savedRecord {
                        completion(.success(savedRecord))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchReadStates(completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let query = CKQuery(recordType: "ReadState", predicate: NSPredicate(value: true))
        
        privateDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 100) { result in
            switch result {
            case .success(let queryResult):
                let records = queryResult.matchResults.compactMap { try? $0.1.get() }
                completion(.success(records))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus(completion: @escaping (Result<CKAccountStatus, Error>) -> Void) {
        container.accountStatus { status, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(status))
            }
        }
    }
}
