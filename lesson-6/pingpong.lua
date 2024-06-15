Handlers.add(
    "Pingpong!",
    Handlers.utils.hasMatchingTag("Action", "Ping"),
    Handlers.utils.reply("Pong!")
)

Handlers.add(
    "Pongping!",
    Handlers.utils.hasMatchingTag("Action", "Pong"),
    Handlers.utils.reply("Ping!")
)
