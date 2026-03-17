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

enum LabSourceType: String, CaseIterable, Codable {
    case manual = "manual"
    case pdfImport = "pdfImport"
    case photoImport = "photoImport"
    case csvImport = "csvImport"
    case portalImport = "portalImport"

    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .pdfImport: return "PDF"
        case .photoImport: return "Photo"
        case .csvImport: return "CSV"
        case .portalImport: return "Portal"
        }
    }
}

enum InjectionSite: Equatable {
    // Traps
    case leftTrap, rightTrap
    // Delts
    case leftFrontDelt, rightFrontDelt
    case leftDelt, rightDelt
    case leftRearDelt, rightRearDelt
    // Arms
    case leftBicep, rightBicep
    case leftTricep, rightTricep
    // Chest
    case leftPec, rightPec
    // Abdomen
    case leftUpperAbdomen, rightUpperAbdomen
    case leftLowerAbdomen, rightLowerAbdomen
    case leftLoveHandle, rightLoveHandle
    // Glutes
    case leftVentroGlute, rightVentroGlute
    case leftDorsoGlute, rightDorsoGlute
    // Legs
    case leftQuad, rightQuad
    case leftCalf, rightCalf
    // Custom
    case custom(String)

    var rawValue: String {
        switch self {
        case .leftTrap: return "leftTrap"
        case .rightTrap: return "rightTrap"
        case .leftFrontDelt: return "leftFrontDelt"
        case .rightFrontDelt: return "rightFrontDelt"
        case .leftDelt: return "leftDelt"
        case .rightDelt: return "rightDelt"
        case .leftRearDelt: return "leftRearDelt"
        case .rightRearDelt: return "rightRearDelt"
        case .leftBicep: return "leftBicep"
        case .rightBicep: return "rightBicep"
        case .leftTricep: return "leftTricep"
        case .rightTricep: return "rightTricep"
        case .leftPec: return "leftPec"
        case .rightPec: return "rightPec"
        case .leftUpperAbdomen: return "leftUpperAbdomen"
        case .rightUpperAbdomen: return "rightUpperAbdomen"
        case .leftLowerAbdomen: return "leftLowerAbdomen"
        case .rightLowerAbdomen: return "rightLowerAbdomen"
        case .leftLoveHandle: return "leftLoveHandle"
        case .rightLoveHandle: return "rightLoveHandle"
        case .leftVentroGlute: return "leftVentroGlute"
        case .rightVentroGlute: return "rightVentroGlute"
        case .leftDorsoGlute: return "leftDorsoGlute"
        case .rightDorsoGlute: return "rightDorsoGlute"
        case .leftQuad: return "leftQuad"
        case .rightQuad: return "rightQuad"
        case .leftCalf: return "leftCalf"
        case .rightCalf: return "rightCalf"
        case .custom(let t): return "custom:\(t)"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "leftTrap": self = .leftTrap
        case "rightTrap": self = .rightTrap
        case "leftFrontDelt": self = .leftFrontDelt
        case "rightFrontDelt": self = .rightFrontDelt
        case "leftDelt": self = .leftDelt
        case "rightDelt": self = .rightDelt
        case "leftRearDelt": self = .leftRearDelt
        case "rightRearDelt": self = .rightRearDelt
        case "leftBicep": self = .leftBicep
        case "rightBicep": self = .rightBicep
        case "leftTricep": self = .leftTricep
        case "rightTricep": self = .rightTricep
        case "leftPec": self = .leftPec
        case "rightPec": self = .rightPec
        case "leftUpperAbdomen": self = .leftUpperAbdomen
        case "rightUpperAbdomen": self = .rightUpperAbdomen
        case "leftLowerAbdomen": self = .leftLowerAbdomen
        case "rightLowerAbdomen": self = .rightLowerAbdomen
        case "leftLoveHandle": self = .leftLoveHandle
        case "rightLoveHandle": self = .rightLoveHandle
        case "leftVentroGlute": self = .leftVentroGlute
        case "rightVentroGlute": self = .rightVentroGlute
        case "leftDorsoGlute": self = .leftDorsoGlute
        case "rightDorsoGlute": self = .rightDorsoGlute
        case "leftQuad": self = .leftQuad
        case "rightQuad": self = .rightQuad
        case "leftCalf": self = .leftCalf
        case "rightCalf": self = .rightCalf
        // Legacy mappings for data stored before 3D body map
        case "abdomenLeft": self = .leftLowerAbdomen
        case "abdomenRight": self = .rightLowerAbdomen
        case "thighLeft": self = .leftQuad
        case "thighRight": self = .rightQuad
        case "upperArmLeft": self = .leftDelt
        case "upperArmRight": self = .rightDelt
        case "buttockLeft": self = .leftDorsoGlute
        case "buttockRight": self = .rightDorsoGlute
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
        case .leftTrap: return "Left Trap"
        case .rightTrap: return "Right Trap"
        case .leftFrontDelt: return "Left Front Delt"
        case .rightFrontDelt: return "Right Front Delt"
        case .leftDelt: return "Left Delt"
        case .rightDelt: return "Right Delt"
        case .leftRearDelt: return "Left Rear Delt"
        case .rightRearDelt: return "Right Rear Delt"
        case .leftBicep: return "Left Bicep"
        case .rightBicep: return "Right Bicep"
        case .leftTricep: return "Left Tricep"
        case .rightTricep: return "Right Tricep"
        case .leftPec: return "Left Pec"
        case .rightPec: return "Right Pec"
        case .leftUpperAbdomen: return "Left Upper Abdomen"
        case .rightUpperAbdomen: return "Right Upper Abdomen"
        case .leftLowerAbdomen: return "Left Lower Abdomen"
        case .rightLowerAbdomen: return "Right Lower Abdomen"
        case .leftLoveHandle: return "Left Love Handle"
        case .rightLoveHandle: return "Right Love Handle"
        case .leftVentroGlute: return "Left Ventroglute"
        case .rightVentroGlute: return "Right Ventroglute"
        case .leftDorsoGlute: return "Left Dorsoglute"
        case .rightDorsoGlute: return "Right Dorsoglute"
        case .leftQuad: return "Left Quad"
        case .rightQuad: return "Right Quad"
        case .leftCalf: return "Left Calf"
        case .rightCalf: return "Right Calf"
        case .custom(let t): return t
        }
    }

