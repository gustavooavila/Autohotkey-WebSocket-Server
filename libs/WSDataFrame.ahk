class WSDataFrame{
     decode(ByRef data, bDataLength) {
        fin := NumGet(&data, "UChar")
        
        if(fin == 0x88){
            return
        }
        
        if(bDataLength > 125) {
            return WSDataFrame.decodebig(data, bDataLength)
            
        }else
        {
            return WSDataFrame.decodesmall(data, bDataLength)
        }
    }
    
    decodesmall(ByRef data, bDataLength) {
        fin := NumGet(&data, "UChar")
        length := NumGet(&data + 1, "UChar")
        
        ; check if masked
        if(length > 128) {
            key := []
            payload := []
            
            Loop %bDataLength% {
                byte := NumGet(&data + A_Index - 1, "UChar")
                if(A_Index > 2 && A_Index < 7 ){
                    key.push(byte)
                }else
                if(A_Index > 6){
                    payload.push(byte)
                }   
            }    
        result := XOR(payload, key)
        } else {
            Loop %length%{
                byte := NumGet(&data + 2 + A_Index - 1, "UChar")
                result .= chr(byte)
            }
        }
        
        return result
    }
    
    encode(message) {
        length := strlen(message)
        if(length < 125) {
            byteArr := [129, length]
            buf := new Buffer(length + 2)
            Loop, Parse, message
            byteArr.push(Asc(A_LoopField))
            VarSetCapacity(result, byteArr.Length())
            For, i, byte in byteArr
            NumPut(byte, result, A_Index - 1, "UInt")
            buf.Write(&result, length + 2)
        }
        return buf
    }
    
    decodebig(ByRef data, bDataLength){
        return data    
    }
}
