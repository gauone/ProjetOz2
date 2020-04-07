functor
import
   GUI
   Input
   PlayerManager
define


   /**************************************
    * Variables Utiles
    *************************************/


   PlayerPortList % Liste des ports des joueurs


   /**************************************
    * Fonctions et Procedures Utiles
    *************************************/


   % Initialise la liste des ports de jouers dans PlayerPortList : 
   % Chaque joueur est d'un certain Kind et est initialise avec un Id unique et une Color
   % PlayerManager.playerGenerator renvoi le numero de port qui sera stocke
   fun{InitPlayerPortList}
      fun{IPPLrec Players Colors Id}
         case Players#Colors
         of (Kind|T1)#(Color|T2) then
         PlayersList = {PlayerManager.playerGenerator Kind Color Id}|{IPPLrec T1 T2 Id+1}
         else
            nil
         end
      end
   in
      {IPLrec Input.players Input.colors 1}
   end


   % Lance les joueurs sur l'interface graphique : 
   %
   proc{SetUpPlayers}
    	case PlayerPortList
      of nil then
         skip
    	[] PlayerPort|T then
         Id Position
      in
    		{Send PlayerPort initPosition(Id Position)} % Demande au joueur son Id et sa Position
    		{Wait Id}
         {Wait Position}
    		{Send GUIPort initPlayer(Id Position)} % Une fois recu, on envoit a l'interface
    		{SetUpPlayers T}
    	end
   end


in
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                   %%%
%%%               Main                %%%
%%%                                   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Cree l'interface graphique
   GUIPort = {GUI.portWindow}
   {Send GUIPort buildWindow}

   {InitPlayerPortList} % Initialise la liste des ports des joueurs
   {SetUpPlayers} % Demande a chaque joueur de choisir un point de depart

   
end
