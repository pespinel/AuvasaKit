import CoreData
import Foundation

/// Manages the Core Data stack for GTFS static data
public actor DatabaseManager {
    /// Shared instance
    public static let shared = DatabaseManager()

    /// Persistent container
    private let container: NSPersistentContainer

    /// View context for main thread operations
    nonisolated public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Errors that can occur during database operations
    public enum DatabaseError: Error, LocalizedError {
        case initializationFailed
        case saveError(Error)
        case fetchError(Error)
        case importError(String)

        public var errorDescription: String? {
            switch self {
            case .initializationFailed:
                "Failed to initialize database"
            case .saveError(let error):
                "Failed to save: \(error.localizedDescription)"
            case .fetchError(let error):
                "Failed to fetch: \(error.localizedDescription)"
            case .importError(let message):
                "Import error: \(message)"
            }
        }
    }

    /// Initializes the database manager
    private init() {
        // Create the model programmatically
        let model = DatabaseManager.createModel()
        self.container = NSPersistentContainer(name: "AuvasaKit", managedObjectModel: model)

        // Configure for in-memory store during tests if needed
        #if DEBUG
        if ProcessInfo.processInfo.environment["AUVASA_IN_MEMORY"] == "1" {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        #endif

        // Load persistent stores
        var loadError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }

        semaphore.wait()

        if let error = loadError {
            fatalError("Failed to load Core Data stack: \(error)")
        }

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Creates a background context for import operations
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Saves changes in a context
    public func save(_ context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }

        try await context.perform {
            do {
                try context.save()
            } catch {
                throw DatabaseError.saveError(error)
            }
        }
    }

    /// Clears all data from the database
    public func clearAllData() async throws {
        let context = newBackgroundContext()

        try await context.perform {
            let entities = [
                "GTFSStop",
                "GTFSRoute",
                "GTFSTrip",
                "GTFSStopTime",
                "GTFSCalendar",
                "GTFSCalendarDate",
                "GTFSShape"
            ]

            for entityName in entities {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs

                do {
                    let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                    if let objectIDs = result?.result as? [NSManagedObjectID] {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                            into: [self.viewContext]
                        )
                    }
                } catch {
                    throw DatabaseError.saveError(error)
                }
            }

            try context.save()
        }
    }

    // MARK: - Core Data Model Creation

    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        model.entities = [
            createStopEntity(),
            createRouteEntity(),
            createTripEntity(),
            createStopTimeEntity(),
            createCalendarEntity(),
            createCalendarDateEntity(),
            createShapeEntity()
        ]

        return model
    }

    private static func createStopEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "GTFSStop"
        entity.managedObjectClassName = NSStringFromClass(GTFSStop.self)
        entity.properties = [
            createAttribute(name: "id", type: .stringAttributeType),
            createAttribute(name: "code", type: .stringAttributeType, optional: true),
            createAttribute(name: "name", type: .stringAttributeType),
            createAttribute(name: "desc", type: .stringAttributeType, optional: true),
            createAttribute(name: "latitude", type: .doubleAttributeType),
            createAttribute(name: "longitude", type: .doubleAttributeType),
            createAttribute(name: "zoneId", type: .stringAttributeType, optional: true),
            createAttribute(name: "url", type: .stringAttributeType, optional: true),
            createAttribute(name: "locationType", type: .integer16AttributeType),
            createAttribute(name: "parentStation", type: .stringAttributeType, optional: true),
            createAttribute(name: "wheelchairBoarding", type: .integer16AttributeType),
            createAttribute(name: "platformCode", type: .stringAttributeType, optional: true)
        ]
        return entity
    }

    private static func createRouteEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "GTFSRoute"
        entity.managedObjectClassName = NSStringFromClass(GTFSRoute.self)
        entity.properties = [
            createAttribute(name: "id", type: .stringAttributeType),
            createAttribute(name: "agencyId", type: .stringAttributeType, optional: true),
            createAttribute(name: "shortName", type: .stringAttributeType),
            createAttribute(name: "longName", type: .stringAttributeType),
            createAttribute(name: "desc", type: .stringAttributeType, optional: true),
            createAttribute(name: "type", type: .integer16AttributeType),
            createAttribute(name: "url", type: .stringAttributeType, optional: true),
            createAttribute(name: "color", type: .stringAttributeType, optional: true),
            createAttribute(name: "textColor", type: .stringAttributeType, optional: true),
            createAttribute(name: "sortOrder", type: .integer32AttributeType, optional: true)
        ]
        return entity
    }

    private static func createTripEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "GTFSTrip"
        entity.managedObjectClassName = NSStringFromClass(GTFSTrip.self)
        entity.properties = [
            createAttribute(name: "id", type: .stringAttributeType),
            createAttribute(name: "routeId", type: .stringAttributeType),
            createAttribute(name: "serviceId", type: .stringAttributeType),
            createAttribute(name: "headsign", type: .stringAttributeType, optional: true),
            createAttribute(name: "shortName", type: .stringAttributeType, optional: true),
            createAttribute(name: "directionId", type: .integer16AttributeType, optional: true),
            createAttribute(name: "blockId", type: .stringAttributeType, optional: true),
            createAttribute(name: "shapeId", type: .stringAttributeType, optional: true),
            createAttribute(name: "wheelchairAccessible", type: .integer16AttributeType),
            createAttribute(name: "bikesAllowed", type: .integer16AttributeType)
        ]
        return entity
    }

    private static func createStopTimeEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "GTFSStopTime"
        entity.managedObjectClassName = NSStringFromClass(GTFSStopTime.self)
        entity.properties = [
            createAttribute(name: "tripId", type: .stringAttributeType),
            createAttribute(name: "stopId", type: .stringAttributeType),
            createAttribute(name: "arrivalTime", type: .stringAttributeType),
            createAttribute(name: "departureTime", type: .stringAttributeType),
            createAttribute(name: "stopSequence", type: .integer32AttributeType),
            createAttribute(name: "stopHeadsign", type: .stringAttributeType, optional: true),
            createAttribute(name: "pickupType", type: .integer16AttributeType),
            createAttribute(name: "dropOffType", type: .integer16AttributeType),
            createAttribute(name: "shapeDistTraveled", type: .doubleAttributeType, optional: true),
            createAttribute(name: "timepoint", type: .integer16AttributeType)
        ]
        return entity
    }

    private static func createCalendarEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "GTFSCalendar"
        entity.managedObjectClassName = NSStringFromClass(GTFSCalendar.self)
        entity.properties = [
            createAttribute(name: "serviceId", type: .stringAttributeType),
            createAttribute(name: "monday", type: .booleanAttributeType),
            createAttribute(name: "tuesday", type: .booleanAttributeType),
            createAttribute(name: "wednesday", type: .booleanAttributeType),
            createAttribute(name: "thursday", type: .booleanAttributeType),
            createAttribute(name: "friday", type: .booleanAttributeType),
            createAttribute(name: "saturday", type: .booleanAttributeType),
            createAttribute(name: "sunday", type: .booleanAttributeType),
            createAttribute(name: "startDate", type: .stringAttributeType),
            createAttribute(name: "endDate", type: .stringAttributeType)
        ]
        return entity
    }

    private static func createCalendarDateEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "GTFSCalendarDate"
        entity.managedObjectClassName = NSStringFromClass(GTFSCalendarDate.self)
        entity.properties = [
            createAttribute(name: "serviceId", type: .stringAttributeType),
            createAttribute(name: "date", type: .stringAttributeType),
            createAttribute(name: "exceptionType", type: .integer16AttributeType)
        ]
        return entity
    }

    private static func createShapeEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "GTFSShape"
        entity.managedObjectClassName = NSStringFromClass(GTFSShape.self)
        entity.properties = [
            createAttribute(name: "shapeId", type: .stringAttributeType),
            createAttribute(name: "latitude", type: .doubleAttributeType),
            createAttribute(name: "longitude", type: .doubleAttributeType),
            createAttribute(name: "sequence", type: .integer32AttributeType),
            createAttribute(name: "distTraveled", type: .doubleAttributeType, optional: true)
        ]
        return entity
    }

    private static func createAttribute(
        name: String,
        type: NSAttributeType,
        optional: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}

