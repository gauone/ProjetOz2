functor
import
	QTk at 'x-oz://system/wp/QTk.ozf'
	Input
export
	portWindow:StartWindow
define

	StartWindow
	TreatStream

	RemoveItem
	RemovePath
	RemovePlayer

	Map = Input.map

	NRow = Input.nRow
	NColumn = Input.nColumn

	DrawSubmarine
	MoveSubmarine
	DrawMine
	RemoveMine
	DrawPath

	BuildWindow

	Label
	Squares
	DrawMap

	StateModification
	Explosion
	Sonared
	Droned

	UpdateLife


   /**************************************
    * Rajouts Graphisme
	*
	* Source : https://0x72.itch.io/dungeontileset-ii
	* All rights reserved to "0x72"
	* 
    *************************************/

   % C'est le floor car c'est la ou on peut bouger
   WaterIMG = {QTk.newImage photo(url:'img/floor.png' height:0 width:0)}

   % C'est les spikes car on ne peut pas y bouger
   IslandIMG = {QTk.newImage photo(url:'img/spikes.png' height:0 width:0)}

   WallIMG = {QTk.newImage photo(url:'img/wall.png' height:0 width:0)}

   GreenPlayer = {QTk.newImage photo(url:'img/player_green.png' height:0 width:0)}
   BluePlayer  = {QTk.newImage photo(url:'img/player_blue.png' height:0 width:0)}
   RedPlayer   = {QTk.newImage photo(url:'img/player_red.png' height:0 width:0)}
   BlackPlayer = {QTk.newImage photo(url:'img/player_black.png' height:0 width:0)}
   WhitePlayer = {QTk.newImage photo(url:'img/player_white.png' height:0 width:0)}
   YellowPlayer = {QTk.newImage photo(url:'img/player_yellow.png' height:0 width:0)}

   BluePt    = {QTk.newImage photo(url:'img/floor_blue.png'   height:0 width:0)}
   RedPt     = {QTk.newImage photo(url:'img/floor_red.png'    height:0 width:0)}
   GreenPt   = {QTk.newImage photo(url:'img/floor_green.png'  height:0 width:0)}
   WhitePt   = {QTk.newImage photo(url:'img/floor_white.png'  height:0 width:0)}
   BlackPt   = {QTk.newImage photo(url:'img/floor_black.png'  height:0 width:0)}
   YellowPt  = {QTk.newImage photo(url:'img/floor_yellow.png'  height:0 width:0)}

   Bomb1  = {QTk.newImage photo(url:'img/bomb1.png' height:0 width:0)}
   Bomb2  = {QTk.newImage photo(url:'img/bomb2.png' height:0 width:0)}
   Bomb3  = {QTk.newImage photo(url:'img/bomb3.png' height:0 width:0)}
   Bomb4  = {QTk.newImage photo(url:'img/bomb4.png' height:0 width:0)}
   Bomb5  = {QTk.newImage photo(url:'img/bomb5.png' height:0 width:0)}
   Bomb6  = {QTk.newImage photo(url:'img/bomb6.png' height:0 width:0)}
   Bomb7  = {QTk.newImage photo(url:'img/bomb7.png' height:0 width:0)}
   Bomb8  = {QTk.newImage photo(url:'img/bomb8.png' height:0 width:0)}
   Bomb9  = {QTk.newImage photo(url:'img/bomb9.png' height:0 width:0)}
   Bomb10 = {QTk.newImage photo(url:'img/bomb10.png' height:0 width:0)}
   Bomb11 = {QTk.newImage photo(url:'img/bomb11.png' height:0 width:0)}
   Bomb12 = {QTk.newImage photo(url:'img/bomb12.png' height:0 width:0)}

   MineIMG = {QTk.newImage photo(url:'img/mine.png' height:0 width:0)}

   DroneIMG = {QTk.newImage photo(url:'img/drone.png')}









in

