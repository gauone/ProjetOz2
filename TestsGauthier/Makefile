files = ../Input.oz ../PlayerManager.oz ../Player.oz ../GUI.oz ../Main.oz FichierTestPlayer.oz

all : $(files)
	/Applications/Mozart2.app/Contents/Resources/bin/ozc -c ../Input.oz ../PlayerManager.oz ../Player.oz ../PlayerRandom.oz ../GUI.oz ../Main.oz
	say "Tout les fichier sont compilé"

run : $(files) all
	say "Fichiers compilés. Lancement de la partie."
	/Applications/Mozart2.app/Contents/Resources/bin/ozengine Main.ozf

clean : $(files)
	rm *.ozf

testplayer : $(files)
	/Applications/Mozart2.app/Contents/Resources/bin/ozc -c ../Input.oz ../Player.oz ../PlayerRandom.oz FichierTestPlayer.oz
	say "Fichiers Input.oz Player.oz compilé"
	/Applications/Mozart2.app/Contents/Resources/bin/ozengine FichierTestPlayer.ozf

redotest : $(files)
	/Applications/Mozart2.app/Contents/Resources/bin/ozc -c FichierTestPlayer.oz
	say "Fichier FichierTestPlayer compilé"
	/Applications/Mozart2.app/Contents/Resources/bin/ozengine FichierTestPlayer.ozf

playeronly: $(files)
	/Applications/Mozart2.app/Contents/Resources/bin/ozc -c ../Player.oz ../PlayerRandom.oz
	say "player compilé"

main : $(files)
	/Applications/Mozart2.app/Contents/Resources/bin/ozc -c ../Main.oz
	say "Fichier principal compilé"
	/Applications/Mozart2.app/Contents/Resources/bin/ozengine Main.ozf

relaunch :
	/Applications/Mozart2.app/Contents/Resources/bin/ozengine Main.ozf

changeInput:
	/Applications/Mozart2.app/Contents/Resources/bin/ozc -c ../Input.oz ../PlayerManager.oz
	say "Input et PlayerManager compilé"

help :
	echo "\n\nall: tout compiler \n\nrun: tout compiler et lancer la main \n\nmain: compiler la main et la lancer \n\nrelaunch: relancer la main \n\ntestplayer: compiler tout les fichiers nécessaires à lancer mes tests sur player et lancer les tests \n\nredotest: compiler et lancer le fichier de test de player \n\nplayeronly: compile player \n\nclean: bouger tout les .ozf\n"
	