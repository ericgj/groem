## Oct 10

DONE 1. Refactor routing to use separate parts instead of "/"
DONE 2. Allow CLOSE|CLOSED, CLICK|CLICKED, TIMEOUT|TIMEDOUT or symbols
DONE 3. Refactor response array - 3rd element should be hash with all Notification-Callback- headers in it
DONE 4. Add integration tests for App notify with callbacks
DONE 4. Clean up callbacks?
DONE 5. Clean up constants?
6. Rename EM_GNTP to Groem?
DONE 7. Take out debugging lines from Client
8. Gem release ??




## This is what I see as the order of work

### First the infrastructure

1. Basic em client that (a) sends requests in gntp format to server, (b) hangs up appropriately with the server based on responses, (c) register/throw synchronous responses from server.

1.1 What the em client requires from request and response models: structs that define #load and #dump.  EM client allows you to specify class of response thrown for each type of GNTP request (Register, Notify, Subscribe).

1.2 Request and response classes for Notify action.


2. EM client (d) registers/throws callbacks with asynchronous responses.

3. Request and response classes for Register action.


### Then the interface

4. App class that (a) builds register request and (b) uses em client to send it (#register)

5. App class (c) saves default settings for notify requests (#notification) and (d) sends notify requests (#notify)

6. App class (e) defines simple callback handlers for notifications (#when_closed, #when_clicked, #when_timeout) which register as em client callbacks before #notify (?)

7. App class allows 'filterable' callback handlers



