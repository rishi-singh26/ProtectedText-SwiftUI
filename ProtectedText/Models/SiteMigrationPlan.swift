//
//  SiteMigrationPlan.swift
//  ProtectedText
//
//  Created by Rishi Singh on 27/06/25.
//

import SwiftData

enum SiteMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [SiteSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
//        [migrateV1toV2]
    }
    
//    static let migrateV1toV2 = MigrationStage.lightweight(
//        fromVersion: AddressSchemaV1.self,
//        toVersion: AddressSchemaV2.self,
//    )
}
