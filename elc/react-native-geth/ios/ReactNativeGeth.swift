//
//  ReactNativeGeth.swift
//  ReactNativeGeth
//
//  Created by 0mkar on 04/04/18.
//

import Foundation
import Geth

@objc(ReactNativeGeth)
class ReactNativeGeth: NSObject {
    private var TAG: String = "Geth"
    private var DATA_DIR = NSHomeDirectory()
    private var ETH_DIR: String = "/.ethereum"
    private var KEY_STORE_DIR: String = "/keystore"
    private let ctx: GethContext
    private var geth_node: NodeRunner

    override init() {
        self.ctx = GethNewContext()
        self.geth_node = NodeRunner()
    }
    
    /**
     * Get Node Information
     * @return Return Node Information
     */
    @objc(getNodeInfo:rejecter:)
    func getNodeInfo(resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        let nodeInfo: GethNodeInfo? = self.geth_node.getNode()?.getInfo()
        
        var ports: [String:Any] = [:]
        ports["listner"] = nodeInfo?.getListenerPort()
        ports["discovery"] = nodeInfo?.getDiscoveryPort()
        
        var result: [String:Any] = [:]
        result["enode"] = nodeInfo?.getEnode()
        result["id"] = nodeInfo?.getID()
        result["ip"] = nodeInfo?.getIP()
        result["listenerAddress"] = nodeInfo?.getListenerAddress()
        result["name"] = nodeInfo?.getName()
        result["ports"] = ports
        result["protocols"] = nodeInfo?.getProtocols()
        
        resolve([result] as NSObject)
    }
    
