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
    GetMostAccurate
    MergeAllEnemyMat
    FusionList
    FusionMap
    ChargeItem
    ManhattanDist
    ManhattanDistList
    GetAllElemAtManhattanDistBetween
    FireItem
    WhereToFire
    WhereToDrone
    WeaponAvailable
    ChangeInMap
    ChangeListinMap
    FireMine
    SayMove
    RemoveIslandFromList
    RemoveIslandFromMap
    DropLast
    MoveMapRight
    MoveMapLeft
    MoveMapDown
    MoveMapUp
    GetAllAtExactDist
    GetAllAtExactDistListe
    SayMineOrMissileExplode
    SayPassingDrone
    SayPassingSonar
    SayDeath
    FillList
    BFS
    NewQueue
    Enqueue
    Dequeue
    IsEmpty
    SayDamageTaken
    TreatStream
    StartPlayer
in
    /**************************************
    * Fonctions et Procedures Utiles
    *************************************/

    /*Retourne le nouveau record apres avoir bind ID et Pos a leur valeurs.
    * Pos est une position ou il y a de l eau!*/
    fun {InitPosition ID Pos Charact}
        if Charact.damage >= Input.maxDamage then ID = null Charact
        else
            ID = Charact.identite
            Pos={GeneratePosition}
            {Record.adjoinAt Charact position Pos}%retourne le nouveau record
        end
    end


    % Retourne true si le point (X Y) est > 0. Si outOfBounds alors vrai aussi.
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
        if Charact.damage >= Input.maxDamage then ID = null Charact
        else
            if Charact.divePermission then
                ID = Charact.identite
                local
                    Absi = Charact.position.x
                    Ord = Charact.position.y
                    Possibles = {PossiblesDir Absi Ord Charact.passage}%une liste contenant les directions
                    DirChoisie %celle du type direction#DeltaX#DeltaY
                    DivePermission

                    Mouvements = [north#~1#0 south#1#0 east#0#1 west#0#~1]

                    fun {FindDirFromPos Position Charact Liste}
                        case Liste
                        of Mvt|T then
                            if (Position.x - Charact.position.x) == Mvt.2 andthen (Position.y - Charact.position.y) == Mvt.3 then Mvt.1
                            else {FindDirFromPos Position Charact T}
                            end
                        [] nil then raise canTFindDirFromPos end
                        end 
                    end
                in
                    if Possibles == nil then
                        Direction = surface
                        Position = pt(x:Absi y:Ord)
                        %Tu montes a la surface tu perds ta permission de plonger et tu dois oublier ou je suis passe car je fais surface
                        {AdjoinList Charact [position#Position passage#nil divePermission#false lastMissileLaunched#false lastMineExplode#false] }
                    else
                        local
                            BFSPath
                            AccurateIdNum
                            Accurate = {GetMostAccurate Charact AccurateIdNum} %une liste ou nil /!\ si posEnnemi est vide alors AccurateIdNum reste unbound.
                            
                        in
                            if Charact.mine >= (Input.mine-1) then BFSPath = {BFS Charact.position.x Charact.position.y {GetAllAtExactDistListe Accurate Input.minDistanceMine Input.nRow Input.nColumn [Charact.position]} Charact}%/!\BFS retourne une liste de pos de type X#Y
                            elseif Charact.missile >= (Input.missile-1) then BFSPath = {BFS Charact.position.x Charact.position.y {GetAllAtExactDistListe Accurate Input.minDistanceMissile Input.nRow Input.nColumn [Charact.position]} Charact}%/!\BFS retourne une liste de pos de type X#Y
                            else BFSPath = {BFS Charact.position.x Charact.position.y {GetAllAtExactDistListe Accurate {Value.max Input.maxDistanceMine+1 Input.maxDistanceMissile+1} Input.nRow Input.nColumn [Charact.position]} Charact}%/!\BFS retourne une liste de pos de type X#Y
                            end

                            if BFSPath==null then
                                DirChoisie = {List.nth Possibles ( ({OS.rand} mod {List.length Possibles}) + 1 ) } %/!\ mod 0 donne une erreur
                                Direction = DirChoisie.1 %Rappel DirChoisie du type direction#DeltaX#DeltaY
                                Position = pt(x:(Absi+DirChoisie.2) y:(Ord+DirChoisie.3))
                                {AdjoinList Charact [position#Position passage#((Absi#Ord)|Charact.passage) mostAccurate#Accurate accurateIdNum#AccurateIdNum lastMissileLaunched#false lastMineExplode#false]}
                            else
                                Position = pt(x:((BFSPath.2.1).1) y:((BFSPath.2.1).2))%2 eme element de BFSPath car normalement le BFS est soit null soit une liste de 2 minimum puisque la liste commence par la position de depart.
                                Direction = {FindDirFromPos Position Charact Mouvements}
                                {AdjoinList Charact [position#Position passage#((Absi#Ord)|Charact.passage) mostAccurate#Accurate accurateIdNum#AccurateIdNum lastMissileLaunched#false lastMineExplode#false]}
                            end
                        end
                    end
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

    /* 
     * Retourne la liste contenant les positions (X#Y) supposees de l ennemi ou on a le moins de possiblites de positions. IdNumUnbound est une varable unbound que l on bind a l IdNum correspondant a la liste.
     * /!\ Si on n a aucune posEnnemi dans Charact est vide alors IdNumUnbound reste unbound!
     */
    fun {GetMostAccurate Charact IdNumUnbound}
        local
            % renvoie une liste contenant tout les index ou l elem est > 0 dans la matrice Mat /!\ doit etre lance avec ces param: {Loop Mat 1 1}
            fun {Loop Mat X Y}
                case Mat
                of Liste1|Liste2 then
                    case Liste1
                    of H|T then
                        if H >= 1 then X#Y|{Loop T|Liste2 X Y+1}
                        else {Loop T|Liste2 X Y+1}
                        end
                    [] nil then
                        if X < Input.nRow then {Loop Liste2 X+1 1}
                        else nil
                        end
                    else raise getMostAccuratexception end
                    end
                else  raise secondGetMostAccuratexception end
                end
            end
            
            % fonction qui permet juste d avancer dans les IdNums pour y appliquer Loop puis garder la liste la plus courte et la retourner dans le tuple Len#Liste
            fun {GetNarrowest IdNumList ActualMinList ActualMinLen ActualMinIdNum}
                local
                    PosList
                    NewLen
                in
                    case IdNumList
                    of IdNum|T then
                        PosList = {Loop (Charact.posEnnemi).IdNum 1 1}
                        NewLen = {List.length PosList}
                        if NewLen < ActualMinLen then {GetNarrowest T PosList NewLen IdNum}
                        else {GetNarrowest T ActualMinList ActualMinLen ActualMinIdNum}
                        end
                    [] nil then
                        IdNumUnbound = ActualMinIdNum
                        ActualMinList
                    else raise getNarrowestException end
                    end
                end
            end

            IdNumList = {Record.arity Charact.posEnnemi}
        in
            if IdNumList == nil then nil
            else
                {GetNarrowest IdNumList nil Input.nRow*Input.nColumn IdNumList.1}
            end
        end
    end


    
    fun {MergeAllEnemyMat Charact}
        local
            IdNum = {Record.arity Charact.posEnnemi}
            fun {Loop IdNum Map}
                case IdNum
                of H|T then {Loop T {FusionMap Map (Charact.posEnnemi).H}}
                [] nil then Map
                else raise errorInMergeAllEnemyMatLoop end
                end
            end
        in
            case IdNum
            of H|nil then (Charact.posEnnemi).H
            [] nil then nil
            [] H|T then {Loop T (Charact.posEnnemi).H}
            else raise errorInMergeAllEnemyMat end
            end
        end
    end

    % Fusionne 2 liste. C-a-d qu on renvoie une liste qui contient le max entre les 2 index /!\ Les liste doivent avoir la même longeur
    fun {FusionList List1 List2}
        case List1#List2
        of (H1|T1)#(H2|T2) then
            {Value.max H1 H2}|{FusionList T1 T2}
        [] nil#nil then nil
        else
            raise listDeLenDifferentes(List1#List2) end
        end
    end

    /*
     * Renvoie une matrice qui contient le max entre les elements des 2 matrices au meme index
     */
    fun {FusionMap Map1 Map2}
        case Map1#Map2
        of (H1|T1)#(H2|T2) then {FusionList H1 H2}|{FusionMap T1 T2}
        [] nil#nil then nil
        else raise mapDeTailleDifferentesFusionMap end
        end
    end


    %pour le moment je choisi au hasard quelle arme recharger
    %cette fonction choisi l arme et si elle est suffisement load que
    %pour creer une nouvelle alors elle bind KindItem a la nouvelle arme sinon elle bind a null
    fun {ChargeItem ID KindItem Charact}
        if Charact.damage >= Input.maxDamage then ID = null Charact
        else
            local
                fun {Choose Weapons}
                    local
                        Chosen
                    in 
                        if Weapons == nil then KindItem = null Charact
                        else 
                            %choisir le sonnar puis le drone puis missile et mine seulement
                            if Charact.sonarDone == false then Chosen = sonar
                            elseif Charact.droneDone == false then Chosen = drone
                            elseif {List.member missile Weapons} andthen (Input.maxDistanceMissile - Input.minDistanceMissile) >= (Input.maxDistanceMine - Input.minDistanceMine) andthen Input.missile*3 =< Input.mine*4 then Chosen = missile %je veux bien attendre 1/4 de load en plus pour un missile si il a une meilleure portee
                            elseif {List.member mine Weapons} then Chosen = mine
                            else Chosen = {List.nth Weapons ( ({OS.rand} mod {List.length Weapons}) + 1 ) } 
                            end
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            
                            if Charact.Chosen >= Input.Chosen then {Choose {List.subtract Weapons Chosen}} %si load est deja au max on retire cet objet car je peux pas le choisir
                            elseif Charact.Chosen + 1 >= Input.Chosen andthen Chosen == sonar then % nouvelle arme
                                KindItem = Chosen 
                                {Record.adjoinList Charact [Chosen#(Charact.Chosen + 1) sonarDone#true]}
                            elseif Charact.Chosen + 1 >= Input.Chosen andthen Chosen == drone then
                                KindItem = Chosen
                                {Record.adjoinList Charact [Chosen#(Charact.Chosen + 1) droneDone#true]}
                            elseif Charact.Chosen + 1 >= Input.Chosen then % une nouvelle arme
                                KindItem = Chosen
                                {Record.adjoinAt Charact Chosen (Charact.Chosen + 1)}
                            else KindItem = null
                                {Record.adjoinAt Charact Chosen (Charact.Chosen + 1)} %un nouveau fragement d arme
                            end
                        end
                    end
                end
            in
                ID = Charact.identite
                {Choose [mine missile sonar drone]}
            end
        end
    end


    % Retourne la distance de Manhattan entre moi et le pt (X Y)
    fun {ManhattanDist Charact X Y}
        {Number.abs X-Charact.position.x} + {Number.abs Y-Charact.position.y}
    end

    % liste de position de type X#Y
    fun {ManhattanDistList Charact Liste}
        local
            fun {InnerFun Liste}
                case Liste
                of H|T then {ManhattanDist Charact H.1 H.2}|{InnerFun T}
                [] nil then nil
                end
            end
        in
            {InnerFun Liste}
        end
    end

    %prends en argument une liste de position de type X#Y et retourne ceux qui sont entre les 2 distances (comprise) sous forme liste de tuple X#Y 
    fun {GetAllElemAtManhattanDistBetween Charact Dist1 Dist2 Liste}
        case Liste
        of H|T then 
            if {ManhattanDist Charact H.1 H.2} >=Dist1 andthen {ManhattanDist Charact H.1 H.2 } =< Dist2 then 
                H|{GetAllElemAtManhattanDistBetween Charact Dist1 Dist2 T}
            else 
                {GetAllElemAtManhattanDistBetween Charact Dist1 Dist2 T}
            end
        [] nil then nil 
        end
    end

    % Choisi ou pas de tirer si on tire on bind KindFire a ce qu on utilise et comment(direction cible ...)
    % Si on ne tire pas alors KindFire est bind a null (KindFire de type FireItem)
    fun {FireItem ID KindFire Charact}
        if Charact.damage >= Input.maxDamage then ID = null Charact
        else
            ID = Charact.identite
            local

                fun {ChoseItemAndCheckUtility Utilisable}
                    if Utilisable == nil then KindFire = null Charact
                    else
                        local
                            FirePosition
                            GetAllMissile = {GetAllElemAtManhattanDistBetween Charact {Value.max Input.minDistanceMissile 2} Input.maxDistanceMissile Charact.mostAccurate}

                        in
                            if {List.member sonar Utilisable} then
                                KindFire = sonar
                                {Record.adjoinList Charact [sonar#0 lastMissileLaunched#false] }

                            elseif {List.member drone Utilisable} then
                                local
                                    Drone = {WhereToDrone Charact}
                                in
                                    if Drone == null then KindFire = null Charact
                                    else
                                        KindFire = drone(Drone.1 Drone.2)
                                        {Record.adjoinList Charact [drone#0 lastMissileLaunched#false] }
                                    end
                                end
                            elseif {List.member missile Utilisable} andthen GetAllMissile \= nil then
                                FirePosition = {WhereToFire Charact GetAllMissile}
                                KindFire = missile(FirePosition)
                                {Record.adjoinList Charact [missile#0 lastMissileLaunched#FirePosition]}%rappel FirePosition de type <position>

                            elseif {List.member mine Utilisable} then
                                FirePosition = {WhereToFire Charact {GetAllElemAtManhattanDistBetween Charact {Value.max Input.minDistanceMine 2} Input.maxDistanceMine Charact.mostAccurate}}
                                if FirePosition == null then
                                    {ChoseItemAndCheckUtility {List.subtract Utilisable mine}}
                                else
                                    KindFire = mine(FirePosition)
                                    {Record.adjoinList Charact [mine#0 myMines#(FirePosition|Charact.myMines) lastMissileLaunched#false]}
                                end

                            else KindFire = null Charact
                            end
                        end
                    end
                end
            in
                {ChoseItemAndCheckUtility {WeaponAvailable Charact} } % {WeaponAvailable Charact} = liste du style [mine#quantiteDeMine missile#quantiteDeMissile ...] J ai garde ce type car ca peut etre utile quand on fera la version efficace
            end
        end
    end

    % Choisi pour une position (pt(x:... y:...)) /!\ si la liste est vide null est renvoye
    fun {WhereToFire Charact Liste}
        local
            % fonction qui trouve le point avec le plus de voisins directs dans Liste (4 maximum)
            fun {FindHigestDensity InListe MaxCount Position}
                case InListe
                of H|T then
                    local
                        TheCount = {Count {GetAllAtExactDist H 1 Input.nRow Input.nColumn [false]} 0}
                    in
                        if TheCount == 4 then pt(x:H.1 y:H.2)
                        elseif TheCount > MaxCount then {FindHigestDensity T TheCount H}
                        else {FindHigestDensity T MaxCount Position}
                        end
                    end
                [] nil then pt(x:Position.1 y:Position.2)
                else
                    raise findHigestDensityException end
                end
            end

            fun {Count ListeVoisins N} % N = 0 au début
                case ListeVoisins
                of H|T then
                    if {List.member (H.x#H.y) Liste} then {Count T N+1}
                    else {Count T N}
                    end
                [] nil then N
                end
            end
        in
            if Liste == nil then null
            else
                {FindHigestDensity Liste ~1 pt(x:~10 y:~10) }
            end
        end
    end

    fun {WhereToDrone Charact}
        local
            fun {FullestRow Matrix Count Index MaxCount IndexMax} % a appeller comme ca: {FullestRow Matrice 0 1 0 1}
                case Matrix
                of H|T then
                    case H
                    of U|V then
                        if U > 0 then {FullestRow V|T Count+1 Index MaxCount IndexMax}
                        else {FullestRow V|T Count Index MaxCount IndexMax}
                        end
                    [] nil then
                        if Count > MaxCount then {FullestRow T 0 Index+1 Count Index}
                        else {FullestRow T 0 Index+1 MaxCount IndexMax}
                        end
                    end
                [] nil then IndexMax
                end
            end

            %ertourne la matrice sans la premiere colonne et bin ToBind au nombre d elem > 1 dans celle ci
            fun {CountFirstCol Matrix Count ToBind}
                case Matrix
                of Ligne1|AutresLignes then
                    case Ligne1
                    of U|V then
                        if U > 0 then V|{CountFirstCol AutresLignes Count+1 ToBind}
                        else V|{CountFirstCol AutresLignes Count ToBind}
                        end
                    [] nil then
                        ToBind = Count
                        nil %n arrive que si une des lignes est vide
                    end
                else
                    ToBind = Count 
                    nil
                end
            end

            fun {FullestCol Matrix Index MaxCount IndexMax} % appeller avec {FullestCol Matrix 1 0 1} Note: retourne l index 1 si la matrice est nil ou nil|nil
                local
                    ActualCount
                    NewMat = {CountFirstCol Matrix 0 ActualCount}
                in
                    case NewMat
                    of nil then IndexMax
                    else
                        if ActualCount > MaxCount then {FullestCol NewMat Index+1 ActualCount Index}
                        else {FullestCol NewMat Index+1 MaxCount IndexMax}
                        end
                    end
                end
            end
        in
            if {Value.isFree Charact.accurateIdNum} then null
            else
                if Input.nRow > Input .nColumn then
                    row#{FullestRow Charact.posEnnemi.(Charact.accurateIdNum) 0 1 0 1}
                else
                    column#{FullestCol Charact.posEnnemi.(Charact.accurateIdNum) 1 0 1}
                end
            end
        end
    end


    % Retourne un liste avec les armes entierement loadees. La liste est du type
    % [mine missile]. Si il n'y a rien de dispo alors c'est nil
    fun {WeaponAvailable Charact}
        local
            Ammunition = [mine#Charact.mine missile#Charact.missile drone#Charact.drone sonar#Charact.sonar]
            fun {Loop Munition Acc}
                case Munition
                of H|T then
                    case H
                    of Type#YourAmount then
                        if YourAmount < Input.Type then {Loop T Acc}%t as pas assez de load je l ajoute pas
                        else {Loop T Type|Acc}
                        end
                    end
                else Acc
                end
            end
        in
            {Loop Ammunition nil}
        end
    end

    /*
     * Fonction qui prends une valeur une position (pt(x:... y:...) ou X#Y) et une map et qui retourne la map avec la valeur mise a Val a la position /!\ la position doit etre compatible avec le tableau
     */
    fun {ChangeInMap PT Map Val}
        local
            %Mets le I eme elem de List a Val (Ieme en commencant par 1).
            fun {ChangeElemInList I Val List}
                if I =< 0 then raise outOfBoundInchangeInMap end %utile si le y est trop petit
                else
                    case List
                    of H|T then
                        if I > 1 then H|{ChangeElemInList I-1 Val T}
                        else Val|T
                        end
                    [] nil then raise outOfBoundInchangeInMap end %utile si le y est trop petit
                    end
                end
            end
        in
            case PT
            of pt(x:X y:Y) then {ChangeElemInList X {ChangeElemInList Y Val {List.nth Map X}} Map} %si le x est trop grand ou petit alors Nth renvoie une Missing else clause
            [] X#Y then {ChangeElemInList X {ChangeElemInList Y Val {List.nth Map X}} Map}
            end
        end
    end

    /*
     * fonctionnement similaire a ChangeInMap sauf que ce prends une liste de positions (de type X#Y ou pt(x: y: )
     */
    fun {ChangeListinMap PosList Map Val}
        case PosList
        of H|T then {ChangeListinMap T {ChangeInMap H Map Val} Val}
        else Map
        end
    end


    % decide de faire exploser une mine ou non. Si oui, Mine est bound a une position. Sinon Mine est bound a null
    fun {FireMine ID Mine Charact}
        if Charact.damage >= Input.maxDamage then ID = null Charact
        else
            ID = Charact.identite
            local

                % Retourne la 1 ere position de la liste etant a un elem > 0 dans la Matrice. Si aucune postion n est trouvee alors false est retourne.
                fun {FindCommunPos Liste Matrice}
                    case Liste
                    of H|T then
                        if {DetectIn Matrice Input.nRow Input.nColumn H.x H.y} then H
                        else {FindCommunPos T Matrice}
                        end
                    [] nil then false
                    else raise listeIsNotaProperListe end
                    end
                end
                
                FirstChoice
                SecondChoice % si FirstChoice est a false alors on a pas trouve dans la matrice Charact.posEnnemi.(Charact.accurateIdNum)... du coup je regarde dans toutes les matrices des ennemis
            in
                if {Value.isFree Charact.accurateIdNum} then Mine = null
                else
                    FirstChoice = {FindCommunPos Charact.myMines Charact.posEnnemi.(Charact.accurateIdNum)} % Charact.myMines est une liste de <positions> tandis que Charact.posEnnemi.(Charact.accurateIdNum) est une matrice ou nil
                    if FirstChoice \= false then
                        Mine = FirstChoice
                    else
                        SecondChoice = {FindCommunPos Charact.myMines {MergeAllEnemyMat Charact} } % une matrice ou nil
                        if SecondChoice \= false then 
                            Mine = SecondChoice
                        else
                            Mine = null
                        end 
                    end
                end

                if Mine == null then
                    {Record.adjoinAt Charact lastMineExplode false }
                else
                    {Record.adjoinList Charact [myMines#{List.subtract Charact.myMines Mine} lastMineExplode#Mine] }
                end
            end
        end
    end


    fun {SayMove ID Direction Charact}
        if ID == Charact.identite then Charact
        else
            local
                Connu = {Arity Charact.posEnnemi}
                IdNum = ID.id
            in
                if {List.member IdNum Connu} then % Je prends la map je bouge la map je retire a nouveau les iles je retourne (les iles sont retiree pour la 2em fois dans les fcts MoveMap)
                    case Direction
                    of north then {Record.adjoinList Charact [posEnnemi#{Record.adjoinAt Charact.posEnnemi IdNum {MoveMapUp    Charact.posEnnemi.IdNum} } lastMissileLaunched#false lastMineExplode#false] }
                    [] south then {Record.adjoinList Charact [posEnnemi#{Record.adjoinAt Charact.posEnnemi IdNum {MoveMapDown  Charact.posEnnemi.IdNum} } lastMissileLaunched#false lastMineExplode#false] }
                    [] west  then {Record.adjoinList Charact [posEnnemi#{Record.adjoinAt Charact.posEnnemi IdNum {MoveMapLeft  Charact.posEnnemi.IdNum} } lastMissileLaunched#false lastMineExplode#false] }
                    [] east  then {Record.adjoinList Charact [posEnnemi#{Record.adjoinAt Charact.posEnnemi IdNum {MoveMapRight Charact.posEnnemi.IdNum} } lastMissileLaunched#false lastMineExplode#false] }
                    else raise diretionNotACrdinalPoint end
                    end

                else %je cree une map de 1 je retire les iles je bouge la map je retire a nouveau les iles je retourne (les iles sont retiree pour la 2em fois dans les fcts MoveMap)
                    case Direction
                    of north then {Record.adjoinList Charact [posEnnemi#{Record.adjoinAt Charact.posEnnemi IdNum {MoveMapUp    {RemoveIslandFromMap {FillList {FillList 1 Input.nColumn} Input.nRow} Input.map} } } lastMissileLaunched#false lastMineExplode#false] }
                    [] south then {Record.adjoinList Charact [posEnnemi#{Record.adjoinAt Charact.posEnnemi IdNum {MoveMapDown  {RemoveIslandFromMap {FillList {FillList 1 Input.nColumn} Input.nRow} Input.map} } } lastMissileLaunched#false lastMineExplode#false] }
                    [] west  then {Record.adjoinList Charact [posEnnemi#{Record.adjoinAt Charact.posEnnemi IdNum {MoveMapLeft  {RemoveIslandFromMap {FillList {FillList 1 Input.nColumn} Input.nRow} Input.map} } } lastMissileLaunched#false lastMineExplode#false] }
                    [] east  then {Record.adjoinList Charact [posEnnemi#{Record.adjoinAt Charact.posEnnemi IdNum {MoveMapRight {RemoveIslandFromMap {FillList {FillList 1 Input.nColumn} Input.nRow} Input.map} } } lastMissileLaunched#false lastMineExplode#false] }
                    else raise diretionNotACrdinalPoint end
                    end
                end
            end
        end
    end


    /*
     * Retourne une liste dont on a mis a 0 les element ayant le meme index que les element > 0 de la liste des Iles /!\ les deux listes doivent avoir la meme taille
     */
    fun {RemoveIslandFromList Liste Iles}
        case Liste#Iles
        of (H1|T1)#(H2|T2) then
            if H2 > 0 then 0|{RemoveIslandFromList T1 T2}
            else H1|{RemoveIslandFromList T1 T2}
            end
        [] nil#nil then nil
        else
            raise listOfDifferentLenRemoveIslandFromList end
        end
    end

    /*
     * Retourne une Matrice dont on a mis a 0 les element ayant le meme index que les element > 0 de la matrice des Iles /!\ les deux matrices doivent avoir la meme taille
     */
    fun {RemoveIslandFromMap Map Iles}
        case Map#Iles
        of (H1|T1)#(H2|T2) then {RemoveIslandFromList H1 H2}|{RemoveIslandFromMap T1 T2}
        [] nil#nil then nil
        else raise mapOfDifferentLenRemoveIslandFromMap end
        end
    end


    % retourne la liste sans le dernier element de celle ci
    fun {DropLast Liste}
        case Liste
        of H|nil then nil
        [] H|T then H|{DropLast T}
        [] nil then nil
        else raise wrongArgumentExceptionDropLast end
        end
    end

    % Decale la matrice vers la droite-> mets des 0 dans premiere colonne et la derniere colonne est supprimee puis retire de cette nouvelle matrice les positions ou il y a des iles.
    fun {MoveMapRight Map}
        local
            fun {InnerFun Map}
                case Map
                of H|T then {DropLast 0|H}|{InnerFun T}
                [] nil then nil
                else raise wrongArgumentExceptionMoveMapRight end
                end
            end
        in
            {RemoveIslandFromMap {InnerFun Map} Input.map}
        end
    end



    % Decale la matrice vers la gauche-> la 1ere colonne est supprimee et la derniere est remplie de 0 puis retire de cette nouvelle matrice les positions ou il y a des iles.
    fun {MoveMapLeft Map}
        local
            fun {InnerFun Map}
                case Map
                of H|T then 
                    {List.append H.2 [0] }|{InnerFun T}
                [] nil then nil
                else raise wrongArgumentExceptionMoveMapLeft end
                end
            end
        in
            {RemoveIslandFromMap {InnerFun Map} Input.map}
        end
    end



    % Decale la matrice vers le bas-> mets des 0 dans premiere ligne et la derniere ligne est supprimee puis retire de cette nouvelle matrice les positions ou il y a des iles. 
    fun {MoveMapDown Map}
        local
            fun {InnerFun Map}
                if Map \= nil then
                    {FillList 0 {List.length Map.1 }}|{DropLast Map}
                else nil
                end
            end
        in
            {RemoveIslandFromMap {InnerFun Map} Input.map}
        end
    end



    % Decale la matrice vers le haut-> mets des 0 dans derniere ligne et la premiere ligne est supprimee puis retire de cette nouvelle matrice les positions ou il y a des iles.
    fun {MoveMapUp Map}
        local
            fun {InnerFun Map}
                if Map \= nil then
                    {List.append Map.2 [{FillList 0 {List.length Map.1 }}] }
                else nil
                end
            end
        in
            {RemoveIslandFromMap {InnerFun Map} Input.map}
        end
    end


    /*
     * Retourne toutes les <positions> (pt(x: y: )) a une distance "Distance" de Manhattan autour du point Position (pt( ) ou x#y). Les points peuvent etre des iles mais pas outOfBound
     * /!\ les points a distance plus petite ne sont pas pris en compte. On n a que la distance exacte. Si  PosToIgnore est soit une liste vide soit une lliste de position a ignorer (pt(x: y: ))
     */
    fun {GetAllAtExactDist Position Distance NRow NColumn PosToIgnore} %explication du fonctionnement: je calcule les pt a distance Distance au dessus en dessous a gauche et a doite puis j incremente les x et y de maniere a aller de l un a l autre
        local
            Posit
            Delta = [1#1 1#~1 ~1#~1 ~1#1]
            Stop

            fun {AddNewPos Pos Delta Stop}
                case Delta
                of H|T then 
                    if Pos \= Stop.1 andthen Pos.x =< NRow andthen Pos.x > 0 andthen Pos.y =< NColumn andthen Pos.y >0 andthen {Not {List.member Pos PosToIgnore}} then
                        Pos|{AddNewPos pt(x:(Pos.x+H.1) y:(Pos.y+H.2) ) Delta Stop}
                    elseif Pos \= Stop.1 then
                        {AddNewPos pt(x:(Pos.x+H.1) y:(Pos.y+H.2) ) Delta Stop}
                    else
                        {AddNewPos Pos T Stop.2}
                    end
                [] nil then nil
                else raise wrongStructureExceptionGetAllAtExactDist end
                end
            end
        in
            case Position
            of X#Y then Posit = pt(x:X y:Y)
            else Posit = Position
            end

            Stop = [pt(x:Posit.x y:(Posit.y+Distance)) pt(x:(Posit.x+Distance) y:Posit.y) pt(x:Posit.x y:(Posit.y-Distance)) pt(x:(Posit.x-Distance) y:Posit.y)]

            {AddNewPos pt(x:(Posit.x-Distance) y:Posit.y) Delta Stop} %je commence mon tour par le point au dessus
        end
    end

    /*
     * Meme chose qu avec GetAllAtExcatDist sauf que cette fois si on prends une liste de position en argument (X#Y ou pt(x: y: )) par contre PosToIgnore est une liste de pt(x: y: )
     */
    fun {GetAllAtExactDistListe Liste Distance NRow NColumn PosToIgnore}
        case Liste
        of H|T then {List.append {GetAllAtExactDist H Distance NRow NColumn PosToIgnore} {GetAllAtExactDistListe T Distance NRow NColumn PosToIgnore}}
        else nil
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
                Connu = {Arity Charact.posEnnemi}
                IdNum = ID.id
            in
                if {List.member IdNum Connu} andthen Charact.accurateIdNum == IdNum then
                        {Record.adjoinList Charact [posEnnemi#{Record.subtract Charact.posEnnemi IdNum} accurateIdNum#_]}%je retire le joueur de mes positions d ennemi
                elseif {List.member IdNum Connu} then
                    {Record.adjoinAt Charact posEnnemi {Record.subtract Charact.posEnnemi IdNum}}%je retire le joueur de mes positions d ennemi
                    
                else
                    Charact
                end
            end
        end
    end

    % retroune une liste de taille N remplie avec la valeur N
    fun {FillList Value N}
        if N =< 0 then nil
        else
            Value|{FillList Value N-1}
        end
    end

    /*
     * BFS trouve le chemin le plus court pour se rapprocher d un ennemi quand on connait sa position :)
     * /!\ va aller dessus alors qu on veut s arreter avant. -> j evite ça en ajoutant tout les points a dist=2 des positions des ennemis quand j'appelle la fct BFS.
     * (X Y) est la position de depart. La liste est une liste contenant les position supposees des differents ennemis(X Y ou pt(x: y: )). Le chemin retourne est une liste (X#Y) commencant par la
     * popsition actuelle et terminant par une des positions supposee des ennemis. Si aucun chemin ne menne vers nos ennemi alors null est retourne
     */
    fun {BFS X Y Liste Charact}
        local  
            % cree une matrice de taille (SizeX sizeY) remplie de InitValue 
            fun {NewMap SizeX SizeY InitValue}
                {FillList {FillList InitValue SizeY} SizeX}
            end

            fun {Loop MyQueue Path} % Rappel Path est toute la map avec toutes les positions!
                if {IsEmpty MyQueue} then null % On a pas touve de chemin vers un de nos ennemi
                else
                    case {Dequeue MyQueue}
                    of X1#Y1 then
                        if {List.member X1#Y1 Liste} orelse {List.member pt(x:X1 y:Y1) Liste} then {ReversePath X1#Y1 Path X1#Y1|nil}
                        else
                            {Loop MyQueue {ChangeListinMap {InnerLoop X1 Y1 [~1#0 1#0 0#~1 0#1] MyQueue Path nil} Path X1#Y1}}
                        end
                    end
                end
            end

            %retourne la ou on doit ajouter la position dans Path
            fun {InnerLoop X Y DeltaList MyQueue Path Acc}
                case DeltaList
                of Delta|T then
                    if {Not {DetectIn Input.map Input.nRow Input.nColumn X+Delta.1 Y+Delta.2}} andthen {NotPosIn Path Input.nRow Input.nColumn X+Delta.1 Y+Delta.2} andthen {Not {List.member (X+Delta.1)#(Y+Delta.2) Charact.passage}} then %si pas ile pas OutOfBound et pas deja fait et pas sur notre passage
                        {Enqueue MyQueue (X+Delta.1)#(Y+Delta.2)}
                        {InnerLoop X Y T MyQueue Path (X+Delta.1)#(Y+Delta.2)|Acc}
                    else
                        {InnerLoop X Y T MyQueue Path Acc}
                    end
                else
                    Acc
                end
            end


            fun {NotPosIn Matrice NRow NColumn X Y}
                %note, dans {List.nth liste I} index commence a 1 et pas a 0
                case {List.nth {List.nth Matrice X } Y}
                of A#B then false
                else true
                end
            end     

            fun {ReversePath Pos Path Acc}
                if Pos == X#Y then Acc % X#Y est le point de depart
                else
                    local
                        NewPos = {List.nth {List.nth Path Pos.1 } Pos.2}
                    in
                        {ReversePath NewPos Path NewPos|Acc}
                    end
                end
            end       

            Path MyQueue
        in
            MyQueue = {NewQueue}

            Path = {ChangeInMap X#Y {NewMap Input.nRow Input.nColumn 0} X#Y}%le pt de depart est marque le reste est a 0

            {Enqueue MyQueue X#Y}%le pt de depart est mis dans la queue pour etre sortit directement apres et commencer la recurssion

            {Loop MyQueue Path}
        end
    end


    /*
    * Merci le dernier TP9 :p Ceci est une Queue ayant le meme comportement qu en java
    */ 
    fun {NewQueue}
        local
            proc {MsgLoop S1 State}
                case S1
                    of Msg|S2 then {MsgLoop S2 {ChangeState Msg State}}
                    [] nil then skip
                end
            end

            fun {ChangeState Msg State}
                case Msg
                    of enqueue(X) then {Append State [X]}
                    [] dequeue(?X) then
                        if State==nil then X=nil nil
                        else X=State.1 State.2
                        end
                    [] isEmpty(X) then X=(State==nil) State
                end
            end
            
            Stream
        in
            thread {MsgLoop Stream nil} end
            {NewPort Stream} %le port est retourne
        end
    end
        
    /*
     * Je ne te fais pas un dessin pour les spec de ces 3 fcts...
    */
    proc {Enqueue Q X}
    {Send Q enqueue(X)}
    end

    fun {Dequeue Q}
        local
            X
        in
            {Send Q dequeue(X)}
            {Wait X}
            X
        end
    end

    fun {IsEmpty Q}
        local
            X
        in
            {Send Q isEmpty(X)}
            {Wait X}
            X
        end
    end

    % /!\ positions de type <position> pt(x: y:)
    fun {SayDamageTaken ID Damage Charact}
        if ID == Charact.identite then Charact
        else
            local
                IdNum = ID.id
                PosList
                BlankMap = {FillList {FillList 0 Input.nColumn} Input.nRow} %equivalent de NewMap
                FinalMap

                fun {FilterPosList Liste NRow NColumn}
                    case Liste
                    of Pos|T then
                        if Pos.x =< NRow andthen Pos.x > 0 andthen Pos.y =< NColumn andthen Pos.y >0 then
                            Pos|{FilterPosList T NRow NColumn}
                        else
                            {FilterPosList T NRow NColumn}
                        end
                    [] nil then nil
                    else raise filterPosListError end
                    end
                end
            in
                case (Charact.lastMissileLaunched)#(Charact.lastMineExplode)
                of false#false then PosList = nil
                [] false#(pt(x:X y:Y)) then PosList = [Charact.lastMineExplode]
                [] (pt(x:X y:Y))#false then PosList = [Charact.lastMissileLaunched]
                [] (pt(x:X1 y:Y1))#(pt(x:X2 y:Y2)) then PosList = [Charact.lastMissileLaunched Charact.lastMineExplode]
                else raise sayDamageTakenLastMissileLaunchedOrLastMineExplodeOfWrongType((Charact.lastMissileLaunched)#(Charact.lastMineExplode)) end
                end

                if Damage == 2 then
                    
                    FinalMap = {ChangeListinMap {FilterPosList PosList Input.nRow Input.nColumn} BlankMap 1}
                elseif Damage == 1 then
                    FinalMap = {ChangeListinMap {GetAllAtExactDistListe PosList 1 Input.nRow Input.nColumn [false]} BlankMap 1}
                else
                    raise unKnownDamageValue end
                end
                {Record.adjoinAt Charact posEnnemi {Record.adjoinAt Charact.posEnnemi IdNum FinalMap}}
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
            [] dive then {TreatStream T {Record.adjoinAt Charact divePermission true}} %autorise a nouveau a plonger
            [] chargeItem(ID KindItem) then {TreatStream T {ChargeItem ID KindItem Charact}}
            [] fireItem(ID KindFire) then {TreatStream T {FireItem ID KindFire Charact}}
            [] fireMine(ID Mine) then {TreatStream T {FireMine ID Mine Charact}}
            [] isDead(Answer) then Answer = (Charact.damage >= Input.maxDamage) {TreatStream T Charact}
            [] sayMove(ID Direction) then {TreatStream T {SayMove ID Direction Charact}}
            % version Dummy:
            [] saySurface(ID) then {TreatStream T Charact}
            [] sayCharge(ID KindItem) then {TreatStream T Charact}
            [] sayMinePlaced(ID) then {TreatStream T Charact}
            [] sayMissileExplode(ID Position Message) then {TreatStream T {SayMineOrMissileExplode Position Message Charact true}}
            [] sayMineExplode(ID Position Message) then {TreatStream T {SayMineOrMissileExplode Position Message Charact false}}
            [] sayAnswerDrone(Drone ID Answer) then {TreatStream T Charact} %normalement il faut faire qqchose, mais la j ignore mon drone
            [] sayAnswerSonar(ID Answer) then {TreatStream T Charact} %idem que ligne precedente
            [] sayDeath(ID) then {TreatStream T {SayDeath ID Charact}}
            [] sayDamageTaken(ID Damage LifeLeft) then {TreatStream T {SayDamageTaken ID Damage Charact}}
            [] sayPassingDrone(Drone ID Answer)then {SayPassingDrone Drone ID Answer Charact} {TreatStream T Charact}
            [] sayPassingSonar(ID Answer) then {SayPassingSonar ID Answer Charact} {TreatStream T Charact}
            [] getCharact(Characteristic) then Characteristic=Charact {TreatStream T Charact}
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
            {TreatStream Stream characteristic(identite:id(id:ID color:Color name:'Antoine') position:pt(x:~1 y:~1) passage:nil divePermission:true mine:0 missile:0 drone:0 sonar:0 damage:0 posEnnemi:pos() myMines:nil lastMissileLaunched:pt(x:~10 y:~10) lastMineExplode:false sonarDone:false droneDone:false )}
            % Contenu type de characteristic(position:pt(x:2 y:3) passage:2#3|2#4|1#4|nil identite:id(color:blue id:1 name:'Antoine') divePermission:true mine:0 missile:0 drone:0 sonar:0 damage:0 posEnnemi:pos(IdNum1:matrice1 IdNum2:matrice2(1=possible 0=pas la)) myMines:ListeDesMines)
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
