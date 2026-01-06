# Status Code

> Digital thumb signal from the server. Since the server can't speak, it uses these 3-digit numbers to tell you if your request worked or if something went wrong.

## How to Read the Numbers?
Just check the first digit of the code, it will tells you the "category" of the result:
- 2xx - Success.
- 4xx - Client Error.
- 4xx - Server Error.

## The Most Popular Status Code

The "Happy" Codes (Success)
* **200 OK**
* **201 Created**

The Client Error Codes
* **400 Bad Request**: We might have sent a messy or incomplete request.
* **401 Unauthorized**: Who are you?
* **403 Forbidden**: You are not allowed to touch this!
* **404 Not found**: url/item doesn't exist.

Server Mistake
* **500 Internal Server Error**: Something inside the server crashed, and it doesn't know why.
* **503 Service Unavailable**: The server is too busy or down for maintenance.