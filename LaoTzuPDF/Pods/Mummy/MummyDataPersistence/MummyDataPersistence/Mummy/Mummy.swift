//
//  MohistDataPersistence.swift
//  MohistDataPersistenceModule
//
//  Created by mozhe on 2018/10/26.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation

public final class Mummy<Base> {
    public let base: Base
    public init(_ base: Base){
        self.base = base
    }
}

public protocol MummyCompatible {
    associatedtype CompatibleType
    var mm: CompatibleType { get }
}

public extension MummyCompatible {
    public var mm: Mummy<Self> {
        return Mummy(self)
    }
}

extension Data: MummyCompatible{}
extension Dictionary: MummyCompatible{}
extension Array: MummyCompatible{}


