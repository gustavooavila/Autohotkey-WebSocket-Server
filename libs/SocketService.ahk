#include AHKsock.ahk
#include EventEmitter.ahk

isFunc(param) {
	fn := numGet(&(_ := Func("InStr").bind()), "Ptr")
	return (Func(param) || (isObject(param) && (numGet(&param, "Ptr") = fn)))
}

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


class Socket extends EventEmitter
{
    __new(port)
    {
        this.clients := {}
        this.port := port
        
        If (i := AHKsock_Listen(port, ObjBindMethod(this, "eventHandler")))
        {
            console.log("AHKsock_Listen() failed with return value = ", i," and ErrorLevel = ", ErrorLevel)
        }
    }
    
    eventHandler(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0, ByRef bData = 0, bDataLength = 0)
    {
        if (!this.clients[iSocket])
        {
            this.clients[iSocket] := new SocketClient(iSocket)
            AHKsock_SockOpt(iSocket, "SO_KEEPALIVE", true)
        }
        client := this.clients[iSocket]
        if (sEvent == "DISCONNECTED")
        {
            this.emit("DISCONNECTED", {iSocket: iSocket})
            client.request := false
            this.clients[iSocket] := false
        } else if (sEvent == "SEND")
        {
            client.TrySend()
        } else if (sEvent == "RECEIVED")
        {
            this.emit("RECEIVED", {client: client, bData: bData, bDataLength: bDataLength})
        }
        
    }
}        