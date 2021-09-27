#include Base64.ahk
#include SHA1.ahk
#include HTTP.ahk

xorcipher(byteArr, keyArr)
{
    keylen := keyArr.length()
    for i, byte in byteArr{
        key :=  keyArr[mod(A_Index - 1, keylen) + 1]
        decodedByte := byte ^ key
        out .= decodedByte ? chr(decodedByte) : chr(key)
    }
    return out
}

handshake(ByRef req, ByRef res){
    clientKey := req.headers["Sec-WebSocket-Key"]
    subprotocol := req.headers["Sec-WebSocket-Protocol"]
    responseKey := sec_websocket_accept(clientKey)
    
    res.headers["Connection"] := "Upgrade"
    res.headers["Upgrade"] := "websocket"
    res.headers["Sec-WebSocket-Accept"] := responseKey
    res.headers["Sec-WebSocket-Protocol"] := subprotocol
    res.status := "101 Switching Protocols"
    
    return res
}

sec_websocket_accept(key){
    key := key . "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    sha1 := bcrypt_sha1(key)
    b64 := HexBase64(sha1)
    return b64
}

class WSClient{
    ; needs a function to send data
    ; needs way to decode the data frames
    __New(ByRef client, protocol) {
        this.client := client
        this.protocol := protocol
    }
    
    decode(ByRef data, bDataLength) {
        fin := NumGet(&data, "UChar")
        
        if(fin == 0x88){
            return
        }
        
        if(bDataLength > 125) {
            return this.decodebig(data, bDataLength)
            
        }else
        {
            return this.decodesmall(data, bDataLength)
        }
    }
    
    decodesmall(ByRef data, bDataLength) {
        fin := NumGet(&data, "UChar")
        length := NumGet(&data + 1, "UChar")
        
        ; check if masked
        if(length > 128) {
            key := []
            payload := []
            
            Loop %bDataLength% {
                byte := NumGet(&data + A_Index - 1, "UChar")
                if(A_Index > 2 && A_Index < 7 ){
                    key.push(byte)
                }else
                if(A_Index > 6){
                    payload.push(byte)
                }   
            }    
        result := xorcipher(payload, key)
        } else {
            Loop %length%{
                byte := NumGet(&data + 2 + A_Index - 1, "UChar")
                result .= chr(byte)
            }
        }
        
        return result
    }
    
    encode(message) {
        length := strlen(message)
        if(length < 125) {
            byteArr := [129, length]
            buf := new Buffer(length + 2)
            Loop, Parse, message
            byteArr.push(Asc(A_LoopField))
            VarSetCapacity(result, byteArr.Length())
            For, i, byte in byteArr
            NumPut(byte, result, A_Index - 1, "UInt")
            buf.Write(&result, length + 2)
        }
        return buf
    }
    
    decodebig(ByRef data, bDataLength){
        return data    
    }
    
    setData(data){
        this.client.setData(data)
    }
    
    TrySend(){
        this.client.TrySend()
    }
}

class WSserver {
    __new(socket){
        this.clients := []
        this.socket := socket        
        this.protocols := []
    }
    
    registerClient(ByRef client, protocol := "default"){
        console.log("new Websocket Client")
        console.log("Socket: ", client.socket, " protocol: ", protocol)
        socket := client.socket
        this.clients[socket] := new WSClient(client, protocol)
    }
    
    addProtocol(protocol, ByRef func) {
        this.protocols[protocol] := func
    }
    
    isValidProtocol(protocol) {
        return this.protocols.HasKey(protocol)
    }
    
    broadcast(data, protocol := "") {
        return 
    }
    
    handler(ByRef client, ByRef bData = 0, bDataLength = 0) {
        ; New Client or Old
        if(this.clients[client.socket]) {
            client := this.clients[client.socket]
            decodedMessage := client.decode(bData, bDataLength)
            if(decodedMessage) {
                protocol := this.protocols[client.protocol]
                
                response := protocol.Call(decodedMessage, client)
                
                if(response) {
                    encodedMessage := client.encode(response)
                    client.setData(encodedMessage)
                    client.TrySend()
                }
                
            }
            return
        }
        
        text := StrGet(&bData, "UTF-8")
        
        ; New request or old?
        if (client.request) {
            ; Get data and append it to the existing request body
            client.request.bytesLeft -= StrLen(text)
            client.request.body := client.request.body . text
        request := client.request
        } else {
            ; Parse new request
            request := new HttpRequest(text)
            
            length := request.headers["Content-Length"]
            request.bytesLeft := length + 0
            
            if (request.body) {
                request.bytesLeft -= StrLen(request.body)
            }
        }
        if (request.bytesLeft <= 0) {
        request.done := true
        } else {
            client.request := request
        }
        if (request.done || request.IsMultipart()) {
            response := new HttpResponse()
            ; validate some of the headers
            if(request.headers["Sec-WebSocket-Protocol"] && request.headers["sec-websocket-key"] && request.headers["Upgrade"] && request.headers["Upgrade"] == "websocket"){
                protocol := request.headers["Sec-WebSocket-Protocol"]
                ; check if the protocol is part of the registered protocols
                if(this.isValidProtocol(protocol)){
                    ; create handshake response
                    response := handshake(request, response)
                    this.registerClient(client, protocol)
                }else{
                    response.status := "501 Not Implemented"
                }
                }else{
                    ; create error response
                    response.status := "400 Bad Request"
                }
                
                if (response.status) {
                    ; generate http data buffer for sending
                    responsedata := response.Generate()
                    client.SetData(responsedata)
                }
                
        }
        ; send HTTP response
        if (client.TrySend()) {
            if(this.clients[client.socket]) return
            if (!request.IsMultipart() || request.done) {
                client.Close()
            }
        }
        
    }
}        