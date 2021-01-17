//
//  NodeRunner.swift
//  ReactNativeGeth
//
//  Created by 0mkar on 06/04/18.
//

import Foundation
import Geth

class NodeRunner {
    private let ctx = GethNewContext()
    private var node: GethNode?
    private var nodeconf: GethNodeConfig?
    private var keyStore: GethKeyStore?
    
    private let DATA_DIR = NSHomeDirectory()
    private let ETH_DIR: String = ".ethereum"
    private var STATIC_NODES_FILES_PATH: String
    private let STATIC_NODES_FILES_NAME: String = "static-nodes.json"
    private var chainID: GethBigInt = GethBigInt(1) // Default mainnet chain ID
    private var coinbase: GethAccount?
    
    init() {
        self.nodeconf = GethNewNodeConfig()
        self.STATIC_NODES_FILES_PATH = self.DATA_DIR + "/" + self.ETH_DIR + "/iOSGeth"
    }
    
    func getNodeConfig() -> GethNodeConfig? {
        return self.nodeconf
    }
    
    func getNode() -> GethNode? {
        return self.node
    }
    
    func setNode(node: GethNode) -> Void {
        self.node = node
    }
    
    func setNodeConfig(nc: GethNodeConfig) -> Void {
        self.nodeconf = nc
    }
    
    func setKeyStore(ks: GethKeyStore) -> Void {
        self.keyStore = ks
    }
    
    func getKeystore() -> GethKeyStore? {
        return self.keyStore
    }
    
    func setChainID(chainID: GethBigInt) -> Void {
        self.chainID = chainID
    }
    
    func getChainID() -> GethBigInt {
        return self.chainID
    }
    
    func getCoinbase() -> GethAccount? {
        return self.coinbase
    }
    
    func setCoinbase(account: GethAccount) -> Void {
        self.coinbase = account
    }
    
    func getAccountFromHex(address: String) throws -> GethAccount? {
        let accounts = self.keyStore?.getAccounts()
        var size: Int = Int(0)
        var result: GethAccount?
        if(accounts != nil) {
            size = (accounts?.size())!
        }
        for index in 0...size {
            let account = try accounts?.get(index)
            if(account?.getAddress().getHex() == address) {
                result = account
                break
            }
        }
        return result
    }
    
    func writeStaticNodesFile(enodes: String) -> Void {
        do {
            var isDirectory = ObjCBool(true)
            let exists = FileManager.default.fileExists(atPath: STATIC_NODES_FILES_PATH, isDirectory: &isDirectory)
            if(exists == false) {
                try FileManager.default.createDirectory(atPath: STATIC_NODES_FILES_PATH, withIntermediateDirectories: false, attributes: nil)
            }
            
            let url = NSURL(fileURLWithPath: STATIC_NODES_FILES_PATH)
            if let pathComponent = url.appendingPathComponent(STATIC_NODES_FILES_NAME) {
                let filePath = pathComponent.path
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: filePath) {
                    try enodes.write(to: pathComponent, atomically: false, encoding: .utf8)
                } else {
                    let fileContent: Data = enodes.data(using: .utf8, allowLossyConversion: true)!
                    fileManager.createFile(atPath: filePath, contents: fileContent, attributes: nil)
                }
            } else {
                throw NodeError.RuntimeError("File path not found")
            }
        } catch let writeErr as NSError {
            NSLog("@s", writeErr)
        }
    }
    
    enum NodeError: Error {
        case RuntimeError(String)
    }
}
