%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                   %%%
%%%         Sandbox - Tests           %%%
%%%                                   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare

PlayerPortList
Players = [player1 player2]
Colors = [yellow green]


% PlayerManager.playerGenerator -> Port
% Input.players -> Players
% Input.colors -> Colors
%
% Initialise la liste des ports de jouers dans PlayerPortList : 
% Chaque joueur est d'un certain Kind et est initialise avec un Id unique et une Color
% PlayerManager.playerGenerator renvoi le numero de port qui sera stocke
declare
fun{InitPlayerPortList}
    fun{IPPLrec P C Id}
        case P#C
        of (Kind|T1)#(Color|T2) then
            {Port Kind Color Id}|{IPPLrec T1 T2 Id+1}
        else
            nil
        end
    end
in
    {IPPLrec Players Colors 1}
end


fun{Port K C I}
    ({OS.rand} mod 10)
end

PlayerPortList = {InitPlayerPortList}
{Browse PlayerPortList}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare

GUIS
GUIP
S1
P1
S2
P2

{NewPort GUIS GUIP}
{NewPort S1 P1}
{NewPort S2 P2}
PlayerPortList = [P1 P2] % Id = 1, Port = P1 | Id = 2, Port = P2


% Lance les joueurs sur l'interface graphique : 
proc{SetUpPlayers}
    proc{SUPrec L}
        case L
        of PlayerPort|T then
            local
                Id Pos
            in
                {Send PlayerPort initPosition(Id Pos)} % Demande au joueur son Id et sa position Pos
                {Wait Id}
                {Wait Pos}
                {Send GUIP initPlayer(Id Pos)} % Une fois recu, on envoit a l'interface
                {SUPrec T}
            end
        else
            skip
        end
    end
in
    {SUPrec PlayerPortList}
end


thread
    {SetUpPlayers}
end
thread
    {Delay 500}
    case S1.1
    of initPosition(Id Pos) then 
        Id = 1
        Pos = pt(x:1 y:1)
    end

    {Delay 500}
    case S2.1
    of initPosition(Id Pos) then 
        Id = 2
        Pos = pt(x:2 y:2)
    end
end
thread
    {Browse GUIS}
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare

EtatJoueursList
Players = [player1 player2]


% Initialise la liste des etats des jouers dans EtatJoueursList : 
% Chaque joueur est d'un certain Kind et est initialise avec un Id unique et une Color
% PlayerManager.playerGenerator renvoi le numero de port qui sera stocke
declare
fun{InitEtatJoueursList}
    fun{IEJLrec P}
        case P
        of H|T then
             etatJoueur(surface:0)|{IEJLrec T}
        else
            nil
        end
    end
in
    {IEJLrec Players}
end


EtatJoueursList = {InitEtatJoueursList}
{Browse EtatJoueursList}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare

S1
P1
S2
P2

{NewPort S1 P1}
{NewPort S2 P2}
PlayerPortList = [P1 P2]

% Envoi le Message sur la radio (donc a tout les ports)
proc{Radio Message}
    proc{Rrec M L}
        case L
        of PlayerPort|T then
            {Send PlayerPort Message}
            {Rrec M T}
        [] nil then
            skip
        end
    end
in
    {Rrec Message PlayerPortList}
end

{Radio 'Test radio'}
thread {Browse S1} end
thread {Browse S2} end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


/*
 * Renvoi une liste egale a List ou l'element a l'indice Ind a ete modifie par Elem
 */
declare
fun{AdjoinListAt List Ind Elem}
    case List
    of H|T then
        if(Ind == 1) then 
            Elem|T
        else
            H|{AdjoinListAt T Ind-1 Elem}
        end
    [] nil then
        nil
    end
end

local
    L1 = [1 2]
    L
in
    thread {Browse L} end
    thread L = {AdjoinListAt L1 3 3} end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare 

Players = [1 2 3]

/*
 * Players -> Input.players
 *
 * Initialise la liste de vie des jouers (ordre Id)
 */
fun{InitVieJoueursList}
    fun{IVJLrec P}
        case P
        of H|T then
            1|{IVJLrec T}
        else
            nil
        end
    end
in
    {IVJLrec Players}
end

local
    L
in
    thread {Browse L} end
    thread L = {InitVieJoueursList} end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare
/*
 * Renvoi la somme des elements de List<int>
 */
fun{SumList List}
    fun{SLacc L A}
        case L
        of H|T then 
            {SLacc T A+H}
        [] nil then 
            A
        end
    end
in
    {SLacc List 0}
end

local 
    List = [1 2 3 4 5]
in
    {Browse {SumList List}}
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare

Message = sayDeath(id(blue 1 basicAI))

proc{PatterMatchingTest M}
    case M
    of sayDeath(id(Color Id Name)) then
        {Browse 'Matched'}
    else
        {Browse 'IDK'}
    end
end

{PatterMatchingTest Message}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare


/*
 * Supprimer les {Browse ...}
 *
 * InformMissile envoi les informations du missile a chaque sub dans l'ordre de PPL (ordre Id)
 * Retourne une MaJ de la VieJoueurList
 * PPL = PlayerPortList
 * FID = FireId
 * MP = MissilePosition
 * VJL = VieJoueurList (car c'est la premiere utilisation d'une subVJL)
 */
fun{InformMissile PPL FID MP VJL}
    local
        MissileMessage
    in 
        case PPL
        of Port|T then 
            {Send Port sayMissileExplode(FID MP MissileMessage)}
            {Browse 'Wait MissileMessage'}
            {Wait MissileMessage}
            {Browse 'MissileMessage binded'}

            if(MissileMessage \= null) then
                %{Radio MissileMessage}

                case MissileMessage
                of sayDeath(id(ActualColor ActualId ActualName)) then % Note la mort d'un joueur
                    {InformMissile T FID MP {AdjoinListAt VJL ActualId 0}}
                else
                    raise illegalMissileMessage end
                end
            else
                {Browse 'MissileMessage was null'}
                {InformMissile T FID MP VJL}
            end
        else
            VJL
        end
    end
