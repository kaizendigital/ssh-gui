//
//  ContentView.swift
//  SSH GUI
//
//  Created by Stephen Lang on 18/05/2020.
//  Copyright © 2020 Kaizen Digital. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var isShowingAlert = false
    @State var alertText = ""
    @State var passphrase = ""
    @State var isBusy = false
    
    let sshDir = "/Users/\(NSUserName())/.ssh"
    let priKeyFile = "/Users/\(NSUserName())/.ssh/id_rsa"
    let pubKeyFile = "/Users/\(NSUserName())/.ssh/id_rsa.pub"
    
    func fileExists() -> Bool {
        return FileManager.default.fileExists(atPath: pubKeyFile)
    }
    
    func fileContents() -> String {
        let fileURL = URL(fileURLWithPath: pubKeyFile)
        
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            self.alertText = "Failed to copy key!"
            self.isShowingAlert = true
            return "";
        }
    }
    
    func copy() {
        let pb = NSPasteboard.general
        pb.declareTypes([.string], owner: nil)
        pb.setString(fileContents(), forType: .string)
    }
    
    func shell(_ args: String) -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args.components(separatedBy: " ")
        task.launch()
        task.waitUntilExit()
        
        if task.terminationStatus == 0 {
            return true
        }
        return false
    }
    
    var body: some View {
        VStack {
            Text("SSH GUI")
                .font(.title)
            
            Group {
                if fileExists() {
                    Text("Public key found")
                        .font(.subheadline)
                        .padding(8)
                    
                    Text(self.pubKeyFile)
                    
                    Button(action: {
                        self.copy()
                    }) {
                        Text("Copy public key")
                    }
                } else {
                    Text("Public key not found")
                        .font(.subheadline)
                        .padding(8)
                    
                    TextField("Passphrase (optional)", text: $passphrase)
                    
                    Button(action: {
                        self.isBusy = true
                        
                        if FileManager.default.fileExists(atPath: self.sshDir) || self.shell("mkdir \(self.sshDir)") {
                            if self.shell("chmod 0700 \(self.sshDir)") {
                                if self.shell("ssh-keygen -t rsa -b 4096 -f \(self.priKeyFile) -N \(self.passphrase)") {
                                    if self.shell("chmod 0600 \(self.priKeyFile)") {
                                        self.copy()
                                        self.alertText = "Success! Your new SSH public key has been copied to clipboard."
                                    } else {
                                        self.alertText = "Failed to set permissions on: \(self.priKeyFile)"
                                    }
                                } else {
                                    self.alertText = "Failed to generate private key at: \(self.priKeyFile)"
                                }
                            } else {
                                self.alertText = "Failed to set permissions on: \(self.sshDir)"
                            }
                        } else {
                            self.alertText = "Failed to create directory: \(self.sshDir)"
                        }
                        
                        self.isBusy = false
                        self.isShowingAlert = true
                    }) {
                        Group {
                            if isBusy {
                                Text("Please wait...")
                            } else {
                                Text("Create public key")
                            }
                        }
                    }
                }
            }
        }.padding(32).frame(width: 256, height: 256, alignment: .center).alert(isPresented: $isShowingAlert) {
            Alert(title: Text("SSH GUI"), message: Text(alertText))
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
