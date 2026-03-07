//
//  UTMConstants.swift
//  SwiftGeoLib
//
//  Created by David Hart on 6/3/2026.
//


public enum UTMConstants {
    public static let utmFalseEasting : Double = 5e5
    public static let utmNorthShift : Double = 1e7

    public static let minimumUTMEasting : Double = 0
    public static let maximumUTMEasting : Double = 1e6

    public static let minimumNorthernUTMNorthing : Double = -91e5
    public static let maximumNorthernUTMNorthing : Double = 96e5

    public static let minimumSouthernUTMNorthing : Double = 9e5
    public static let maximumSouthernUTMNorthing : Double = 196e5
}