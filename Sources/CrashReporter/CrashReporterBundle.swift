//
//  CrashReporterBundle.swift
//  CrashReporter
//
//  Created by Nathan Manceaux-Panot on 2024-11-16.
//

import Foundation

let CrashReporterBundle: Bundle = {
#if SWIFT_PACKAGE
	return Bundle.module
#else
	return Bundle.main
#endif
}()
