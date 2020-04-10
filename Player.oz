functor
import
    Input
    System %ajout de moi
    OS %ajout de moi
export
    portPlayer:StartPlayer
define
    InitPosition
    DetectIn
    GeneratePosition
    FindOtherPos
    Move
    PossiblesDir
    ChargeItem
    ManhattanDist
    FireItem
    WhereToFire
    WeaponAvailable
    FireMine
    SayMove
    SayMineOrMissileExplode
    SayPassingDrone
    SayPassingSonar
    SayDeath
    TreatStream
    StartPlayer
in
    /**************************************
    * Fonctions et Procedures Utiles
    *************************************/

    /*Retourne le nouveau record apres avoir bind ID et Pos a leur valeurs.
    * Pos est une position ou il y a de l eau!*/
    fun {InitPosition ID Pos Charact}
        if Charact.damage >= Input.maxDamage then ID = null
        else
            ID = Charact.identite
            Pos={GeneratePosition}
            {Record.adjoinAt Charact position Pos}%retourne le nouveau record
        end
    end


    % Retourne true si le point (X Y) est une ile. Si outOfBounds alors vrai aussi.
    fun {DetectIn Matrice NRow NColumn X Y}
        if X > NRow orelse Y > NColumn orelse X =< 0 orelse Y =< 0 then true
        else
            %note, dans {List.nth liste I} index commence a 1 et pas a 0
            {List.nth {List.nth Matrice X } Y} > 0
        end
    end


    %donne une position au hasard n etant pas une ile ou outOfBound
    fun {GeneratePosition}
        local
            Absi Ord
        in
            Absi = ({OS.rand} mod Input.nRow) + 1
            Ord = ({OS.rand} mod Input.nColumn) + 1
            if {DetectIn Input.map Input.nRow Input.nColumn Absi Ord} then {FindOtherPos Absi Ord}
            else pt(x:Absi y:Ord)
            end
        end
    end


    % Si par malchance le {OS.rand} a donne une ile on avance dans la matrice jusqu a trouver de l eau
    fun {FindOtherPos X Y}
        local
            Absi Ord
        in
            Ord = (Y mod Input.nColumn) + 1
            if Ord == 1 then Absi = (X mod Input.nRow) + 1 %on passe a la ligne suivante ou on remonte en haut
            else Absi = X
            end

            if {DetectIn Input.map Input.nRow Input.nColumn Absi Ord} then {FindOtherPos Absi Ord}
            else pt(x:Absi y:Ord)
            end
        end
    end


    % Fonction qui choisit la direction a prendre, ajoute la derniere position a passage et rend une nouvelle position
    % Random dans un premier temps ;p /!\j'ajoute a passage la position precedente seulement
    fun {Move ID Position Direction Charact}
        if Charact.damage >= Input.maxDamage then ID = null
        else
            if Charact.divePermission then
                ID = Charact.identite
                local
                    Absi = Charact.position.x
                    Ord = Charact.position.y
                    Possibles = {PossiblesDir Absi Ord Charact.passage}%une liste contenant les directions
                    DirChoisie %celle du type direction#DeltaX#DeltaY
                    DivePermission
                in
                    if Possibles == nil
                        then Direction = surface
                            Position = pt(x:Absi y:Ord)
                            DivePermission = false %Tu montes a la surface tu perds ta permission de plonger
                    else
                        DirChoisie = {List.nth Possibles ( ({OS.rand} mod {List.length Possibles}) + 1 ) }%/!\ mod 0 donne une erreur

                        Direction = DirChoisie.1
                        Position = pt(x:(Absi+DirChoisie.2) y:(Ord+DirChoisie.3)) %Rappel DirChoisie du type direction#DeltaX#DeltaY
                        DivePermission = Charact.divePermission
                    end
                    {AdjoinList Charact [position#Position passage#((Absi#Ord)|Charact.passage) divePermission#DivePermission]}
                end
            else
                raise iDonTHaveThePermissionToDiveAndYouAskMeToMove end
            end
        end
    end


    % Retourne les directions autres que la surface possibles pour la position donnee par (X Y)
    % La valeur retournee est une liste du style [direction#DeltaX#DeltaY direction#DeltaX#DeltaY ...]
    % Mes criteres sont: pas passe par la depuis la derniere surface et pas une ile
    %/!\ passage est suppose etre une liste du style [X1#Y1 X2#Y2 ...]
    fun {PossiblesDir X Y Passage}
        local
            Mouvements = [north#~1#0 south#1#0 east#0#1 west#0#~1]
            fun {Loop Mvt Acc}
                case Mvt
                of H|T then
                    case H
                    of A#Xmvt#Ymvt then
                        if {DetectIn Input.map Input.nRow Input.nColumn (X + Xmvt) (Y + Ymvt)} orelse {List.member (X + Xmvt)#(Y + Ymvt) Passage}
                            then {Loop T Acc}
                        else {Loop T H|Acc}
                        end
                    end
                else Acc
                end
            end
        in
            {Loop Mouvements nil}
        end
    end


    %pour le moment je choisi au hasard quelle arme recharger
    %cette fonction choisi l arme et si elle est suffisement load que
    %pour creer une nouvelle alors elle bind KindItem a la nouvelle arme sinon elle bind a null
    fun {ChargeItem ID KindItem Charact}
        if Charact.damage >= Input.maxDamage then ID = null
        else
            local
                Weapons = [mine missile drone sonar]
                Chosen
            in
                Chosen = {List.nth Weapons ( ({OS.rand} mod {List.length Weapons}) + 1 ) }
                %quand tu modifieras pour que ce ne soit plus au hasard, tu devra juste changer le chosen avant cette ligne,
                %le reste de ce qui est demande est fait ici en dessous
                ID = Charact.identite
                if 0 == ((Charact.Chosen+1) mod Input.Chosen) then KindItem = Chosen %on ne bind que si on a atteint le load de l arme
                else KindItem = null
                end
                {Record.adjoinAt Charact Chosen (Charact.Chosen + 1)}%j augmente de 1 le load dans les caracteristiques
            end
        end
    end


    % Retourne la distance de Manhattan entre moi et le pt (X Y)
    fun {ManhattanDist Charact X Y}
        {Number.abs X-Charact.position.x} + {Number.abs Y-Charact.position.y}
    end


    % Choisi ou pas de tirer si on tire on bind KindFire a ce qu on utilise et comment(direction cible ...)
    % Si on ne tire pas alors KindFire est bind a null (KindFire de type FireItem)
    fun {FireItem ID KindFire Charact}
        if Charact.damage >= Input.maxDamage then ID = null
        else
            ID = Charact.identite
            local

                fun {ChoseItemAndCheckUtility Utilisable}
                    if Utilisable == nil then KindFire = null Charact %Pour le moment on tire des qu on sait. Si on est pas sur de la position on pourait eviter ca a l avenir
                    else
                        local
                            TupleItem
                            Item
                            FirePosition
                            RemainingAfterward
                            SubtractedList
                        in
                            %ici il faut changer pour que ce soit plus random ;p une maniere est de choisir l'item qui sait atteindre l ennemi avec sa portee propre
                            TupleItem = {List.nth Utilisable ( ({OS.rand} mod {List.length Utilisable}) + 1 ) } % du type mine#quantiteDeMine
                            Item = TupleItem.1 %/!\ du type mine
                            FirePosition = {WhereToFire Item Charact}% Soit une position soit null car il n y a pas de position ou on ne se blesserait pas

                            if FirePosition == null then {ChoseItemAndCheckUtility {List.subtract Utilisable TupleItem}} %je supprime cet item de la liste des dispo et je recommence la selection d item
                            else
                                case Item
                                of mine then KindFire = mine(FirePosition) %choisi une position de mine random
                                    RemainingAfterward = {Value.max (Charact.mine - Input.mine) 0}
                                [] missile then KindFire = missile(FirePosition) %choisi une position de mine random potentielement sur toi meme ;p
                                    RemainingAfterward = {Value.max (Charact.missile - Input.missile) 0}
                                [] sonar then KindFire = sonar
                                    RemainingAfterward = {Value.max (Charact.sonar - Input.sonar) 0}
                                [] drone then KindFire = drone(row  (({OS.rand} mod Input.nRow) + 1) ) %ATTENTION TYPE PEUT-ETRE MAUVAIS!
                                    RemainingAfterward = {Value.max (Charact.drone - Input.drone) 0}
                                end
                                {Record.adjoinAt Charact Item RemainingAfterward}
                            end
                        end
                    end
                end
            in
                {ChoseItemAndCheckUtility {WeaponAvailable Charact} } % {WeaponAvailable Charact} = liste du style [mine#quantiteDeMine missile#quantiteDeMissile ...] J ai garde ce type car ca peut etre utile quand on fera la version efficace
            end
        end
    end

    % Choisi pour le moment une position random qui respecte la ManhattanDist et essaye d'eviter de
    %   mettre ou on a deja mis des mines et evite de se donner des dommages a soit meme si c est un missile
    fun {WhereToFire Item Charact}
        local

            fun {GenerateFirePosition MaxDist MinDist IsMissile}
                local
                    Absi
                    Ord

                    % Si par malchance le {OS.rand} ci dessous a donne une ile ou un mine (ou trop pres de nous) cette fct avance dans la matrice jusqu a trouver de l eau.
                    % Si on trouve aucune position alors on retourne null
                    fun {FindOtherFirePos X Y}
                        local
                            NewX NewY
                        in
                            % On avance de 1 position en y. Si on a fait la ligne, on passe a la ligne suivante.
                            NewY = (Y mod {Value.min (Input.nColumn - {Value.max (Charact.position.y - MaxDist - 1) 0}) ((2*MaxDist)+1) }) + {Value.max (Charact.position.y - MaxDist) 1}
                            if NewY == {Value.max (Charact.position.y - MaxDist) 1} then NewX = (X mod {Value.min (Input.nRow - {Value.max (Charact.position.x - MaxDist - 1) 0}) ((2*MaxDist)+1) }) + {Value.max (Charact.position.x - MaxDist) 1} %on passe a la ligne suivante ou on remonte en haut du carre
                            else NewX = X
                            end

                            if NewX \= Absi orelse NewY \= Ord then
                                % On regarde si ce nouveau pt est valide (meme bout de code que dans GenerateFirePosition sauf qu'on retient le Absi Ord qu on a recu de GenerateFirePosition)
                                if IsMissile andthen ( {ManhattanDist Charact NewX NewY} < {Value.min 2 MinDist} orelse {DetectIn Input.map Input.nRow Input.nColumn NewX NewY} orelse {ManhattanDist Charact NewX NewY} > MaxDist )
                                    then {FindOtherFirePos NewX NewY} % missile: j ai pas envie de m envoyer un missile dessus ou sur une ile ou trop loin
                                elseif {Not IsMissile} andthen ( {DetectIn Input.map Input.nRow Input.nColumn NewX NewY} orelse {DetectIn Charact.posToAvoid Input.nRow Input.nColumn NewX NewY} orelse {ManhattanDist Charact NewX NewY} < MinDist orelse {ManhattanDist Charact NewX NewY} > MaxDist )
                                    then {FindOtherFirePos NewX NewY} %Mine: j ai pas envie de mettre une mine sur les iles ou sur les mines et je doit respecter les 2 bornes en len de Manhattan
                                else pt(x:NewX y:NewY)
                                end
                            else null %on a deja tout essaye dans ce cas
                            end
                        end
                    end
                in
                    % Choix random dans une boite de la taille de MaxDist autour de moi /!\ les coins sont trop loins en dist de Manhattan!
                    Absi = ({OS.rand} mod {Value.min (Input.nRow - {Value.max (Charact.position.x - MaxDist - 1) 0}) ((2*MaxDist)+1) }) + {Value.max (Charact.position.x - MaxDist) 1}
                    Ord =  ({OS.rand} mod {Value.min (Input.nColumn - {Value.max (Charact.position.y - MaxDist - 1) 0}) ((2*MaxDist)+1) }) + {Value.max (Charact.position.y - MaxDist) 1}

                    if IsMissile andthen ( {ManhattanDist Charact Absi Ord} < {Value.min 2 MinDist} orelse {DetectIn Input.map Input.nRow Input.nColumn Absi Ord} orelse {ManhattanDist Charact Absi Ord} > MaxDist )
                        then {FindOtherFirePos Absi Ord} % missile: j ai pas envie de m envoyer un missile dessus ou sur une ile ou trop loin
                    elseif {Not IsMissile} andthen ( {DetectIn Input.map Input.nRow Input.nColumn Absi Ord} orelse {DetectIn Charact.posToAvoid Input.nRow Input.nColumn Absi Ord} orelse {ManhattanDist Charact Absi Ord} < MinDist orelse {ManhattanDist Charact Absi Ord} > MaxDist )
                        then {FindOtherFirePos Absi Ord} %Mine: j ai pas envie de mettre une mine sur les iles ou sur les mines et je doit respecter les 2 bornes en len de Manhattan
                    else pt(x:Absi y:Ord)
                    end
                end
            end

        in
            case Item
            of missile then {GenerateFirePosition Input.maxDistanceMissile Input.minDistanceMissile true}
            [] mine then {GenerateFirePosition Input.maxDistanceMine Input.minDistanceMine false}
            else raise notMineOrMissile(Item) end
            end
        end
    end


    % Retourne un liste avec les armes entierement loadees. La liste est du type
    % [mine#quantiteDeMine missile#quantiteDeMissile]. Si il n'y a rien de dispo alors c'est nil
    fun {WeaponAvailable Charact}
        local
            Ammunition = [mine#Charact.mine missile#Charact.missile drone#Charact.drone sonar#Charact.sonar]
            fun {Loop Munition Acc}
                case Munition
                of H|T then
                    case H
                    of Type#YourAmount then
                        if YourAmount < Input.Type then {Loop T Acc}%t as pas assez de load je l ajoute pas
                        else {Loop T H|Acc}
                        end
                    end
                else Acc
                end
            end
        in
            {Loop Ammunition nil}
        end
    end


    %enonce If a mine was already placed before, the player may decide to make one exploded
    fun {FireMine ID Mine Charact}
        if Charact.damage >= Input.maxDamage then ID = null
        else
            local
                Choice % faire exploser ou pas
            in
                ID = Charact.identite
                Choice = true%a modifier si on ameliore

                if Choice then Mine = {GeneratePosition}%a modifier si on ameliore la on se tire peut etre dessus
                else Mine = null
                end
            end
            Charact
        end
    end


    % Je vais faire en sorte qu on retienne la position de nos adversaires
    %fct appellee que si je fais le AI
    fun {SayMove ID Direction Charact}
        if ID == Charact.identite then {System.show sayMoveDeMoiMeme(Direction)} Charact
        else
            local
                Connu = {Arity Charact.posEnnemi}
                IdNum = ID.id
                Mouvements = [north#~1#0 south#1#0 east#0#1 west#0#~1]
                DeltaX
                DeltaY
            in
                if {List.member IdNum Connu} then
                    for Mvt in Mouvements do
                        case Mvt
                        of Direction#I#J then DeltaX=I DeltaY=J
                        else skip
                        end
                    end
                    {Record.adjoinAt Charact posEnnemi {Record.adjoinAt Charact.posEnnemi IdNum (Charact.posEnnemi.1+DeltaX)#(Charact.posEnnemi.2+DeltaY)}}
                else Charact %je connais pas sa position... Dans le meilleur des cas je peux reduire le champ de recherche. Pour le moment je fais rien
                end
            end
        end
    end


    % Retourne un nouveau Charact et bind Message dist>=2 ->0 damage Dist=1->1 Dist=0->2
    % Il faudra prendre en compte IsMissile quand la fonction sera maligne
    fun {SayMineOrMissileExplode Position Message Charact IsMissile}
        case Position
        of pt(x:X y:Y) then
            ManDist = {ManhattanDist Charact X Y}
            in
            if ManDist >= 2 then Message = null Charact
            else % 2 - ManDist est la formule du damage que je recois (si elle est < que 2 seulement)
                if (2 - ManDist + Charact.damage) >= Input.maxDamage then Message = sayDeath(Charact.identite)
                else Message = sayDamageTaken(Charact.identite (2 - ManDist) (Input.maxDamage - 2 + ManDist - Charact.damage) )
                end
                {Record.adjoinAt Charact damage (Charact.damage + 2 - ManDist)}
            end
        else raise positionMisunderstoodInSayMineOrMissileExplode end
        end
    end


    proc {SayPassingDrone Drone ID Answer Charact}
        if Charact.damage >= Input.maxDamage then ID = null
        else
            ID = Charact.identite
            case Drone
            of drone(Dim Num) then
                if Dim == row then Answer = (Charact.position.x == Num)
                else Answer = (Charact.position.y == Num)
                end
            else raise droneMisunderstoodInSayPassingDrone end
            end
        end
    end

    %comme trick, je vais toujours envoyer les lignes si il y en a moins que de colonne si c'est l inverse :) (et je vais eviter de dire une ile)
    proc {SayPassingSonar ID Answer Charact}
        if Charact.damage >= Input.maxDamage then ID = null
        else
            ID = Charact.identite
            local
                Mensonge = {FindOtherPos (Input.nRow div 2)+1 (Input.nColumn div 2)+1}
            in
                if Input.nColumn > Input.nRow then Answer = pt(x:Charact.position.x y:Mensonge.y)
                else Answer = pt(x:Mensonge.x y:Charact.position.y)
                end
            end
        end
    end


    % Efface le joueur de la mémoire de l AI
    fun {SayDeath ID Charact}
        if ID == Charact.identite then {System.show jeRecoisLInfoQueJeSuisMort(ID)} Charact
        else
            local
                Connu = {List.append {Arity Charact.posEnnemi} {Arity Charact.lifeEnnemi}}
                IdNum = ID.id
                AIIntermediatRecord
            in
                if {List.member IdNum Connu} then
                    AIIntermediatRecord = {Record.adjoinAt Charact posEnnemi {Record.subtract Charact.posEnnemi IdNum}}%je retire le joueur de mes positions d ennemi
                    {Record.adjoinAt AIIntermediatRecord lifeEnnemi {Record.subtract AIIntermediatRecord.lifeEnnemi IdNum}}% a ce nouveau record je fais la meme mais dans mes niveaux de vie
                else
                    Charact
                end
            end
        end
    end

    /***********************************************
    Lancement et traitement de la stream du player
    ***********************************************/


    /*dans cette fonction on est autorise a ajouter des parametres ;)
    /!\ faut les rajouter dans la ligne en dessous de NewPort plus bas!*/
    proc{TreatStream Stream Charact} %ajoutés par moi: Charact->les caracteristiques a chaque etat
        case Stream
        of H|T then
            case H
            of initPosition(ID Position) then {TreatStream T {InitPosition ID Position Charact}}
            [] move(ID Position Direction) then {TreatStream T {Move ID Position Direction Charact}}
            [] dive then {TreatStream T {Record.adjoinAt Charact divePermission true}}%autorise a nouveau a plonger
            [] chargeItem(ID KindItem) then {TreatStream T {ChargeItem ID KindItem Charact}}
            [] fireItem(ID KindFire) then {TreatStream T {FireItem ID KindFire Charact}}
            [] fireMine(ID Mine) then {TreatStream T {FireMine ID Mine Charact}}
            [] isDead(Answer) then Answer = (Charact.damage >= Input.maxDamage) {TreatStream T Charact}
            % version Dummy:
            [] sayMove(ID Direction) then {TreatStream T Charact}
            [] saySurface(ID) then {TreatStream T Charact}
            [] sayCharge(ID KindItem) then {TreatStream T Charact}
            [] sayMinePlaced(ID) then {TreatStream T Charact}
            [] sayMissileExplode(ID Position Message) then {TreatStream T {SayMineOrMissileExplode Position Message Charact true}}
            [] sayMineExplode(ID Position Message) then {TreatStream T {SayMineOrMissileExplode Position Message Charact false}}
            [] sayAnswerDrone(Drone ID Answer) then {TreatStream T Charact} %normalement il faut faire qqchose, mais la j ignore mon drone
            [] sayAnswerSonar(ID Answer) then {TreatStream T Charact} %idem que ligne precedente
            [] sayDeath(ID) then {TreatStream T Charact}
            [] sayDamagetaken(ID Damage LifeLeft) then {TreatStream T Charact}%il faut juste que je le ajoute dans la memoire de l AI
            /*% version AI: note:il faut changer --move chargeItem fireItem fireMine-- en + des fct non-dummy pour avoir un AI malin
            [] sayMove(ID Direction) then {TreatStream T {SayMove ID Direction Charact}}
            [] sayDeath(ID) then {TreatStream T {SayDeath ID Charact}}
            */
            [] sayPassingDrone(Drone ID Answer)then {SayPassingDrone Drone ID Answer Charact} {TreatStream T Charact}
            [] sayPassingSonar(ID Answer) then {SayPassingSonar ID Answer Charact} {TreatStream T Charact}
            end
        [] nil then {System.show 'Player s Stream ended -> see Player file'}
        else raise iLegalOptionExceptionInPaylerStream(Stream.1) end
        end
    end


    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream characteristic(identite:id(id:ID color:Color name:'Antoine') position:pt(x:~1 y:~1) passage:nil divePermission:true mine:0 missile:0 drone:0 sonar:0 damage:0 posEnnemi:pos() lifeEnnemi:life() posToAvoid:Input.map )}
            % Contenu type de characteristic(position:pt(x:2 y:3) passage:2#3|2#4|1#4|nil identite:id(color:blue id:1 name:'Antoine') divePermission:true mine:0 missile:0 drone:0 sonar:0 damage:0 posEnnemi:pos(2:3#4 3:1#1) lifeEnnemi:life(1:4 2:1) posToAvoid:Carte_Des_Mines)
        end
        Port
    end

end

%TODO:
/*
Vérifier que le nom ne doit rien a voir avec le reste :p
Changer la fonction Move qui est random pour le moment
Changer FireItem car il y a des distance de Manhattan min et max pour mettre de mines ou missile en fait
Tester les fcts say et ManhattanDist
Vérifier de source autre qu un etudiant inconnu que type drone est bien drone(row <unXChoisi>)
*/
