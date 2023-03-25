# **ServerCalls**

Server calls are when the script connects directly to the game's back end API rather than performing actions in game. This is useful for things like getting user/game data, buying/opening chests in bulk, activating chest codes, and much more.

The back end API responds to http get/post requests. Script Hub has some functions to simplify this process using the correct credentials pulled directly from the game. These functions can be called using the global variable ``g_ServerCall``.

Before using any functions in the ServerCall class, it is important to update credentials using the ``g_SF.ResetServerCall()`` function while the game is open. 

See the [example](./../Example_ServerCall/) with line by line descriptions.

