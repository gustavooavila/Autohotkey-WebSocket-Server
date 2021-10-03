class EventEmitter
{
    __new()
    {
        this.events := {}
    }
    
    _addListener(event, ByRef listener, atStart := 0, once := 0){
        if(!this.events[event])
        {
            this.events[event] := []
        }
        
        if(atStart)
        {
            this.events[event].InsertAt(1, {listener: listener, once: once})
        }
        else
        {
            this.events[event].append({listener: listener, once: once})
        }
        
        return this
    }
    
    removeListener(event, ByRef listener)
    {
        if(this.events[event])
        {
            if(listener)
            {
                For i, eventListener in this.events[event]
                {
                    if(eventListener.listener == listener)
                    {
                        this.events[event].RemoveAt(i)
                    }
                }
            }
        }
        else
        {
            iListeners := this.events[eventName].Length()
            this.events[eventName].RemoveAt(1, iListeners-1)
        }
    }
    
    emit(eventName, args*)
    {
        if(this.events[eventName])
        {
            iListeners := this.events[eventName].Length()
            if(iListeners)
            {
                For i, eventListener in this.events[eventName]
                {
                    eventListener.listener(args*)
                    if(eventListener.once)
                    {
                        this.events[eventName].RemoveAt(i)
                    }
                }
            }
            return iListeners
        }
        return 0
    }
    
    
    prependOnceListener(event, ByRef listener)
    {
        return this._addListener(event, listener, 1, 1)
    }
    
    prependListener(event, ByRef listener)
    {
        return this._addListener(event, listener, 1, 0)
    }
    
    addListener(event, ByRef listener)
    {
        return this._addListener(event, listener, 0, 0)
    }
    
    once(event, ByRef listener)
    {
        return this._addListener(event, listener, 0, 1)
    }
    
    on(event, ByRef listener)
    {
        return this.addListener(event, listener)
    }
    
    off(event, ByRef listener)
    {
        this.removeListener(event, listener)
    }
}