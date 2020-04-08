functor
import
   GUI
   Input
   PlayerManager
define


   /**************************************
    * Variables Utiles
    *************************************/


   /*
    * Liste des ports des joueurs (Ordre Id)
    */
   PlayerPortList 

   /*
    * List dont chaque element est un record representant l'etat d'un joueur (ordre correspond a l'Id)
    * EtatJoueursList = [ etatJoueur(surface:<int> [nombre de tour avant de pouvoir replonger, 0 = Peut plonger, -1 = en mer] etatJoueur(...) ...]
    */
   EtatJoueursList


   /**************************************
    * Fonctions et Procedures Utiles
    *************************************/


   /*
    * Initialise la liste des ports de jouers dans PlayerPortList : 
    * Chaque joueur est d'un certain Kind et est initialise avec un Id unique et une Color
    * PlayerManager.playerGenerator renvoi le numero de port qui sera stocke
    */
   declare
   fun{InitPlayerPortList}
      fun{IPPLrec P C Id}
         case P#C
         of (Kind|T1)#(Color|T2) then
               {PlayerManager.playerGenerator Kind Color Id}|{IPPLrec T1 T2 Id+1}
         else
               nil
         end
      end
   in
      {IPPLrec Input.players Input.colors 1}
   end


   /*
    * Initialise la liste des etats des jouers dans EtatJoueursList (ordre Id)
    */
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
      {IEJLrec Input.players}
   end


   /*
    * Envoi le Message sur la radio (donc a tout les ports ET le GUI)
    */
   proc{Radio Message}
      proc{Rrec M L}
         case L
         of PlayerPort|T then
               {Send PlayerPort Message}
               {Rrec M T}
         [] nil then
               {Send GUIP Message}
         end
      end
   in
      {Rrec Message PlayerPortList}
   end


   /*
    * Lancement des joueurs : 
    * Demande de leurs position (par l'Id) par l'interface
    */
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


   /*
    * Partie tour par tour
    */
   proc{StartTBT}
      proc{TBTActions PPL Round Id EJL} % Recursion sur les joueurs (ordre PlayerPortList est dans l'ordre des Ids)
         case PPL
         of PlayerPort|T then % Actions pour un tour d'un joueur
            %%%%  -- Pt.1 --  %%%

            % if(EtatsJoueurs.Id.Surface == true) then
            %    next

            %%%%  -- Pt.2 --  %%%

            if(Round == 1 orelse {List.nth EJL Id}.surface > 0) then
               {Send PlayerPort dive}
            end

            %%%%  -- Pt.3 --  %%%

            {Send PlayerPort move(MoveId MovePos MoveDir)}
            {Wait MoveId}
            {Wait MovePos}
            {Wait MoveDir}
            
            %%%%  -- Pt.4 --  %%%

            if(MoveDir == surface) then
               {Radio saySurface(MoveId)}
               {TBTActions PPL Round Id+1 {Record.adjoinAt {List.nth EJL Id} surface (Input.turnSurface-1)}}
            end

            %%%%  -- Pt.5 --  %%%
            
            {Radio sayMove(MoveId MoveDir)}
            
            %%%%  -- Pt.6 --  %%%

            {Send PlayerPort chargeItem(ChargeId ChargeItem)}
            {Wait ChargeId}
            {Wait ChargeItem}

            if(ChargeItem \= null) then
               {Radio sayCharge(ChargeId ChargeItem)}
            end

            %%%%  -- Pt.7 --  %%%

            {Send PlayerPort fireItem(FireId FireItem)} %FireItem <fireitem>
            {Wait FireId}
            {Wait FireItem}

            case FireItem
            of mine(Position) then 
               {Radio sayMinePlaced(FireId)}
            [] missile(Position) then
               for Port in PlayerPortList do
                  local
                     Message
                  in 
                     {Send Port sayMissileExplode(FireId Position Message)}
                     {Wait Message}
                     if(Message \= null) then 
                        {Radio Message}
                     end
                  end
               end
            [] drone(row:Row) then
                  %
            [] drone(column:Column) then
               %
            [] sonar then 
               %
            else
               skip % Pas d'item tire
            end




            {TBTActions T Round Id+1}
         else % Chaque jouer a joue 
            

            {TBTActions PPL Round+1 1 EtatJoueursList}
         end
      end
   in
      {TBTActions PlayerPortList 1 1}
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
   GUIP = {GUI.portWindow} % Recuperation du port de l'interface
   {Send GUIP buildWindow} % Lancement de l'interface

   PlayerPortList = {InitPlayerPortList} % Initialise la liste des ports des joueurs dans l'ordre des Id
   EtatJoueursList = {InitEtatJoueursList} % Initialise le tuple des etats des joueurs dans l'ordre des Ids
   {SetUpPlayers} % Demande a chaque joueur de choisir un point de depart

   if(Input.isTurnByTurn) then 
      {StartTBT}
   else
      {StartSim}
   end


end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                   %%%
%%%              Notes                %%%
%%%                                   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*
   
   ctrl+f {TBTActions PPL Round Id+1 {Record.adjoinAt {List.nth EJL Id} surface (Input.turnSurface-1)}} : 
   Pas sur du Input.turnSurface-1... C'est car on dit qu'une fois a la surface on y a deja passe 1 tour

   Ma procedure Radio, broadcast et envoi a la GUI en meme temps, ca pose probleme ? 

 
 
 
 
 
*/