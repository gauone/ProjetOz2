functor
import
    Input
export
    portPlayer:StartPlayer
define
    InitPosition
    IslandDetected
    GeneratePosition
    FindOtherPos
    Move
    PossiblesDir
    TreatStream
    StartPlayer
in
    /**************************************
    * Fonctions et Procedures Utiles
    *************************************/

    /*Retourne le nouveau record apres avoir bind ID et Pos a leur valeurs.
    * Pos est une poistion ou il y a de l eau!*/
    fun {InitPosition ID Pos Charact}
        ID = Charact.id
        Pos={GeneratePosition}
        {Record.adjoinAt Charact position Pos}%retourne le nouveau record
    end

    % Retourne true si le point (X Y) est une ile. Si outOfBounds alors vrai aussi.
    fun {IslandDetected X Y}
        if X > Input.nRow orelse Y > Input.nColumn orelse X =< 0 orelse Y =< 0 then true
        else
            %note, dans {List.nth liste I} index commence a 1 et pas a 0
            {List.nth {List.nth Input.map X } Y} > 0
        end
    end

    %donne une position au hasard n etant pas une ile ou outOfBound
    fun {GeneratePosition}
        local  
            Abs Ord
        in
            Abs = ({OS.rand} mod Input.nRow) + 1
            Ord = ({OS.rand} mod Input.nColumn) + 1
            if {IslandDetected Abs Ord} then {FindOtherPos Abs Ord}
            else pt(x:Abs y:Ord)
            end
        end
    end

    % Si par malchance le {OS.rand} a donne une ile on avance dans la matrice jusqu a trouver de l eau
    fun {FindOtherPos X Y}
        local
            Abs Ord
        in
            Ord = (Y mod Input.nColumn) + 1
            if Ord == 1 then Abs = (X mod Input.nRow) + 1 %on passe a la ligne suivante ou on remonte en haut
            else Abs = X
            end

            if {IslandDetected Abs Ord} then {FindOtherPos Abs Ord}
            else pt(x:Abs y:Ord)
            end
        end
    end

    %Random dans un premier temps ;p
    fun {Move ID Position Direction Charact}
        ID = Charact.id
        local
            Abs = Charact.position.x
            Ord = Charact.position.y
            Possibles = {PossiblesDir Abs Ord Charact.passage}%une liste contenant les directions
        in
            %TODO 
        end
    end
    
    % Retourne les directions autres que la surface possibles pour la position donnee par (X Y)
    % La valeur retournee est une liste du style [north south west east].
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
                        if {IslandDetected (X + Xmvt) (Y + Ymvt)} orelse {List.member (X + Xmvt)#(Y + Ymvt) Passage}
                            then {Loop T Acc}
                        else {Loop T A|Acc}
                        end
                    end
                else Acc
                end
            end
        in
            {Loop Mouvements nil}
        end
    end
            




    /**************************************
    Lancement et traitement de la stream du player
    *************************************/


    /*dans cette fonction on est autorisé à ajouter des paramètres ;)
    /!\ faut les rajouter dans la ligne en dessous de NewPort plus bas!*/
    proc{TreatStream Stream Charact}%ajoutés par moi: Charact-> les caracteristiques a chaque etat
        case Stream
        of H|T then
            case H
            of initPosition(ID Position) then {TreatStream T {InitPosition ID Position Charact}}
            [] move(ID Position Direction) then {TreatStream T {Move ID Position Direction}}
            end
        [] nil then {Show 'Player s Stream ended -> see Player file'}
        else raise iLegalOptionExceptionInPaylerStream(H) end
        end
    end


    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream characteristic(id:id(id:ID color:Color name:'Antoine') position passage:nil)}
        end
        Port
    end

end

%TODO:
/*
Vérifier que le nom ne doit rien a voir avec le reste :p 
Changer la fonction Move qui est random pour le moment
*/