%%%%% Build the initial window and set it up (call only once)
	fun{BuildWindow}
		Grid GridScore Toolbar Desc DescScore Window
	in
		Toolbar=lr(glue:we tbbutton(text:"Quit" glue:w action:toplevel#close))
		Desc=grid(handle:Grid height:500 width:500)
		DescScore=grid(handle:GridScore height:100 width:500)
		Window={QTk.build td(Toolbar Desc DescScore)}
  
		{Window show}

		% configure rows and set headers
		{Grid rowconfigure(1 minsize:50 weight:0 pad:0)}
		for N in 1..NRow do
			{Grid rowconfigure(N+1 minsize:50 weight:0 pad:0)}
			{Grid configure({Label N} row:N+1 column:1 sticky:wesn)}
		end
		% configure columns and set headers
		{Grid columnconfigure(1 minsize:50 weight:0 pad:0)}
		for N in 1..NColumn do
			{Grid columnconfigure(N+1 minsize:50 weight:0 pad:0)}
			{Grid configure({Label N} row:1 column:N+1 sticky:wesn)}
		end
		% configure scoreboard
		{GridScore rowconfigure(1 minsize:50 weight:0 pad:0)}
		for N in 1..(Input.nbPlayer) do
			{GridScore columnconfigure(N minsize:50 weight:0 pad:0)}
		end

		{DrawMap Grid}

		handle(grid:Grid score:GridScore)
	end

%%%%% Squares of water and island
	Squares = square(0:label(image:WaterIMG height:1 width:1)
					 1:label(image:IslandIMG height:1 width:1)
			        )

%%%%% Labels for rows and columns
	fun{Label V}
		label(image : WallIMG text:V)
	end

%%%%% Function to draw the map
	proc{DrawMap Grid}
		proc{DrawColumn Column M N}
			case Column
			of nil then skip
			[] T|End then
				{Grid configure(Squares.T row:M+1 column:N+1 sticky:wesn)}
				{DrawColumn End M N+1}
			end
		end
		proc{DrawRow Row M}
			case Row
			of nil then skip
			[] T|End then
				{DrawColumn T M 1}
				{DrawRow End M+1}
			end
		end
	in
		{DrawRow Map 1}
	end

%%%%% Init the submarine
	fun{DrawSubmarine Grid ID Position}
		Handle HandlePath HandleScore X Y Id Color LabelSub LabelScore
	in
		pt(x:X y:Y) = Position
		id(id:Id color:Color name:_) = ID

		case Color of 'yellow' then
				LabelSub = label(image:YellowPlayer handle:Handle height:1 width:1) 
			[] 'red'            then
				LabelSub = label(image:RedPlayer handle:Handle height:1 width:1)
			[] 'green'          then
				LabelSub = label(image:GreenPlayer handle:Handle height:1 width:1)
			[] 'black'          then
				LabelSub = label(image:BlackPlayer handle:Handle height:1 width:1)
			[] 'blue'           then
				LabelSub = label(image:BluePlayer handle:Handle height:1 width:1)
			[] 'white'          then
				LabelSub = label(image:WhitePlayer handle:Handle height:1 width:1)
		end	

      	LabelScore = label(text:Input.maxDamage borderwidth:5 handle:HandleScore relief:solid bg:Color ipadx:5 ipady:5)
		HandlePath = {DrawPath Grid Color X Y}
		{Grid.grid configure(LabelSub row:X+1 column:Y+1 sticky:wesn)}
		{Grid.score configure(LabelScore row:1 column:Id sticky:wesn)}
		{HandlePath 'raise'()}
		{Handle 'raise'()}
		guiPlayer(id:ID score:HandleScore submarine:Handle mines:nil path:HandlePath|nil)
	end

	fun{MoveSubmarine Position}
		fun{$ Grid State}
			ID HandleScore Handle Mine Path NewPath X Y
		in
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
			pt(x:X y:Y) = Position
			NewPath = {DrawPath Grid ID.color X Y}
			{Grid.grid remove(Handle)}
			{Grid.grid configure(Handle row:X+1 column:Y+1 sticky:wesn)}
			{NewPath 'raise'()}
			{Handle 'raise'()}
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:NewPath|Path)
		end
	end
  
	fun{DrawMine Position}
		fun{$ Grid State}
			ID HandleScore Handle Mine Path LabelMine HandleMine X Y
			in
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
			pt(x:X y:Y) = Position
			LabelMine = label(image:MineIMG handle:HandleMine height:1 width:1)
			{Grid.grid configure(LabelMine row:X+1 column:Y+1)}
			{HandleMine 'raise'()}
			{Handle 'raise'()}
			guiPlayer(id:ID score:HandleScore submarine:Handle mines:mine(HandleMine Position)|Mine path:Path)
		end
	end

	local
		fun{RmMine Grid Position List}
			case List
			of nil then nil
			[] H|T then
				if (H.2 == Position) then
					{RemoveItem Grid H.1}
					T
				else
					H|{RmMine Grid Position T}
				end
			end
		end
	in
		fun{RemoveMine Position}
			fun{$ Grid State}
				ID HandleScore Handle Mine Path NewMine
				in
				guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
				NewMine = {RmMine Grid Position Mine}
				guiPlayer(id:ID score:HandleScore submarine:Handle mines:NewMine path:Path)
			end
		end
	end
	
   fun{DrawPath Grid Color X Y}
      Handle Label
   in
      case Color of 'blue' then
         Label = label(image:BluePt   handle:Handle height:1 width:1) 
      [] 'yellow' then
         Label = label(image:YellowPt handle:Handle height:1 width:1)
      [] 'white'  then
         Label = label(image:WhitePt  handle:Handle height:1 width:1)
      [] 'red'    then
         Label = label(image:RedPt    handle:Handle height:1 width:1)
      [] 'black'  then
         Label = label(image:BlackPt  handle:Handle height:1 width:1)
      [] 'green'  then
         Label = label(image:GreenPt  handle:Handle height:1 width:1)
      end
      {Grid.grid configure(Label row:X+1 column:Y+1 sticky:wesn)}
      Handle
   end
	
	proc{RemoveItem Grid Handle}
		{Grid.grid forget(Handle)}
	end

		
	fun{RemovePath Grid State}
		ID HandleScore Handle Mine Path
	in
		guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
		for H in Path.2 do
	 {RemoveItem Grid H}
		end
		guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path.1|nil)
	end

	fun{UpdateLife Life}
		fun{$ Grid State}
			HandleScore
			in
			guiPlayer(id:_ score:HandleScore submarine:_ mines:_ path:_) = State
			{HandleScore set(Life)}
	 		State
		end
	end


	fun{StateModification Grid WantedID State Fun}
		case State
		of nil then nil
		[] guiPlayer(id:ID score:_ submarine:_ mines:_ path:_)|Next then
			if (ID == WantedID) then
				{Fun Grid State.1}|Next
			else
				State.1|{StateModification Grid WantedID Next Fun}
			end
		end
	end

	fun{RemovePlayer Grid WantedID State}
		case State
		of nil then nil
		[] guiPlayer(id:ID score:HandleScore submarine:Handle mines:M path:P)|Next then
			if (ID == WantedID) then
			{HandleScore set(0)}
				for H in P do
			 		{RemoveItem Grid H}
				end
				for H in M do
			 		{RemoveItem Grid H.1}
				end
				{RemoveItem Grid Handle}
				Next
			else
				State.1|{RemovePlayer Grid WantedID Next}
			end
		end
	end

   proc{Explosion ID Position Grid}
         local X Y HandleBomb1 HandleBomb2 HandleBomb3 HandleBomb4 HandleBomb5 HandleBomb6 HandleBomb7 HandleBomb8 HandleBomb9 HandleBomb10 HandleBomb11 HandleBomb12 LabelBomb1 LabelBomb2 LabelBomb3 LabelBomb4 LabelBomb5 LabelBomb6 LabelBomb7 LabelBomb8 LabelBomb9 LabelBomb10 LabelBomb11 LabelBomb12 in
            pt(x:X y:Y) = Position
            LabelBomb1 = label(image:Bomb1 handle:HandleBomb1 height:1 width:1)
            {Grid.grid configure(LabelBomb1 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb1 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb1)}

            LabelBomb2 = label(image:Bomb2 handle:HandleBomb2 height:1 width:1)
            {Grid.grid configure(LabelBomb2 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb2 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb2)}

            LabelBomb3 = label(image:Bomb3 handle:HandleBomb3 height:1 width:1)
            {Grid.grid configure(LabelBomb3 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb3 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb3)}

            LabelBomb4 = label(image:Bomb4 handle:HandleBomb4 height:1 width:1)
            {Grid.grid configure(LabelBomb4 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb4 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb4)}

            LabelBomb5 = label(image:Bomb5 handle:HandleBomb5 height:1 width:1)
            {Grid.grid configure(LabelBomb5 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb5 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb5)}

            LabelBomb6 = label(image:Bomb6 handle:HandleBomb6 height:1 width:1)
            {Grid.grid configure(LabelBomb6 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb6 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb6)}

            LabelBomb7 = label(image:Bomb7 handle:HandleBomb7 height:1 width:1)
            {Grid.grid configure(LabelBomb7 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb7 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb7)}

            LabelBomb8 = label(image:Bomb8 handle:HandleBomb8 height:1 width:1)
            {Grid.grid configure(LabelBomb8 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb8 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb8)}

            LabelBomb9 = label(image:Bomb9 handle:HandleBomb9 height:1 width:1)
            {Grid.grid configure(LabelBomb9 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb9 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb9)}

            LabelBomb10 = label(image:Bomb10 handle:HandleBomb10 height:1 width:1)
            {Grid.grid configure(LabelBomb10 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb10 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb10)}

            LabelBomb11 = label(image:Bomb11 handle:HandleBomb11 height:1 width:1)
            {Grid.grid configure(LabelBomb11 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb11 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb11)}

            LabelBomb12 = label(image:Bomb12 handle:HandleBomb12 height:1 width:1)
            {Grid.grid configure(LabelBomb12 row:X+1 column:Y+1 sticky:wesn)}
            {HandleBomb12 'raise'()}
            {Delay 70}
            {Grid.grid forget(HandleBomb12)}
         end
   end

	local
		proc{LineDroned Drone Grid N}
			HandleDrone LabelDrone
			in
			LabelDrone = label(image:DroneIMG handle:HandleDrone)
			case Drone
			of drone(row X) then
				if N < Input.nColumn then
					{Grid.grid configure(LabelDrone row:X+1 column:N+1)}
					{HandleDrone 'raise'()}
					{Delay 250}
					{Grid.grid forget(HandleDrone)}
					{LineDroned Drone Grid N+1}
				end
			[] drone(column Y) then
				if N < Input.nRow then
					{Grid.grid configure(LabelDrone row:N+1 column:Y+1)}
					{HandleDrone 'raise'()}
					{Delay 250}
					{Grid.grid forget(HandleDrone)}
					{LineDroned Drone Grid N+1}
				end
			else
				skip
			end
		end
	in
		proc{Droned Drone Grid}
			{LineDroned Drone Grid 1}
		end
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	fun{StartWindow}
		Stream
		Port
	in
		{NewPort Stream Port}
		thread
			{TreatStream Stream nil nil}
		end
		Port
	end

	proc{TreatStream Stream Grid State}
		case Stream
		of nil then skip
		[] buildWindow|T then NewGrid in 
			NewGrid = {BuildWindow}
			{TreatStream T NewGrid State}
		[] initPlayer(ID Position)|T then NewState in
			NewState = {DrawSubmarine Grid ID Position}
			{TreatStream T Grid NewState|State}
		[] movePlayer(ID Position)|T then
			{TreatStream T Grid {StateModification Grid ID State {MoveSubmarine Position}}}
		[] lifeUpdate(ID Life)|T then
			{TreatStream T Grid {StateModification Grid ID State {UpdateLife Life}}}
			{TreatStream T Grid State}
		[] putMine(ID Position)|T then 
			{TreatStream T Grid {StateModification Grid ID State {DrawMine Position}}}
		[] removeMine(ID Position)|T then
			{TreatStream T Grid {StateModification Grid ID State {RemoveMine Position}}}
		[] surface(ID)|T then
			{TreatStream T Grid {StateModification Grid ID State RemovePath}}
		[] removePlayer(ID)|T then
			{TreatStream T Grid {RemovePlayer Grid ID State}}
		[] explosion(ID Position)|T then
			{Explosion ID Position Grid}
			{TreatStream T Grid State}
		[] drone(ID Drone)|T then
			{Droned Drone Grid}
			{TreatStream T Grid State}
		[] sonar(ID)|T then
			{TreatStream T Grid State}
		[] _|T then
			{TreatStream T Grid State}
		end
	end
end
