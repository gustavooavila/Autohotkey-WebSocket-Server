#Persistent
#SingleInstance, force
SetBatchLines, -1

global Console := new CConsole()
Console.hotkey := "^+c"  ; to show the console
Console.show()

Server := new Socket(8000)

http := new HttpServer(Server)

http.StaticRoute("index.html")

ws := new WSserver(http)

ws.addProtocol("echo", Func("WSecho"))


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