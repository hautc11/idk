# Load Balancing

```
                           +------------+                 
                           |            |                 
                           |  Server-3  |                 
                           |            |                 
                           +------------+                 
+----------+               +------------+                 
|          |      ?        |            |                 
|  Client  +-------------->|  Server-2  |                 
|          |               |            |                 
+----------+               +------------+                 
                           +------------+                 
                           |            |                 
                           |  Server-1  |                 
                           |            |                 
                           +------------+                 
                                                        
```

- Load balancing serves two purposes:

    1. It spread the load so that way we can actually handle way more traffic than a single server could handle.
    2. Provide high availability: If Server-1 goes down theoretically client can connect to Server-2 or Server-3.

- There's two way to apply load balancing:
    1. Client side load balancing: Client be aware of all the server. They will query some sort of registry that tell them about the existence of all the server.
    2. Server side load balancing.