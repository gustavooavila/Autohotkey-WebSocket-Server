#include AHKsock.ahk

class SocketClient
{
    __New(socket) {
        this.socket := socket
    }
    
    ;TODO: clean up better, delete this object and all references
    
    Close(timeout = 5000) {
        AHKsock_Close(this.socket, timeout)
    }
    
    ;TODO: replace with message Queue
    
    SetData(data) {
        this.data := data
    }
    sendBinary(byRef data) {
        if ((i := AHKsock_Send(this.socket, p, length - this.dataSent)) < 0) {
            console.log("sent binary data")
        }
    }
    TrySend() {
        if (!this.data || this.data == "")
        return false
        
        p := this.data.GetPointer()
        length := this.data.length
        
        this.dataSent := 0
        
        loop {
            if ((i := AHKsock_Send(this.socket, p, length - this.dataSent)) < 0) {
                if (i == -2) {
                return
                } else {
                    ; Failed to send
                    return
                }
            }
            
            if (i < length - this.dataSent) {
            this.dataSent += i
            } else {
                break
            }
        }
        this.dataSent := 0
        this.data := ""
        
        return true
    }
}


class SocketServiceHandler
{
    static services := {}
    
    RegisterService(service)
    {
        console.log("service registered: ",service.port)
        SocketServiceHandler.services[service.port] := service
    }
    
    StartServices()
    {
        For port, service in SocketServiceHandler.services
        {    
            If (i := AHKsock_Listen(port, "SocketHandler")) 
            {
                console.log("AHKsock_Listen() failed with return value = ", i," and ErrorLevel = ", ErrorLevel)
                break
            }
        }
    }
}

SocketHandler(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0, ByRef bData = 0, bDataLength = 0) {
    static clients := {}
    
    if (!clients[iSocket]) {
        clients[iSocket] := new SocketClient(iSocket)
        AHKsock_SockOpt(iSocket, "SO_KEEPALIVE", true)
    }
    client := clients[iSocket]
    if (sEvent == "DISCONNECTED") {
        client.request := false
        clients[iSocket] := false
    
    } else if (sEvent == "SEND") {
        client.TrySend()
    } else if (sEvent == "RECEIVED") {
        service := SocketServiceHandler.services[sPort]
        service.handler(client, bData, bDataLength)
    }
}