    var bodyRegion: String {
        switch self {
        case .leftTrap, .rightTrap: return "Traps"
        case .leftFrontDelt, .rightFrontDelt,
             .leftDelt, .rightDelt,
             .leftRearDelt, .rightRearDelt: return "Delts"
        case .leftBicep, .rightBicep,
             .leftTricep, .rightTricep: return "Arms"
        case .leftPec, .rightPec: return "Chest"
        case .leftUpperAbdomen, .rightUpperAbdomen,
             .leftLowerAbdomen, .rightLowerAbdomen,
             .leftLoveHandle, .rightLoveHandle: return "Abdomen"
        case .leftVentroGlute, .rightVentroGlute,
             .leftDorsoGlute, .rightDorsoGlute: return "Glutes"
        case .leftQuad, .rightQuad: return "Quads"
        case .leftCalf, .rightCalf: return "Calves"
        case .custom: return "Custom"
        }
    }

    static let allStandard: [InjectionSite] = [
        .leftTrap, .rightTrap,
        .leftFrontDelt, .rightFrontDelt,
        .leftDelt, .rightDelt,
        .leftRearDelt, .rightRearDelt,
        .leftBicep, .rightBicep,
        .leftTricep, .rightTricep,
        .leftPec, .rightPec,
        .leftUpperAbdomen, .rightUpperAbdomen,
        .leftLowerAbdomen, .rightLowerAbdomen,
        .leftLoveHandle, .rightLoveHandle,
        .leftVentroGlute, .rightVentroGlute,
        .leftDorsoGlute, .rightDorsoGlute,
        .leftQuad, .rightQuad,
        .leftCalf, .rightCalf
    ]
}
