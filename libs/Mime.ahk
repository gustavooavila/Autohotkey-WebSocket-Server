class MimeTypes
{
    __New(){
        position := InStr(A_LineFile, "\", false, -1)
        libfolder := SubStr(A_LineFile, 1, position)
        this.LoadMimes(libfolder . "mime.types")
        
    }
    LoadMimes(file) {
        if (!FileExist(file))
            return false
            
        FileRead, data, % file
        types := StrSplit(data, "`n")
        this.mimes := {}
        for i, data in types {
            info := StrSplit(data, " ")
            type := info.Remove(1)
            ; Seperates type of content and file types
            info := StrSplit(LTrim(SubStr(data, StrLen(type) + 1)), " ")

            for i, ext in info {
                this.mimes[ext] := type
            }
        }
        return true
    }

    GetMimeType(file) {
        default := "text/plain"
        if (!this.mimes)
            return default

        SplitPath, file,,, ext
        type := this.mimes[ext]
        if (!type)
            return default
        return type
    }
}