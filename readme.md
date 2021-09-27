
#  Autohotkey Websocket HTTP Server

100% Autohotkey implementation of Websocket and HTTP server
comes with a mousepad-esque app as example

## TODO:
* allow bigger than 125 bytes messages on websocket (just need to implement the other frame types/sizes)
* respond to WS disconnect and clear client references (garbage collection type of thing)
* allow to run the websocket on the same port as the http server
* clean the spaghetti
* maybe some documentation ???

## Thanks to:
* GeekDude: for the amazing [cJson.ahk](https://github.com/G33kDude/cJson.ahk)
* zhamlin: for [AHKhttp](https://github.com/zhamlin/AHKhttp) the inspiration (and basis) for this project
* jNizM: for [AHK_CNG](https://github.com/jNizM/AHK_CNG) from which I stole the SHA1 hashing
* Laszlo: for the [Base64](https://autohotkey.com/board/topic/9974-include-a-bitmap-in-your-uncompiled-script/page-2#entry63195) decoder, which btw was a pain in the a** to find, somehow most base64 decoders I tried didn't work smh, also I learned a lot from his posts on the forums


## Everyone on Discord, thank you very Much
the usual suspects, in no particular order
* Micha
* Devise
* A Real Username
* andreas@ESA
* Chunjee
* tidbit
* Firecul
* B_M_N
* GeekDude

to be honest this readme is looking more like a graduation discurse than a readme ... oh well
¯\_(ツ)_/¯