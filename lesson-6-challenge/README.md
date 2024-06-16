| Name                          | AOS Name                | Process ID                                  |
| ----------------------------- | ----------------------- | ------------------------------------------- |
| Token                         | lesson6-token           | 6JJw9kdSC4EIQTWMDQzxlzRuQyYEzzljlD9U8bH1FIk |
| Rock-Paper-Scissors Game Room | lesson6-rps-gameroom    | M568XMXSDeMhLHZX3kmO4ih3ZevzHrzPLb8BvgUkK_4 |
| Game Master                   | lesson6-game-master     | 3Qc_cdoNDX0Jj5QTuGd6ctem8xxgj9ktTXDBNSC5sfo |
| Player Listener               | lesson6-player-listener |                                             |

## How to play?

1. RPS = "M568XMXSDeMhLHZX3kmO4ih3ZevzHrzPLb8BvgUkK_4"
2. Send({ Target = RPS, Action = "Register" })
3. Wait for the game to start once we have enough players (at least 4); the game will divide the players into 2 teams
4. Once the game starts, you should make a move: Send({ Target = RPS, Action = "Move", Move = "<Rock | Paper | Scissors>" })
5. Wait for the game to end and see if you won or lost
