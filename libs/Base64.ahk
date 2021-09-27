;;taken from autohotkey.com/board/topic/117778-convert-hex-string-to-real-binary/#entry675902
;HexStr2BinHex(hexString, byref var)
;{
;    sizeBytes := strlen(hexString)//2
;    VarSetCapacity(var, sizeBytes)
;    loop, % sizeBytes
;    numput("0x" substr(hexString, A_Index * 2 - 1, 2), var, A_Index - 1, "UChar")
;    return sizeBytes
;}
;
;;original from autohotkey.com/board/topic/5545-base64-coderdecoder/?p=33960
;HexBase64(string){
;    size := HexStr2BinHex(string,value)
;    Loop % size
;    {
;        curValue := NumGet(value, A_Index-1, "UChar")
;        If Mod(A_Index,3) = 1{
;            b64buffer := curValue << 16
;        }
;        Else If Mod(A_Index,3) = 2{
;            b64buffer += curValue << 8
;        }
;        Else {
;            b64buffer += curValue
;            out := out . Code(b64buffer>>18) . Code(b64buffer>>12) . Code(b64buffer>>6) . Code(b64buffer)
;        }
;    }
;    If Mod(StrLen(string),3) = 0
;    Return out
;    If Mod(StrLen(string),3) = 1
;    Return out . Code(b64buffer>>18) . Code(b64buffer>>12) "=="
;    Return out . Code(b64buffer>>18) . Code(b64buffer>>12) . Code(b64buffer>>6) "="
;}

;Code(i) {   ; <== Chars[i & 63], 0-base index
;    Chars = ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
;    StringMid i, Chars, (i&63)+1, 1
;    return i
;}

;taken from autohotkey.com/board/topic/9974-include-a-bitmap-in-your-uncompiled-script/?p=63195
StringCaseSense On

HexBase64(hex) { ; StrLen(hex) must be even
   Loop Parse, hex
   {
      m := Mod(A_Index,3)
      x  = 0x%A_loopfield%
      IfEqual      m,1, SetEnv z, % x << 8
      Else IfEqual m,2, EnvAdd z, % x << 4
      Else {
         z += x
         o := o Code(z>>6) code(z)
      }
   }
   IfEqual m,2, Return o Code(z>>6) Code(z) "=="
   IfEqual m,1, Return o Code(z>>6) "="
   Return o
}


Code(i) {   ; <== Chars[i & 63], 0-base index
   Chars = ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
   StringMid i, Chars, (i&63)+1, 1
   Return i
}
