# Horizontal VS. Vertical Scaling

## Horizontal Scaling

- Where we use bigger hosts and more hardware, more memory, more CPU.

```
                       +-----------------+
                       |                 |
                       |                 |
                       |                 |
                       |                 |
+----------+           |                 |
|          | scale to  |                 |
|  Server  +---------->|      Server     |
|          |           |                 |
+----------+           |                 |
                       |                 |
                       |                 |
                       |                 |
                       +-----------------+
```

## Vertical Scaling

- Where we're going to duplicate our server and find someway of [balancing](/network/load-balancing.md) our request and our data between them.

```
                           +-----------+                 
                           |           |                 
                           |  Server3  |                 
                           |           |                 
                           +-----------+                 
+----------+               +-----------+                 
|          | scale to      |           |                 
|  Server  +-------------->|  Server1  |                 
|          |               |           |                 
+----------+               +-----------+                 
                           +-----------+                 
                           |           |                 
                           |  Server2  |                 
                           |           |                 
                           +-----------+                 
                                                        
```