// MARK: - Managed Object Classes

@objc(GTFSStop)
public class GTFSStop: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var code: String?
    @NSManaged public var name: String
    @NSManaged public var desc: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var zoneId: String?
    @NSManaged public var url: String?
    @NSManaged public var locationType: Int16
    @NSManaged public var parentStation: String?
    @NSManaged public var wheelchairBoarding: Int16
    @NSManaged public var platformCode: String?
}

@objc(GTFSRoute)
public class GTFSRoute: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var agencyId: String?
    @NSManaged public var shortName: String
    @NSManaged public var longName: String
    @NSManaged public var desc: String?
    @NSManaged public var type: Int16
    @NSManaged public var url: String?
    @NSManaged public var color: String?
    @NSManaged public var textColor: String?
    @NSManaged public var sortOrder: Int32
}

@objc(GTFSTrip)
public class GTFSTrip: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var routeId: String
    @NSManaged public var serviceId: String
    @NSManaged public var headsign: String?
    @NSManaged public var shortName: String?
    @NSManaged public var directionId: Int16
    @NSManaged public var blockId: String?
    @NSManaged public var shapeId: String?
    @NSManaged public var wheelchairAccessible: Int16
    @NSManaged public var bikesAllowed: Int16
}

@objc(GTFSStopTime)
public class GTFSStopTime: NSManagedObject {
    @NSManaged public var tripId: String
    @NSManaged public var stopId: String
    @NSManaged public var arrivalTime: String
    @NSManaged public var departureTime: String
    @NSManaged public var stopSequence: Int32
    @NSManaged public var stopHeadsign: String?
    @NSManaged public var pickupType: Int16
    @NSManaged public var dropOffType: Int16
    @NSManaged public var shapeDistTraveled: Double
    @NSManaged public var timepoint: Int16
}

@objc(GTFSCalendar)
public class GTFSCalendar: NSManagedObject {
    @NSManaged public var serviceId: String
    @NSManaged public var monday: Bool
    @NSManaged public var tuesday: Bool
    @NSManaged public var wednesday: Bool
    @NSManaged public var thursday: Bool
    @NSManaged public var friday: Bool
    @NSManaged public var saturday: Bool
    @NSManaged public var sunday: Bool
    @NSManaged public var startDate: String
    @NSManaged public var endDate: String
}

@objc(GTFSCalendarDate)
public class GTFSCalendarDate: NSManagedObject {
    @NSManaged public var serviceId: String
    @NSManaged public var date: String
    @NSManaged public var exceptionType: Int16
}

@objc(GTFSShape)
public class GTFSShape: NSManagedObject {
    @NSManaged public var shapeId: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var sequence: Int32
    @NSManaged public var distTraveled: Double
}
