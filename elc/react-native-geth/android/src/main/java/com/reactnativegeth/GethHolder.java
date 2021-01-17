package com.reactnativegeth;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableNativeArray;

import org.ethereum.geth.Account;
import org.ethereum.geth.KeyStore;
import org.ethereum.geth.Node;
import org.ethereum.geth.NodeConfig;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.Writer;

public class GethHolder {
    private static final String ETH_DIR = ".ethereum";
    private static final String STATIC_NODES_FILES_PATH = "/" + ETH_DIR + "/GethDroid/";
    private static final String STATIC_NODES_FILES_NAME = "static-nodes.json";

    private Account account;
    private Node node;
    private NodeConfig ndConfig;
    private KeyStore keyStore;
    private ReactApplicationContext reactContext;

    protected GethHolder(ReactApplicationContext reactContext) {
        this.reactContext = reactContext;
        try {
            NodeConfig nc = new NodeConfig();
            setNodeConfig(nc);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    protected NodeConfig getNodeConfig() {
        return ndConfig;
    }

    protected void setNodeConfig(NodeConfig nc) {
        this.ndConfig = nc;
    }

    protected Node getNode() {
        return node;
    }

    protected void setNode(Node node) {
        this.node = node;
    }

    protected Account getAccount() {
        return account;
    }

    protected void setAccount(Account account) {
        this.account = account;
    }

    protected KeyStore getKeyStore() {
        return keyStore;
    }

    protected void setKeyStore(KeyStore keyStore) {
        this.keyStore = keyStore;
    }

    protected void writeStaticNodesFile(String enodes) {
        try {
            File dir = new File(this.reactContext
                    .getFilesDir() + STATIC_NODES_FILES_PATH);
            if (dir.exists() == false) dir.mkdirs();
            File f = new File(dir, STATIC_NODES_FILES_NAME);
            if (f.exists() == false) {
                if (f.createNewFile() == true) {
                    WritableArray staticNodes = new WritableNativeArray();
                    staticNodes.pushString(enodes);
                    Writer output = new BufferedWriter(new FileWriter(f));
                    output.write(staticNodes.toString());
                    output.close();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
