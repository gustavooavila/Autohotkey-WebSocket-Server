#Persistent
#SingleInstance, force
SetBatchLines, -1

global Console := new CConsole()
Console.hotkey := "^+c"  ; to show the console
Console.show()

SocketManager := new SocketServiceHandler()

http := new HttpServer(8000)

http.StaticRoute("index.html")

ws := new WSserver(8080)
ws.addProtocol("echo", Func("WSecho"))

SocketManager.RegisterService(http)
SocketManager.RegisterService(ws)

SocketManager.StartServices()

return

WSecho(data, client){
    return data
}

Esc::ExitApp

#include, %A_ScriptDir%\..\..\libs
#include, CConsole.ahk
#Include, SocketService.ahk
#include, HTTP.ahk
#include, WS.ahk