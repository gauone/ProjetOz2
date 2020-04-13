functor
export
   isTurnByTurn:IsTurnByTurn
   nRow:NRow
   nColumn:NColumn
   map:Map
   nbPlayer:NbPlayer
   players:Players
   colors:Colors
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   turnSurface:TurnSurface
   maxDamage:MaxDamage
   missile:Missile
   mine:Mine
   sonar:Sonar
   drone:Drone
   minDistanceMine:MinDistanceMine
   maxDistanceMine:MaxDistanceMine
   minDistanceMissile:MinDistanceMissile
   maxDistanceMissile:MaxDistanceMissile
   guiDelay:GUIDelay
define
   IsTurnByTurn
   NRow
   NColumn
   Map
   NbPlayer
   Players
   Colors
   ThinkMin
   ThinkMax
   TurnSurface
   MaxDamage
   Missile
   Mine
   Sonar
   Drone
   MinDistanceMine
   MaxDistanceMine
   MinDistanceMissile
   MaxDistanceMissile
   GUIDelay
in

%%%% Style of game %%%%

   %IsTurnByTurn = true

   IsTurnByTurn = false

%%%% Description of the map %%%%

   NRow = 10
   NColumn = 10

   Map = [[0 0 0 0 0 0 0 0 0 0 ]
          [0 1 1 1 0 0 0 0 0 0 ]
          [0 0 0 0 0 0 1 1 0 0 ]
          [0 0 0 0 0 1 1 0 0 0 ]
          [0 0 0 1 1 1 1 0 0 0 ]
          [0 0 0 0 0 0 0 0 0 0 ]
          [0 0 0 1 1 0 0 0 1 0 ]
          [0 0 0 0 1 0 0 0 1 0 ]
          [0 0 0 0 1 0 0 0 1 0 ]
          [0 0 0 0 0 0 0 0 0 0 ]]

%%%% Players description %%%%

   % NbPlayer = 6
   % Players = [player1 player2 player3 player4 player5 player6]
   % Colors = [red green black blue white yellow]

   NbPlayer = 3
   Players = [player1 player2 player3]
   Colors = [red black green]

%%%% Thinking parameters (only in simultaneous) %%%%

   %ThinkMin = 500
   %ThinkMax = 3000

   ThinkMin = 20
   ThinkMax = 50

%%%% Surface time/turns %%%%

   TurnSurface = 3

%%%% Life %%%%

   MaxDamage = 2

%%%% Number of load for each item %%%%

   Missile = 3
   Mine = 3
   Sonar = 3
   Drone = 3

%%%% Distances of placement %%%%

   MinDistanceMine = 3
   MaxDistanceMine = 5
   MinDistanceMissile = 3
   MaxDistanceMissile = 5

%%%% Waiting time for the GUI between each effect %%%%

   GUIDelay = 500 % ms

end
