// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import wso2/ftp;
import ballerina/log;
import ballerina/io;
import ballerina/internal;
import ballerina/config;
import ballerina/http;

public const MOVE = "MOVE";
public const DELETE = "DELETE";
public const ERROR = "ERROR";

public type Operation MOVE|DELETE|ERROR;

type Config record {
    string fileNamePattern;
    string destFolder;
    string errFolder;
    Operation opr;
};

Config conf = {
    fileNamePattern: config:getAsString("FTP_FILE_NAME_PATTERN"),
    destFolder: config:getAsString("FTP_DESTINATION_FOLDER"),
    errFolder: config:getAsString("FTP_ERROR_FOLDER"),
    opr: MOVE
};

// Creating a ftp listener instance by defining the configuration.
listener ftp:Listener remoteServer = new({
    protocol:ftp:FTP,
    host:config:getAsString("FTP_HOST"),
    port:config:getAsInt("FTP_LISTENER_PORT"),
    pollingInterval:config:getAsInt("FTP_POLLING_INTERVAL"),
    fileNamePattern:conf.fileNamePattern,
    secureSocket: {
        basicAuth: {
            username:config:getAsString("FTP_USER_NAME"),
            password:config:getAsString("FTP_PASSWORD")
        }
    },
    path:config:getAsString("FTP_LISTENER_FOLDER")
});

// Defining the configuration of the ftp client endpoint.
ftp:ClientEndpointConfig ftpConfig = {
    protocol: ftp:FTP,
    host: config:getAsString("FTP_HOST"),
    port: config:getAsInt("FTP_LISTENER_PORT"),
    secureSocket: {
        basicAuth: {
            username: config:getAsString("FTP_USER_NAME"),
            password: config:getAsString("FTP_PASSWORD")
        }
    }
};

ftp:Client ftpClient = new(ftpConfig);

service monitor on remoteServer {
    resource function fileResource(ftp:WatchEvent m) {
        foreach ftp:FileInfo v1 in m.addedFiles {

            log:printInfo("Added file path: " + v1.path);

            var getResult = ftpClient->get(v1.path);
            var proRes = processFile(untaint v1.path);

            if (proRes == MOVE) {
                string destFilePath = createFolderPath(v1, conf.destFolder);
                error? renameErr = ftpClient->rename(v1.path, destFilePath);
            } else {
                string errFoldPath = createFolderPath(v1, conf.errFolder);
                error? processErr = ftpClient->rename(v1.path, errFoldPath);
            }

                     // Implementation
        }
    }
}
public function processFile(string sourcePath) returns Operation {
    var getResult = ftpClient->get(sourcePath);
    Operation res = ERROR;

       //Implementation

    return res;
}


public function createFolderPath(ftp:FileInfo v2, string folderPath) returns string {
    string p2 = createPath(v2);
    string path = folderPath + "/" + p2;
    return path;
}

public function createPath(ftp:FileInfo v3) returns string {
    int subString = v3.path.lastIndexOf("/");
    int length = v3.path.length();
    string subPath = v3.path.substring((subString + 1), length);
    return subPath;
}

