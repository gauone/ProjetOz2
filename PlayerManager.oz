functor
import
	PlayerBasicAI
	Player
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player4 then {PlayerBasicAI.portPlayer Color ID}
		[] player3 then {PlayerBasicAI.portPlayer Color ID}
		[] player2 then {PlayerBasicAI.portPlayer Color ID}
		[] player1 then {Player.portPlayer Color ID}

		end
	end
end
