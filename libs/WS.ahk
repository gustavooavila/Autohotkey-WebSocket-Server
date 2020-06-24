#include Base64.ahk
#include SHA1.ahk

class WSRoute{
    static WS_MAGIC_STRING = 258EAFA5-E914-47DA-95CA-C5AB0DC85B11
    
    __New(path, ByRef func, ByRef WSserver){
        this.path := path
        this.WSserver := WSserver
        this.func := func
    }
    
    response(ByRef req, ByRef WSClient, ByRef HTTPserver){
        return this.func(req,WSClient,this.WSserver,HTTPserver)
    }
    
    handshake(ByRef req, ByRef res, ByRef HTTPserver){
    
        key := "dGhlIHNhbXBsZSBub25jZQ==" . "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        
        sha1 := bcrypt_sha1(key)
        Base64Encode :=  B64Enc(sha1)
        
        
        Console.log("key:",key)
        Console.log("sha1:",sha1)
        Console.log("b64:",b64)
        
        res.status := "101 Switching Protocols"
        res.headers["Connection"] := "Upgrade"
        res.headers["Upgrade"] := "websocket"
        res.headers["Sec-WebSocket-Accept"] := b64
        
    }
    
    __Call(method, args*){
        if (method = "")
        return this.handshake(args*)
        if (IsObject(method))
        return this.handshake(method, args*)
    }
}
class WSRouter{
    __New(ByRef WSserver){
        this.WSserver := WSserver
        this.routes:={}
    }
    addRoute(path, ByRef func){
        this.routes[path] := new WSRoute(path, func, this.WSserver)
    }
    
}

class WSserver {
    __new(ByRef HTTPserver){
        this.HTTPserver := HTTPserver
        this.Router := new WSRouter(this)
        this.clients := []
    }
    
    addRoute(path, ByRef func){
        this.Router.addRoute(path, func)
    }
    
    broadcast(path,message){
        For index, client in this.clients{
            client.sendMsg(path,message)
        }
    }
    
    setup(){
        For key, value in this.Router.routes{
            this.HTTPserver.Router.DinamicRoute(key,value)
        }
    }
}


class WSClient{
    sendMsg(path,message){
        return
    }
}