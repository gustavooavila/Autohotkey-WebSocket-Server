#include Crypto.ahk
#include WSDataFrame.ahk
#include HTTP.ahk
#Include EventEmitter.ahk

handshake(ByRef req, ByRef res)
{
    clientKey := req.headers["Sec-WebSocket-Key"]
    subprotocol := req.headers["Sec-WebSocket-Protocol"]
    responseKey := sec_websocket_accept(clientKey)
    
    res.headers["Connection"] := "Upgrade"
    res.headers["Upgrade"] := "websocket"
    res.headers["Sec-WebSocket-Accept"] := responseKey
    res.headers["Sec-WebSocket-Protocol"] := subprotocol
    res.status := "101 Switching Protocols"
}

sec_websocket_accept(key)
{
    key := key . "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" ; Chosen by fair dice roll. Guaranteed to be random.
    sha1 := sha1_encode(key)
    pbHash := sha1[1]
    cbHash := sha1[2]
    b64 := Base64_encode(&pbHash, cbHash)
    return b64
}

class WSserver extends EventEmitter
{
    __new(ByRef port)
    {
        
        this.clients := []       
        this.protocols := []
        
        if(port.__Class == "Socket")
        {
            this.socket := port
            this.http := new HttpServer(this.socket)
        }else if(port.__Class == "HttpServer")
        {
            this.http := port
            this.socket := this.http.socket
        }else
        {
            this.http := new HttpServer(port)
            this.socket := this.http.socket
        }
        
        this.socket.prependListener("RECEIVED", objBindMethod(this, "handleWS"))
        this.http.addListener("upgrade", objBindMethod(this, "handleHTTP"))
    }
    
    addProtocol(protocol, ByRef func)
    {
        this.protocols[protocol] := func
    }
    
    isValidProtocol(protocol)
    {
        return this.protocols.HasKey(protocol)
    }
    
    broadcast(data, protocol := "")
    {
        return 
    }
    
    handleWS(ByRef e) {
        client := e.data.client
        bData := e.data.bData
        bDataLength := e.data.bDataLength
        
        response := False
        if(client.WSprotocol)
        {
            e.stopPropagation()
            if(client.multiFrameMessage)
            {
                client.multiFrameMessage.decode(bData, bDataLength)
                request := client.multiFrameMessage
                
            } else 
            {
                request := new WSRequest(bData, bDataLength)
            }
            
            if(request.datatype == "close")
            {
                if(request.length)
                {
                    closeCode := request.getMessage()
                    if(request.length == 2)
                    {
                        console.log("WS Client closed with closeCode: ", closeCode)
                    } else if(request.length > 2)
                    {
                        for _, char in closeCode
                        message .= Chr(char)
                        console.log("WS Client closed with Message: ", message)
                    }
                    response := new WSResponse(0x8, closeCode, request.length)
                }else
                {
                    response := new WSResponse(0x8)
                }
                
            } else if(request.datatype == "ping")
            {
                ; don't know how to test this :/
                response := new WSResponse(0xA, request.getMessage(), request.length)
                
            }else
            {
                if(request.fin)
                {
                    protocol := this.protocols[client.WSprotocol]                
                    response := new WSResponse()
                    protocol.Call(request, response, client)
                    
                } else
                {
                    client.multiFrameMessage := request
                }
            }
            if(response)
            {
                client.setData(response.encode())
                if (client.TrySend())
                {
                    if(request.datatype == "close")
                    {
                        client.Close()
                    }
                }
            }
        }
        
    }
    
    handleHTTP(Byref e)
    {
        request := e.data.request
        response := e.data.response 
        client := e.data.client
        
        if(request.headers["Sec-WebSocket-Protocol"] && request.headers["sec-websocket-key"] && request.headers["Upgrade"] && request.headers["Upgrade"] == "websocket")
        {
            protocol := request.headers["Sec-WebSocket-Protocol"]
            ; check if the protocol is part of the registered protocols
            if(this.isValidProtocol(protocol)){
                ; create handshake response
                handshake(request, response)
                client.preventClose := True
                client.WSprotocol := protocol
            }else
            {
                response.status := "501 Not Implemented"
            }
        }else
        {
            ; create error response
            response.status := "400 Bad Request"
        }            
    }
}        