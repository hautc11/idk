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

Load balancing is the process of distributing incoming traffic across multiple servers instead of sending all requests to a single server.

### Why Load Balancing?

Load balancing serves two main purposes:

- **Scalability**  
  Spread traffic across multiple servers so the system can handle more requests than a single server could.

- **High Availability**  
  If one server goes down, traffic can be routed to other healthy servers.

---

## Types of Load Balancing

### 1. Client-Side Load Balancing
In client-side load balancing, the **client is aware of all available servers**.

- The client queries a service registry or configuration to discover servers.
- The client decides which server to call.

---

### 2. Server-Side Load Balancing
In server-side load balancing, the **client sends requests to a single endpoint** (the load balancer).

- The load balancer routes traffic to backend servers.
- Clients do not need to know how many servers exist.

Server-side load balancing can be further categorized as follows:

#### Layer 4 (L4) Load Balancing
- Operates at the **transport layer (TCP/UDP)**.
- Routes traffic based on IP address and port.
- Fast and efficient, but not aware of request content.

#### Layer 7 (L7) Load Balancing
- Operates at the **application layer (HTTP/HTTPS)**.
- Routes traffic based on request data such as URL paths or headers.
- Enables more flexible routing logic.

#### Global Server Load Balancing (GSLB)
- Operates at a **global level**, usually using DNS.
- Routes users to the closest or healthiest region or data center.
- Often used together with L4 or L7 load balancers inside each region.

## When to Use Which?

- **Client-Side Load Balancing**
  - Internal services
  - Trusted clients
  - Simple infrastructure, more logic on the client

- **L4 Load Balancing**
  - High performance and low latency
  - Simple traffic distribution
  - Works with any protocol

- **L7 Load Balancing**
  - Web and API traffic
  - Need routing based on URL, headers, or cookies
  - Common in microservices architectures

- **GSLB**
  - Global users
  - Multi-region deployments
  - Disaster recovery and latency optimization

## Key Takeaway

- **Client-side vs Server-side**: Who decides where the request goes
- **L4 vs L7**: How much of the request is inspected
- **GSLB**: Which region or data center should handle the request

In modern systems, these approaches are often **combined** to provide scalability, availability, and global reach.

---
### Simple Request Flow

This flow shows how different types of server-side load balancing work together in a typical production system.

```
+----------+     +----------+    +----------------------+    +--------------------+
|          |     |          |    |                      |    |                    |
|  Client  +---->|   GSLB   +--->| L4/L7 Load Balancer  +--->| Application Server |
|          |     |          |    |                      |    |                    |
+----------+     +----------+    +----------------------+    +--------------------+
```

**Step-by-step explanation:**

1. **Client**  
   The client (browser or mobile app) sends a request to a single domain name (e.g. `api.example.com`).

2. **GSLB (Global Level)**  
   - DNS resolves the domain to the best region or data center.
   - The decision is based on factors like user location, latency, or regional health.

3. **L4 / L7 Load Balancer (Regional Level)**  
   - Once the request reaches a region, a local load balancer selects a backend server.
   - **L4** chooses based on IP and port.
   - **L7** can choose based on request content such as URL path or headers.

4. **Application Server**  
   The selected server processes the request and returns a response to the client.

**Important Note**

- Clients are unaware of servers, regions, or routing logic.
- Multiple load balancers can exist at different layers, but they work together as a single system.
