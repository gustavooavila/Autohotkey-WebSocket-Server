#include, Socket.ahk

class SocketService
{
    static services := {}
    static clients := {}
    
    RegisterService(ByRef service)
    {
        port := service.port
        
        Server := new SocketTCP()
        SocketService.addEventListeners(Server)
        Server.Bind(["0.0.0.0", port])
        SocketService.services[Server.Socket] := service
        Server.Listen()
        
        console.log("service started")
        console.log("port: ", port, "socket: ", Server.Socket)
    }
    
    
    addEventListeners(Server){
        Server.onRecv := objBindMethod(SocketService, "Handler", "RECEIVED")
        Server.OnDisconnect := objBindMethod(SocketService, "Handler", "DISCONNECTED")
        Server.OnAccept := objBindMethod(SocketService, "Handler", "ACCEPT")
    }
    
    Handler(sEvent, Server) {
        console.log(sEvent, Server)
        if (sEvent == "ACCEPT")
        {
            serverSocket := Server.Socket
            
            client := new SocketService.Client(Server)
            clientSocket := client.Socket
            
            bDataLength := client.MsgSize()
            VarSetCapacity(bData, bDataLength)
            client.Recv(bData, bDataLength)
            
            service := SocketService.services[serverSocket]
            service.handler(client, bData, bDataLength)
        }
    }   
    
    class Client extends SocketTCP
    {
        __new(ByRef Server)
        {
            if ((s := DllCall("Ws2_32\accept", "UInt", Server.Socket, "Ptr", 0, "Ptr", 0, "Ptr")) == -1)
			throw Exception("Error calling accept",, this.GetLastError())
            
            this.sending := False
            
            this.Socket := s
            this.ProtocolId := Server.ProtocolId
            this.SocketType := Server.SocketType
            this.EventProcRegister(this.FD_READ | this.FD_CLOSE)
        }
        
        SetData(data)
        {
            this.data := data
        }
        
        TrySend()
        {
            if (!this.data || this.data == "")
            return false
            
            pointer := this.data.GetPointer()
            length := this.data.length
            
            this.dataSent := 0
            
            loop {
                if ((i := this.Send(pointer, length - this.dataSent)) < 0) 
                {
                    if (i == -2)
                    {
                        return
                    } 
                    else {
                        ; Failed to send
                        return
                    }
                }
                
                if (i < length - this.dataSent) 
                {
                    this.dataSent += i
                }
                else {
                    break
                }
            }
            this.dataSent := 0
            this.data := ""
            
            return true
        }
        
        LastError()
        {
            Return DllCall("Ws2_32\WSAGetLastError")
        }
        
        Send(pBuffer, BufSize, Flags := 0)
        {
            iSendResult := DllCall("Ws2_32\send", "Ptr", this.Socket, "Ptr", pBuffer, "Int", BufSize, "Int", Flags)
            
            If (iSendResult = -1) And ((iErr := this.LastError()) = 10035) { ;Check specifically for WSAEWOULDBLOCK
                this.sending := False ;Update socket's send status
                Return -2 ;Calling send() would have blocked the thread. Try again once you get the proper update.
            } 
            Else If (iSendResult = -1) Or ErrorLevel {
                ErrorLevel := ErrorLevel ? ErrorLevel : iErr
                Return -3 ;The send() call failed. The error is in ErrorLevel.
            } 
            Else Return iSendResult ;The send() operation was successful
        }
    }
}