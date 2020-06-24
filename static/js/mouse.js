(function(){
    class Mouse {
        constructor(){
            this.state = {"x":0, "y":0, "btn":0};
            this.touchstart = {"x":0, "y":0};
            this.touching = false;
            this.MousePad = $("#mousePad").hammer();
            this.LeftMouseBtn = $("#leftMouseBtn");
            this.RightMouseBtn = $("#rightMouseBtn");

            this.registerEvents();
        }
        resetState(){
            this.state = {"x":0, "y":0, "btn":0};
        }
        registerEvents(){
            this.MousePad.on("panstart",(ev)=>{
                this.touchstart.x = ev.gesture.deltaX;
                this.touchstart.y = ev.gesture.deltaY;
            })
            this.MousePad.on("panmove",(ev) => {
                const deltas = {"x":0,"y":0}
                deltas.x = ev.gesture.deltaX - this.touchstart.x;
                deltas.y = ev.gesture.deltaY - this.touchstart.y;
                this.sendMouse(deltas,0)
            });
            this.MousePad.on("panend",(ev) => {
                const deltas = {"x":0,"y":0}
                deltas.x = ev.gesture.deltaX;
                deltas.y = ev.gesture.deltaY;
                this.sendMouse(deltas,0)
            });
        }
        
        sendMouse(deltas,btn){
            console.log(deltas,btn)
            $.get("./MouseStatus",{...deltas,btn})
        }
    }
    
    new Mouse();
    
})()


const socket = new WebSocket('ws://localhost:8080','mouse');

// Connection opened
socket.addEventListener('open', function (event) {
    socket.send('Hello Server!');
});

// Listen for messages
socket.addEventListener('message', function (event) {
    console.log('Message from server ', event.data);
});