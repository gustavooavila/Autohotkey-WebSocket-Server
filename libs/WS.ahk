#include Crypto.ahk
#include WSDataFrame.ahk
#include HTTP.ahk


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
    key := key . "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" ; Chosen by fair dice roll. Guaranteed to be random.
    sha1 := sha1_encode(key)
    pbHash := sha1[1]
    cbHash := sha1[2]
    b64 := Base64_encode(&pbHash, cbHash)
    return b64
}

class WSClient{
    ; needs a function to send bigger data
    ; needs way to decode bigger data frames
    __New(ByRef client, protocol) {
        this.client := client
        this.protocol := protocol
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
            if(client.multiFrameMessage) {
                client.multiFrameMessage.decode(bData, bDataLength)
            request := client.multiFrameMessage
            } else {
                request := new WSRequest(bData, bDataLength)
            }
            if(request.fin) {
                protocol := this.protocols[client.protocol]                
                response := new WSResponse()
                
                protocol.Call(request, response, client)
                
                encodedMessage := response.encode()
                client.setData(encodedMessage)
                client.TrySend()
            
            }else{
                client.multiFrameMessage := request
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