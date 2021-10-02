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
        if(client.WSprotocol) {
            response := False
            
            if(client.multiFrameMessage) {
                client.multiFrameMessage.decode(bData, bDataLength)
                request := client.multiFrameMessage
            
            } else {
                request := new WSRequest(bData, bDataLength)
            }
            
            if(request.datatype == "close") {
                ; the protocol for closing must be wrong,
                ; the onclose event is not firing in the client
                if(request.length){
                    closeCode := request.getMessage()
                response := new WSResponse(0x8, closeCode, request.length)
                }else{
                    response := new WSResponse(0x8)
                }
            
            } else if(request.datatype == "ping") {
                ; don't know how to test this :/
                response := new WSResponse(0xA, request.getMessage(), request.length)
            
            }else {
                if(request.fin) {
                    protocol := this.protocols[client.WSprotocol]                
                    response := new WSResponse()
                    protocol.Call(request, response, client)
                
                } else {
                    client.multiFrameMessage := request
                }
            }
            if(response){
                client.setData(response.encode())
                client.TrySend()
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
                client.WSprotocol := protocol
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