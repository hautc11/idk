# OSI Model - Open System Interconnection Model

> It is the blueprint for understanding how networks should work.


```
                     +-------------------------+                                           
                     |                         |                                           
                     |      Application (7)    |<-------------------------------+          
                     |                         |                                |          
                  +--------------------------------+                            |          
                  |                                |                            |          
                  |         Presentation (6)       |                            |          
                  |                                |                            |          
              +----------------------------------------+                        |          
              |                                        |                 The important ones
              |                Session (5)             |                     |       |     
              |                                        |                     |       |     
           +-----------------------------------------------+                 |       |     
           |                                               |                 |       |     
           |                 Transport (4)                 |<----------------+       |     
           |                                               |                         |     
       +-------------------------------------------------------+                     |     
       |                                                       |                     |     
       |                     Network  (3)                      |<--------------------+     
       |                                                       |                           
    +-------------------------------------------------------------+                        
    |                                                             |                        
    |                        Data Link (3)                        |                        
    |                                                             |                        
+---------------------------------------------------------------------+                    
|                                                                     |                    
|                            Physical (2)                             |                    
|                                                                     |                    
+---------------------------------------------------------------------+                    
```

## Network Layer (3)

This is where protocals like IP, and others handle routing, addressing, and packet forwarding.

### IP (Internet Protocol)

* The responsibility for IP is basically to give names that are usable to nodes (physical or virtual device that connected to a network and is capable of sending, receiving, or forward data) on the network and allow routing.

* We have two types of names:
    * IPv4
    * IPv6

* IP will come in two forms:
    * Private Address.
    * Public Address.

## Transport Layer (4)

This is where TCP and UDP provide some additional functionality on top of IP like guaranteed ordering or reliable delivery and so on.

### TCP (Transmission Control Protocol)

* Give you some additonal features on top of IP like guaranteed delivery and ordering.
* Reliable, default, guarantees ordering >< throughput, latency.

### UDP (User Datagram Protocol)

* It just sends the data and moves on.
* No guarantee, data can arrive out of order.
* Speed and Efficiency.

## Application (7)

It is the only layer that interacts directly with your software (like a web browser or email client).

### HTTP protocol

* HTTP is the Tool (The "Hammer"): It is a Protocol. It defines how data gets from Point A to Point B. It provides the mechanism (verbs like GET/POST, headers, status codes).

* REST is the Rulebook (The "Blueprint"): It is an Architectural Style. It defines how you should use the tool (HTTP) to organize your data so that it is scalable and easy to understand.

* The way HTTP work is simple text formatted request and responses.

    ```
    #Request

    GET /order/1 HTTP/1.1
    Host: fake.api
    User-Agent: Mozilla/5.0
    Accept: application/json

    #Response
    
    HTTP/1.1 200 OK
    Content-Type: application/json

    {
        "orderId": 1,
        "items": [
            ...
        ]
    }
    ```

### Websocket, gRPC, WebRTC...