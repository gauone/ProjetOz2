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

