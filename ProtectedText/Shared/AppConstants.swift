//
//  AppConstants.swift
//  ProtectedText
//
//  Created by Rishi Singh on 30/06/25.
//

import Foundation

let KTabSeperator = "-- tab separator --"
let KTabSeperatorHash = CryptoService.computeSHA512(KTabSeperator)

let KOPResult = "OverwriteProtection"
let KOPMessage = "Overwrite Protection: Site was modified in the meantime\nTo prevent any data loss:\n1. back up your changes to some text editor,\n2. reload the site to get latest modification,\n3. reapply your changes."

/// Tab deletion confirmation message
let KTabDelMessage = "Are you sure you want to delete this tab?\nThis action is irreversible and the delete text can not be recovered!"
