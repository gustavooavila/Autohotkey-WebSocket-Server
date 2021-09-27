(function(){
    let socket = new WebSocket('ws://localhost:8080', 'mouse');
    
    class Mouse {
        constructor(){
            this.state = {"x":0, "y":0, "btn":0};
            this.touchstart = {"x":0, "y":0};
            this.touching = false;
            this.MousePad = $("#mousePad").hammer();
            this.LeftMouseBtn = $("#leftMouseBtn");
            this.RightMouseBtn = $("#rightMouseBtn");
            socket.addEventListener('open',(event)=>{
                this.registerEvents();
            });
        }
        resetState(){
            this.state = {"x":0, "y":0, "btn":0};
        }
        registerEvents(){
            this.MousePad.on("panstart",(ev)=>{
                const deltas = {"x":0,"y":0}
                this.touchstart.x = ev.gesture.deltaX;
                this.touchstart.y = ev.gesture.deltaY;
            });
            
            this.MousePad.on("panmove",(ev) => {
                const deltas = {"x":0,"y":0}
                deltas.x = ev.gesture.deltaX - this.touchstart.x;
                deltas.y = ev.gesture.deltaY - this.touchstart.y;
                this.sendMouse(deltas, 0)
                this.touchstart.x = ev.gesture.deltaX;
                this.touchstart.y = ev.gesture.deltaY;
            });
            
            this.LeftMouseBtn.on("click", (ev)=>{
                const deltas = {"x":0,"y":0}
                this.sendMouse(deltas, 1);
            });
            
            this.RightMouseBtn.on("click", (ev)=>{
                const deltas = {"x":0,"y":0}
                this.sendMouse(deltas, 2);
            });
        }
        
        sendMouse(deltas,btn){
            socket.send(JSON.stringify({...deltas, btn}));
        }
    }
    
    new Mouse();
})()

