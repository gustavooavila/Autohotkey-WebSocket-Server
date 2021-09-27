/*
    this is where we hide the ugly code, Yeah it gets uglier...
    acording to the Websocket RFC: http://tools.ietf.org/html/rfc6455
    there's lots of bytes that we need to scrub before we can get the data from our data frames
    data frames? you may ask, well yes, the packets we transfer in a websocket connection has frames
    and those frames change format according to the ammount of data we need to send
    we will check each kind in depth once I wrap my head around coding this... I'm kinda putting it aside for a while tbh
    
    references: 
    http://tools.ietf.org/html/rfc6455
    https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers
    https://www.iana.org/assignments/websocket/websocket.xhtml
    
    implementation references:
    Lua: https://github.com/lipp/lua-websockets/blob/master/src/websocket/frame.lua
    Python: https://github.com/aaugustin/websockets/blob/main/src/websockets/frames.py
    JS: https://github.com/websockets/ws/blob/master/lib/receiver.js
    JS: https://github.com/websockets/ws/blob/master/lib/sender.js
    
*/

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
                if(A_Index > 2 && A_Index < 7 ) {
                    key.push(byte)
                }else
                if(A_Index > 6) {
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