    /**
     * Creates and configures a new Geth node.
     *
     * @param config  Json object configuration node
     * @param promise Promise
     * @return Return true if created and configured node
     */
    @objc(nodeConfig:resolver:rejecter:)
    func nodeConfig(config: NSObject, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            let nodeconfig: GethNodeConfig = self.geth_node.getNodeConfig()!
            var nodeDir: String = DATA_DIR + "/" + ETH_DIR
            var keyStoreDir: String = DATA_DIR + "/" + ETH_DIR + "/" + KEY_STORE_DIR
            var error: NSError?
            
            if(config.value(forKey: "enodes") != nil) {
                geth_node.writeStaticNodesFile(enodes: config.value(forKey: "enodes") as! String)
            }
            if((config.value(forKey: "networkID")) != nil) {
                nodeconfig.setEthereumNetworkID(config.value(forKey: "networkID") as! Int64)
            }
            if((config.value(forKey: "chainID")) != nil) {
                let chainID: Int64 = config.value(forKey: "chainID") as! Int64
                self.geth_node.setChainID(chainID: GethBigInt(chainID))
            }
            if(config.value(forKey: "maxPeers") != nil) {
                nodeconfig.setMaxPeers(config.value(forKey: "maxPeers") as! Int)
            }
            if(config.value(forKey: "genesis") != nil) {
                nodeconfig.setEthereumGenesis(config.value(forKey: "genesis") as! String)
            }
            if(config.value(forKey: "nodeDir") != nil) {
                nodeDir = config.value(forKey: "nodeDir") as! String
            }
            if(config.value(forKey: "keyStoreDir") != nil) {
                keyStoreDir = config.value(forKey: "keyStoreDir") as! String
            }
            
            let node: GethNode = GethNewNode(nodeDir, nodeconfig, &error)
            let keyStore: GethKeyStore = GethNewKeyStore(keyStoreDir, GethLightScryptN, GethLightScryptP)
            if error != nil {
                reject(nil, nil, error)
                return
            }
            geth_node.setNodeConfig(nc: nodeconfig)
            geth_node.setKeyStore(ks: keyStore)
            geth_node.setNode(node: node)
            resolve([true] as NSObject)
        } catch let NCErr as NSError {
            NSLog("@", NCErr)
            reject(nil, nil, NCErr)
        }
    }
    
    /**
     * Start creates a live P2P node and starts running it.
     *
     * @param promise Promise
     * @return Return true if started.
     */
    @objc(startNode:rejecter:)
    func startNode(resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            var result: Bool = false
            if(geth_node.getNode() != nil) {
                try geth_node.getNode()?.start()
                result = true
            }
            resolve([result] as NSObject)
        } catch let NSErr as NSError {
            NSLog("@", NSErr)
            reject(nil, nil, NSErr)
        }
    }
    
    /**
     * Terminates a running node along with all it's services.
     *
     * @param promise Promise
     * @return return true if stopped.
     */
    @objc(stopNode:rejecter:)
    func stopNode(resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            var result: Bool = false
            if(geth_node.getNode() != nil) {
                try geth_node.getNode()?.stop()
                result = true
            }
            resolve([result] as NSObject)
        } catch let NSErr as NSError {
            NSLog("@", NSErr)
            reject(nil, nil, NSErr)
        }
    }
    
    /**
     * Create a new account with the specified encryption passphrase.
     *
     * @param passphrase Passphrase
     * @param promise    Promise
     * @return return new account object.
     */
    @objc(newAccount:resolver:rejecter:)
    func newAccount(password: String, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        var account: GethAccount?
        let ks: GethKeyStore? = self.geth_node.getKeystore()
        do {
            account = try ks?.newAccount(password)
            var result = [String:Any]()
            result["address"] = account?.getAddress().getHex()
            result["account"] = (ks?.getAccounts().size())! - 1
            resolve([result] as NSObject)
        } catch let accError as NSError {
            NSLog("@", accError)
            reject(nil, nil, accError)
        }
    }
    
    /**
     * Unlock an account with given passphrase.
     *
     * @param passphrase Passphrase
     * @param promise    Promise
     * @return return true of unlocked
     */
    @objc(unlockAccount:password:resolver:rejecter:)
    func unlockAccount(address: String, password: String, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            let account: GethAccount? = try self.geth_node.getAccountFromHex(address: address)
            let ks: GethKeyStore? = self.geth_node.getKeystore()
            try ks?.timedUnlock(account, passphrase: password, timeout: 60)
            
            resolve([true] as NSObject)
        } catch let accError as NSError {
            NSLog("@", accError)
            reject(nil, nil, accError)
        }
    }
    
    /**
     * Get list of accounts in keystore
     * @return Returns Array of accounts
     */
    @objc(listAccounts:rejecter:)
    func listAccounts(resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            var accountsStore = [[String:Any]]()
            let keyStore: GethKeyStore? = self.geth_node.getKeystore()
            let accounts: GethAccounts? = keyStore?.getAccounts()
            for index in 0..<(accounts?.size())! {
                let account: GethAccount? = try accounts?.get(index)
                let address: String? = account?.getAddress().getHex()
                let result: [String:Any] = ["address": address ?? "", "account": index]
                accountsStore.append(result)
            }
            resolve([accountsStore] as NSObject)
        } catch let accErr as NSError {
            reject(nil, nil, accErr)
        }
    }
    
    /**
     * Get balance of an address
     * @param address to get balance of
     * @return Returns wei balance
     */
    @objc(getBalance:resolver:rejecter:)
    func getBalance(address: String, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            var error: NSError?
            let account: GethAddress = GethNewAddressFromHex(address, &error)
            if(error != nil) {
                reject(nil, nil, error)
            }
            let node: GethNode? = self.geth_node.getNode()
            let ec: GethEthereumClient? = try node?.getEthereumClient()
            let balance: GethBigInt? = try ec?.getBalanceAt(self.ctx, account: account, number: -1)
            resolve([balance?.getInt64()] as NSObject)
        } catch let balanceErr as NSError {
            reject(nil, nil, balanceErr)
        }
    }
    
    /**
     * Send transaction.
     *
     * @param passphrase Passphrase
     * @param nonce      Account nonce (use -1 to use last known nonce)
     * @param toAddress  Address destination
     * @param amount     Amount
     * @param gasLimit   Gas limit
     * @param gasPrice   Gas price
     * @param data       Transaction data (optional)
     * @param promise    Promise
     * @return Return String transaction
     */
    @objc(sendTransaction:password:resolver:rejecter:)
    func sendTransaction(transaction: GethTransaction, password: String, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            let keyStore: GethKeyStore? = self.geth_node.getKeystore()
            let accounts: GethAccounts? = keyStore?.getAccounts()
            let account: GethAccount? = try accounts?.get(0)
            let eth_client: GethEthereumClient? = try self.geth_node.getNode()?.getEthereumClient()
            
            let signedTx: GethTransaction? = try signTx(tx: transaction, account: account!, password: password)
            sendSignedTransaction(signedTx: signedTx!, resolver: resolve, rejecter: reject)
        } catch let sendTxErr as NSError {
            NSLog("@", sendTxErr)
            reject(nil, nil, sendTxErr)
        }
    }
    
    /**
     * Send signed transaction.
     *
     * @param signedTx Transaction (signed)
     * @return Return String transaction
     */
    @objc(sendSignedTransaction:resolver:rejecter:)
    func sendSignedTransaction(signedTx: GethTransaction, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            let eth_client: GethEthereumClient? = try self.geth_node.getNode()?.getEthereumClient()
            try eth_client?.sendTransaction(ctx, tx: signedTx)
        } catch let sendTxErr as NSError {
            NSLog("@", sendTxErr)
            reject(nil, nil, sendTxErr)
        }
    }
    
    /**
     * Sign transaction.
     * @param {Transaction} transaction Transaction object
     * @param {String} address Signing address
     * @param {String} passphrase Passphrase
     * @return {String} Returns signed transaction
     */
    @objc(signTransaction:address:passphrase:resolver:rejecter:)
    func signTransaction(transaction: GethTransaction, address: String, password: String, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            var account: GethAccount? = self.geth_node.getCoinbase()
            if(address.isEmpty) {
                account = try self.geth_node.getAccountFromHex(address: address)
            }
            let signedTx: GethTransaction? = try signTx(tx: transaction, account: account!, password: password)
            resolve(signedTx)
        } catch let signErr as NSError {
            NSLog("@", signErr)
            reject(nil, nil, signErr)
        }
    }
    
    func signTx(tx: GethTransaction, account: GethAccount, password: String) throws -> GethTransaction? {
        let keyStore: GethKeyStore? = self.geth_node.getKeystore()
        let chainID: GethBigInt = self.geth_node.getChainID()
        let signedTx: GethTransaction? = try keyStore?.signTxPassphrase(account, passphrase: password, tx: tx, chainID: chainID)
        return signedTx
    }
    
    /**
     * Get sync progress
     * @return Returns clint sync info
     */
    @objc(getSyncProgress:rejecter:)
    func getSyncProgress(resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            NSLog("Getting sync progress...")
            let node: GethNode? = self.geth_node.getNode()
            let ec: GethEthereumClient? = try node?.getEthereumClient()
            let syncProgress: GethSyncProgress? = try ec?.syncProgress(self.ctx)
            var result: [String:Any] = [:]
            result["currentBlock"] = syncProgress?.getCurrentBlock()
            result["highestBlock"] = syncProgress?.getHighestBlock()
            result["startingBlock"] = syncProgress?.getStartingBlock()
            result["knownStates"] = syncProgress?.getKnownStates()
            result["pulledStates"] = syncProgress?.getPulledStates()
            NSLog("%@", result)
            resolve([result] as NSObject)
        } catch let syncErr as NSError {
            NSLog("%@", syncErr)
            reject(nil, nil, syncErr)
        }
    }
    
    /**
     * Get peers info
     * @return Returns clint sync info
     */
    @objc(getPeersInfo:rejecter:)
    func getPeersInfo(resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            let peers: NSMutableArray = []
            let node: GethNode? = self.node_runner.getNode()
            let peersInfo: GethPeerInfos? = node?.getPeersInfo()
            if(peersInfo?.size() ?? 0 > 0) {
                for index in 0..<(peersInfo?.size())! {
                    let peerInfo: GethPeerInfo? = try peersInfo?.get(index)
                    let peer: NSMutableDictionary = [:]
                    peer["remoteAddress"] = peerInfo?.getRemoteAddress()
                    peer["caps"] = peerInfo?.getCaps().string()
                    peer["id"] = peerInfo?.getID()
                    peer["name"] = peerInfo?.getName()
                    peer["localAddress"] = peerInfo?.getLocalAddress()
                    peers.add(peer)
                }
            }
            resolve([peers] as NSObject)
        } catch let piErr as NSError {
            NSLog("%@", piErr)
            reject(nil, nil, piErr)
        }
    }
}
