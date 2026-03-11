import Foundation

enum DrugRoute: String, CaseIterable, Codable {
    case oral = "oral"
    case injection = "injection"
    case topical = "topical"
    case other = "other"

    var displayName: String {
        switch self {
        case .oral: return "Oral"
        case .injection: return "Injection"
        case .topical: return "Topical"
        case .other: return "Other"
        }
    }
}

enum DoseStatus: String, CaseIterable, Codable {
    case scheduled = "scheduled"
    case taken = "taken"
    case skipped = "skipped"
}

enum FrequencyType: String, CaseIterable, Codable {
    case daily = "daily"
    case specificDays = "specificDays"
    case everyNDays = "everyNDays"
}

enum GlucoseUnit: String, CaseIterable, Codable {
    case mmolL = "mmolL"
    case mgdL = "mgdL"

    var displayName: String {
        switch self {
        case .mmolL: return "mmol/L"
        case .mgdL: return "mg/dL"
        }
    }
}

enum InjectionSite: Equatable {
    case abdomenLeft
    case abdomenRight
    case thighLeft
    case thighRight
    case upperArmLeft
    case upperArmRight
    case buttockLeft
    case buttockRight
    case custom(String)

    var rawValue: String {
        switch self {
        case .abdomenLeft: return "abdomenLeft"
        case .abdomenRight: return "abdomenRight"
        case .thighLeft: return "thighLeft"
        case .thighRight: return "thighRight"
        case .upperArmLeft: return "upperArmLeft"
        case .upperArmRight: return "upperArmRight"
        case .buttockLeft: return "buttockLeft"
        case .buttockRight: return "buttockRight"
        case .custom(let text): return "custom:\(text)"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "abdomenLeft": self = .abdomenLeft
        case "abdomenRight": self = .abdomenRight
        case "thighLeft": self = .thighLeft
        case "thighRight": self = .thighRight
        case "upperArmLeft": self = .upperArmLeft
        case "upperArmRight": self = .upperArmRight
        case "buttockLeft": self = .buttockLeft
        case "buttockRight": self = .buttockRight
        default:
            if rawValue.hasPrefix("custom:") {
                self = .custom(String(rawValue.dropFirst("custom:".count)))
            } else {
                return nil
            }
        }
    }

    var displayName: String {
        switch self {
        case .abdomenLeft: return "Abdomen Left"
        case .abdomenRight: return "Abdomen Right"
        case .thighLeft: return "Thigh Left"
        case .thighRight: return "Thigh Right"
        case .upperArmLeft: return "Upper Arm Left"
        case .upperArmRight: return "Upper Arm Right"
        case .buttockLeft: return "Buttock Left"
        case .buttockRight: return "Buttock Right"
        case .custom(let text): return text
        }
    }

    var bodyRegion: String {
        switch self {
        case .abdomenLeft, .abdomenRight: return "Abdomen"
        case .thighLeft, .thighRight: return "Thigh"
        case .upperArmLeft, .upperArmRight: return "Upper Arm"
        case .buttockLeft, .buttockRight: return "Buttock"
        case .custom: return "Custom"
        }
    }

    static let allStandard: [InjectionSite] = [
        .abdomenLeft, .abdomenRight,
        .thighLeft, .thighRight,
        .upperArmLeft, .upperArmRight,
        .buttockLeft, .buttockRight
    ]
}
