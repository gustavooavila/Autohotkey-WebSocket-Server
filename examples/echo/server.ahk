#Persistent
#SingleInstance, force
SetBatchLines, -1

global Console := new CConsole()
Console.hotkey := "^+c"  ; to show the console
Console.show()

http := new HttpServer(8000)

http.StaticRoute("index.html")

ws := new WSserver(8080)
ws.addProtocol("echo", Func("WSecho"))

SocketService.RegisterService(http)
SocketService.RegisterService(ws)

return

WSecho(ByRef Request, ByRef Response, ByRef client){
    Response.message := Request.getMessage()
}

Esc::ExitApp

#include, %A_ScriptDir%\..\..\libs
#include, CConsole.ahk
#Include, SocketService.ahk
#include, HTTP.ahk
#include, WS.ahk