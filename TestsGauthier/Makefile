files = ../Input.oz ../PlayerManager.oz ../Player.oz ../GUI.oz ../Main.oz FichierTestPlayer.oz

build : $(files)
	/Applications/Mozart2.app/Contents/Resources/bin/ozc -c ../Input.oz ../PlayerManager.oz ../Player.oz ../GUI.oz ../Main.oz

run : Main.ozf
	build
	/Applications/Mozart2.app/Contents/Resources/bin/ozengine Main.ozf

clean : $(files)
	rm *.ozf

player : $(files)
	/Applications/Mozart2.app/Contents/Resources/bin/ozc -c ../Input.oz ../Player.oz FichierTestPlayer.oz
	/Applications/Mozart2.app/Contents/Resources/bin/ozengine FichierTestPlayer.ozf

ftestplayer : $(files)
	/Applications/Mozart2.app/Contents/Resources/bin/ozc -c FichierTestPlayer.oz
	/Applications/Mozart2.app/Contents/Resources/bin/ozengine FichierTestPlayer.ozf

	
