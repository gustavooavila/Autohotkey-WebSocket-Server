#Persistent
#SingleInstance, force
SetBatchLines, -1


global Console := new CConsole()
Console.hotkey := "^+c"  ; to show the console
Console.show()

http := new HttpServer()

http.StaticFolder("static")
http.StaticRoute("index.html")
http.DinamicRoute("/mouseStatus",Func("MouseStatus"))
ws := new WSserver(http)

ws.addRoute("mouse",Func("WSmouse"))

ws.setup()

http.Serve(8080)

return

MouseStatus(Byref req, Byref res){
    Console.log(req.queries)
    x := req.queries.x
    y := req.queries.y
    MouseMove, x, y, 50, R
    res.status := 200
}
WSmouse(){
    return
}
Esc::ExitApp

#include %A_ScriptDir%\libs
#include, HTTP.ahk
#include, WS.ahk
#include, CConsole.ahk