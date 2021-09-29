/*
    this is where we hide the ugly code, Yeah it gets uglier...
    acording to the Websocket RFC: http://tools.ietf.org/html/rfc6455
    there's lots of bytes that we need to scrub before we can get the message data
    according to ammount of data the message may be split in multiple data frames
    as well as change the format of the data frame
    
    
    Frame format:
    0               1               2               3               4    bytes
    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-------+-+-------------+-------------------------------+
    |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
    |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
    |N|V|V|V|       |S|             |   (if payload len==126/127)   |
    | |1|2|3|       |K|             |                               |
    +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
    |     Extended payload length continued, if payload len == 127  |
    + - - - - - - - - - - - - - - - +-------------------------------+
    |                               |Masking-key, if MASK set to 1  |
    +-------------------------------+-------------------------------+
    | Masking-key (continued)       |          Payload Data         |
    +-------------------------------- - - - - - - - - - - - - - - - +
    :                     Payload Data continued ...                :
    + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
    |                     Payload Data continued ...                |
    +---------------------------------------------------------------+
    
    OpCodes: 
    0x8 Close
    0x9 Ping
    0xA Pong
    
    Payload data OpCodes:
    0x0 Continuation
    0x1 Text
    0x2 Binary
    
    
    
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
Uint16(a, b){
    return a * 256 + b
}

Uint16SplitUint8(c){
    a := Mod(c, 256)
    b := c - a
    return [a, b]
}

class WSFrameHeader {
    __new(ByRef data, bDataLength){
        byte1 := NumGet(&data, "UChar")
        byte2 := NumGet(&data + 1, "UChar")
        
        this.big := bDataLength > 125
        
        this.fin  := byte1 & 0x80 ? True : False ; indicates the end of the message
        
        this.rsv1 := byte1 & 0x40 ? True : False
        this.rsv2 := byte1 & 0x20 ? True : False
        this.rsv3 := byte1 & 0x10 ? True : False
        
        this.opcode := byte1 & 0x0F
        
        this.mask := byte2 & 0x80 ? True : False ; indicates if the content is masked(XOR)
        
        this.key := []
        this.length := 0
        
        if(this.big) {
        this.length := Uint16(NumGet(&data + 2, "UChar"), NumGet(&data + 3, "UChar"))
        } else {
            this.length := byte2 & 0x7F    
            if(this.mask){
                this.key[1] := NumGet(&data + 2, "UChar")
                this.key[2] := NumGet(&data + 3, "UChar")
                this.key[3] := NumGet(&data + 4, "UChar")
                this.key[4] := NumGet(&data + 5, "UChar")
            }
        }
    }
}

class WSDataFrame{
    decode(ByRef data, bDataLength) {
        header := new WSFrameHeader(data, bDataLength)
        console.log(header)
        
        if(bDataLength > 125) {
            return WSDataFrame.decodebig(data, bDataLength, header)
            
        }else
        {
            return WSDataFrame.decodesmall(data, bDataLength, header)
        }
    }
    
    decodesmall(ByRef data, bDataLength, header) {
        length := header.length
        
        if(header.mask) {
            payload := []
            
            Loop %length% {
                byte := NumGet(&data + 6 + A_Index - 1, "UChar")
                payload.push(byte)
            }
        result := XOR(payload, header.key)
        } else {
            Loop %length%{
                byte := NumGet(&data + 2 + A_Index - 1, "UChar")
                result .= chr(byte)
            }
        }
        
        return result
    }
    
    decodebig(ByRef data, bDataLength, header){
        return data
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
    
}
