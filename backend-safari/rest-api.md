# REST

## What is REST actually?

**REST** stands for **RE**presentational **S**tate **T**ransfer.

> 1. Names (resources) for things: unique url for each thing.
> 2. Action words for task: GET, POST, PUT, DELETE.
> 3. Stateless: short memory - prove who you are every time interact with it (token).

It's not a library or a [protocol](). It is an Architectural Style that treat server data as "Resources" and use standard [HTTP Method](#the-http-methods) to interact with them. It is a set of rules that, if followed, will make our API scalable a reliable.

If we break these rules, our API might still work but it cannot be considered truly "RESTful".

## The HTTP Methods

| Method | Role |
|--------|-------------------------------------------------------------|
| GET    | Retrieve data. Should never modify data.                    |
| POST   | Create a new resource.                                      |
| PUT    | Update a resource (replace the whole thing).                |
| PATCH  | Update a resource (modify only specific fields).            |
| DELETE | Remove a resource.                                          |

## PUT vs. PATCH
- **PUT (Replace)**
    - Scenario: "This is the new version of Order#1. Overwrite the old one completely".
    - FE will send the entire object. If a field is missing in the request, BE should technically set that field to null or default value.
- **PATCH (Modify)**
    - Scenario: "Order#1 just change the quantity of Cheese. Just keep the other information."
    - FE send only the data that changed.

**Why it matters?**
→ Using PUT when you meant PATCH can accidentally wipe out data if FE didn't send the full object.

## Path Parameters vs. Query Parameters
- **PATH** (/order/1): Used to identify a specific resource. If we remove this, the URL must not point to the same "thing".
- **Query** (/orders?page=1&size=20): Used to sort, filter, or paginate. If we remove this, we still be able to looking at the list of all orders. BUT just a different view of them.