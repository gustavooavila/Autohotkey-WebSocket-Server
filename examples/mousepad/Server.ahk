#Persistent
#SingleInstance, force
SetBatchLines, -1

global Console := new CConsole()
Console.hotkey := "^+c"  ; to show the console
Console.show()

SocketManager := new SocketServiceHandler()

http := new HttpServer(8000)

http.StaticFolder("static")
http.StaticRoute("index.html")


ws := new WSserver(8080)
ws.addProtocol("mouse", Func("WSmouse"))


SocketManager.RegisterService(http)
SocketManager.RegisterService(ws)

SocketManager.StartServices()

return

WSmouse(ByRef Request, ByRef Response, ByRef client){
    data := JSON.Load(Request.getMessage())
    
    x := data.x
    y := data.y
    btn := data.btn
    
    if(x != 0 or y != 0){
        MouseMove x, y, 0, R
    }
    
    if(data.btn == 1){
        MouseClick left
    }
    if(data.btn == 2){
        MouseClick right
    }
    
    ;return data
}

Esc::ExitApp

#include, %A_ScriptDir%\..\..\libs
#include, JSON.ahk
#include, CConsole.ahk
#Include, SocketService.ahk
#include, HTTP.ahk
#include, WS.ahk