end


local
    SubVJL
    S1
    P1
    S2
    P2
    {NewPort S1 P1}
    {NewPort S2 P2}

    PlayerPortList = [P1 P2]
    FireId = 1
    MissilePosition = 5
    VieJoueursList = [1 1]
in
    thread
        SubVJL = {InformMissile PlayerPortList FireId MissilePosition VieJoueursList}
        {Delay 1000}
        {Browse SubVJL}
    end

    thread
        case S1
        of H|T then 
            case H
            of sayMissileExplode(A1 A2 M) then
                {Delay 500}
                {Browse 'Player 1 binds null'}
                M = null
            end
        end

        case S2
        of H|T then 
            case H
            of sayMissileExplode(A1 A2 M) then
                {Browse 'Player 2 binds sayDeath'}
                {Delay 500}
                M = sayDeath(id(blue 2 basicAI))
            end
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare


/*
 * InformMine envoi les informations de la mine a chaque sub dans l'ordre de PPL (ordre Id)
 * Retourne une MaJ de la VieJoueurList
 * PPL = PlayerPortList
 * MID = MineId
 * MP = MinePosition
 * SVJLM = SubVJLMissile (car c'est le dernier cas ou il y aurait pu y avoir un mort)
 */
fun{InformMine PPL MID MP SVJLM}
    local
        MineMessage
    in 
        case PPL
        of Port|T then 
            {Send Port sayMineExplode(MID MP MineMessage)}
            {Browse 'Wait MineMessage'}
            {Wait MineMessage}
            {Browse 'MineMessage binded'}

            if(MineMessage \= null) then
                %{Radio MissileMessage}

                case MineMessage
                of sayDeath(id(ActualColor ActualId ActualName)) then % Note la mort d'un joueur
                    {InformMine T MID MP {AdjoinListAt SVJLM ActualId 0}}
                else
                    raise illegalMineMessage end
                end
            else
                {Browse 'MineMessage was null'}
                {InformMine T MID MP SVJLM}
            end
        else
            SVJLM
        end
    end
end


local
    SubVJLMine
    S1
    P1
    S2
    P2
    S3
    P3
    {NewPort S1 P1}
    {NewPort S2 P2}
    {NewPort S3 P3}

    PlayerPortList = [P1 P2 P3]
    MineId = 1
    MinePosition = 5
    SubVJLMissile = [1 1 1]
in
    thread
        SubVJLMine = {InformMine PlayerPortList MineId MinePosition SubVJLMissile}
        {Delay 1000}
        {Browse SubVJLMine}
    end

    thread
        case S1
        of H|T then 
            case H
            of sayMineExplode(A1 A2 M) then
                {Browse 'Player 1 binds null'}
                M = null
            end
        end

        case S2
        of H|T then 
            case H
            of sayMineExplode(A1 A2 M) then
                {Browse 'Player 2 binds sayDeath'}
                M = sayDeath(id(blue 2 basicAI))
            end
        end

        case S3
        of H|T then 
            case H
            of sayMineExplode(A1 A2 M) then
                {Browse 'Player 3 binds null'}
                M = null
            end
        end


    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Premiere version : sens de X et Y

declare

fun{NewPosition MovePos MoveDir}
    case MoveDir
    of north then
        case MovePos
        of pt(x:X y:Y) then 
            pt(x:X-1 y:Y)
        else
            raise illegalPosition end
        end
    [] east then
        case MovePos
        of pt(x:X y:Y) then 
            pt(x:X y:Y+1)
        else
            raise illegalPosition end
        end
    [] south then
        case MovePos
        of pt(x:X y:Y) then 
            pt(x:X+1 y:Y)
        else
            raise illegalPosition end
        end
    [] west then 
        case MovePos
        of pt(x:X y:Y) then 
            pt(x:X y:Y-1)
        else
            raise illegalPosition end
        end
    else
        raise illegalDirection end
    end
end

{Browse {NewPosition pt(x:3 y:2) north}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare

Arg = 3

proc{GiveZero}
    proc{T A}
        if(A > 0) then
            {Browse '--- Decremente'}
            {T (A-1)}
        else
            {Browse 'Zombie expression ZZZzzz'}
        end
    end
in
    {T Arg}
    {Browse 'Get Zero'}
end

{GiveZero}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare

fun{RemoveInd List I}
    case List
    of H|T then
        if(I == 1) then
            T
        else
            H|{RemoveInd T I-1}
        end
    end
end

local
    List1 = [a b c d e f]
    List2 = {RemoveInd List1 3}
in
    {Browse List2}
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


declare

PPL = [p1 p2 p3 p4 p5]
VJL = [1 1 0 1 0]

/*
 * Fonctions de calque de PPL sur VJL : 
 * 
 * Pre : |PPL| == |VJL|
 * Post : 
 *    PPL = [P1 P2 P3 P4]
 *    Si VJL = [1 1 0 1]
 *    Renvoi : PPL = [P1 P2 P4]
 */
fun{Ecrase PPL VJL}
    case PPL
    of Hp|Tp then
        case VJL
        of Hv|Tv then
            if(Hv == 1) then
                Hp|{Ecrase Tp Tv}
            else
                {Ecrase Tp Tv}
            end
        else
            nil
        end
    else
        nil
    end
end


{Browse {Ecrase PPL VJL}}