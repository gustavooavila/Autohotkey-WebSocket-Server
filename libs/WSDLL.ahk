class WSDll{
    __new(){
        DllCall("Websocket/WebSocketCreateServerHandle","ptr",)
        WEB_SOCKET_HANDLE
    }
}