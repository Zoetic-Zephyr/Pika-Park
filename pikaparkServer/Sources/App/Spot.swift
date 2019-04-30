//
//  Spot.swift
//  App
//
//  Created by Quinn on 2019/4/29.
//
import FluentSQLite
import Foundation
import Vapor

struct Spot: SQLiteModel, Migration {
    var id: Int?
    var name: String
    var coordinate: String
    var price: Int
    var openSpaces: Int
}
