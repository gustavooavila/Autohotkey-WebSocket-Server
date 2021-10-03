#Include Buffer.ahk
#Include URI.ahk
#Include Mime.ahk

class StaticRoute{
    __New(path){
        this.path := path
    }
    serve(ByRef req, ByRef res, ByRef server) {
        res.ServeFile(this.path)
        res.status := 200
    }
    __Call(method, args*) {
        if (method = "")
        return this.serve(args*)
        if (IsObject(method))
        return this.serve(method, args*)
    }
}

class HTTPRouter{
    __New(ByRef server){
        this.server := server
        this.routes := {}
    }
    StaticRoute(path){
        url := StrReplace(path,"\", "/")
        url = /%url%
        this.routes[url] :=  new StaticRoute(path)
    }
    StaticFolder(path){
        Loop Files, %path%\*, FR
        {
            this.StaticRoute(A_LoopFileFullPath)
        }
    }
    DinamicRoute(path, ByRef func){
        this.routes[path] := func
    }
    
    Handle(ByRef request) {
        response := new HttpResponse()
        requested := this.routes[request.path]
        if (requested){
        requested.(request, response, this)
        }else{
            response.status := 404
        }
        
        return response
    }
}

class HttpServer
{
    __new(port){
        this.Router := new HTTPRouter()
        this.port := port
    }
    
    static servers := {}
    
    StaticRoute(path){
        this.Router.StaticRoute(path)
    }
    
    StaticFolder(path){
        this.Router.StaticFolder(path)
    }
    
    DinamicRoute(path, func){
        this.Router.DinamicRoute(path, func)
    }
    
    handler(ByRef client, ByRef bData = 0, bDataLength = 0) {
        text := StrGet(&bData, "UTF-8")
        ; New request or old?
        if (client.request) {
            ; Get data and append it to the existing request body
            client.request.bytesLeft -= StrLen(text)
            client.request.body := client.request.body . text
        request := client.request
        } else {
            ; Parse new request
            request := new HttpRequest(text)
            
            length := request.headers["Content-Length"]
            request.bytesLeft := length + 0
                        
            if (request.body) {
                request.bytesLeft -= StrLen(request.body)
            }
        }
        if (request.bytesLeft <= 0) {
        request.done := true
        } else {
            client.request := request
        }
        
        if (request.done || request.IsMultipart()) {
            response := this.Router.Handle(request)
            if (response.status) {
                console.log("new HTTP Request")
                console.log("Route: ", request.path)
                client.SetData(response.Generate())
            }
        }
        if (client.TrySend()) {
            if (!request.IsMultipart() || request.done) {
                client.Close()
            }
        }    
        
    }
}

class HttpRequest
{
    __New(data = "") {
        if (data)
        this.Parse(data)
    }
    
    GetPathInfo(top) {
        results := []
        while (pos := InStr(top, " ")) {
            results.Insert(SubStr(top, 1, pos - 1))
            top := SubStr(top, pos + 1)
        }
        this.method := results[1]
        this.path := Uri.Decode(results[2])
        this.protocol := top
    }
    
    GetQuery() {
        pos := InStr(this.path, "?")
        query := StrSplit(SubStr(this.path, pos + 1), "&")
        if (pos)
        this.path := SubStr(this.path, 1, pos - 1)
        
        this.queries := {}
        for i, value in query {
            pos := InStr(value, "=")
            key := SubStr(value, 1, pos - 1)
            val := SubStr(value, pos + 1)
            this.queries[key] := val
        }
    }
    
    Parse(data) {
        this.raw := data
        data := StrSplit(data, "`n`r")
        headers := StrSplit(data[1], "`n")
        this.body := LTrim(data[2], "`n")
        this.GetPathInfo(headers.Remove(1))
        this.GetQuery()
        this.headers := {}
        
        for i, line in headers {
            pos := InStr(line, ":")
            key := SubStr(line, 1, pos - 1)
            val := Trim(SubStr(line, pos + 1), "`n`r ")
            
            this.headers[key] := val
        }
    }
    
    IsMultipart() {
        length := this.headers["Content-Length"]
        expect := this.headers["Expect"]
        
        if (expect = "100-continue" && length > 0)
        return true
        return false
    }
}

class HttpResponse
{
    __New() {
        this.headers := {}
        this.status := 0
        this.protocol := "HTTP/1.1"
        
        this.SetBodyText("")
        this.MimeTypes := new MimeTypes()
    }
    ServeFile(file) {
        f := FileOpen(file, "r")
        length := f.RawRead(data, f.Length)
        f.Close()
        
        this.SetBody(data, length)
        this.headers["Content-Type"] := this.MimeTypes.GetMimeType(file)
    }
    
    Generate() {
        FormatTime, date,, ddd, d MMM yyyy HH:mm:ss
        this.headers["Date"] := date
        headers := this.protocol . " " . this.status . "`r`n"
        for key, value in this.headers {
            StringReplace,value,value,`n,,A
            StringReplace,value,value,`r,,A
            headers := headers . key . ": " . value . "`r`n"
        }
        
        headers := headers . "`r`n"
        length := this.headers["Content-Length"]
        buffer := new Buffer((StrLen(headers) * 2) + length)
        buffer.WriteStr(headers)
        
        buffer.Append(this.body)
        buffer.Done()
        
        return buffer
    }
    
    SetBody(ByRef body, length) {
        this.body := new Buffer(length)
        this.body.Write(&body, length)
        this.headers["Content-Length"] := length
    }
    
    SetBodyText(text) {
        this.body := Buffer.FromString(text)
        this.headers["Content-Length"] := this.body.length
    }
}

