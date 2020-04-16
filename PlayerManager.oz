functor
import
	PlayerBasicAI
	Player
	PlayerRandom
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player1 then {Player.portPlayer Color ID}
		[] player2 then {Player.portPlayer Color ID}
		[] player3 then {Player.portPlayer Color ID}

		% of player6 then {PlayerBasicAI.portPlayer Color ID}
		% [] player5 then {PlayerBasicAI.portPlayer Color ID}
		% [] player4 then {PlayerBasicAI.portPlayer Color ID}
		% [] player3 then {PlayerBasicAI.portPlayer Color ID}
		% [] player2 then {PlayerBasicAI.portPlayer Color ID}
		% [] player1 then {PlayerBasicAI.portPlayer Color ID}

		end
	end
end
