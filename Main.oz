functor
import
   System
   GUI
   Input
   PlayerManager
define


   /**************************************
    * Variables Utiles
    *************************************/


   /*
    * Port de l'interface graphique
    */
   GUIP

   /*
    * Liste des ports des joueurs (Ordre Id)
    */
   PlayerPortList

   /*
    * List<int> dont chaque element est le nombre de tour avant que le joueur puisse replonger (ordre correspond a l'Id)
    * SurfaceJoueursList = [2 -1 1 0 ...] : 
    * -1 = En plonge
    *  0 = Peut plonger
    *  1 = Un tour restant
    *  2 = ...
    */
   SurfaceJoueursList

   /*
    * List<int> dont chaque element indique si le joueur est vivant (ordre correspond a l'Id)
    * VieJoueursList = [0 1 0 1 ...] : 
    * 0 = Mort
    * 1 = Vivant
    */
   VieJoueursList


   /**************************************
    * Fonctions et Procedures Utiles
    *************************************/


   /*
   * Renvoi une liste egale a List ou l'element a l'indice Ind a ete modifie par Elem
   */
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


   /*
    * Initialise la liste des ports de jouers dans PlayerPortList : 
    * Chaque joueur est d'un certain Kind et est initialise avec un Id unique et une Color
    * PlayerManager.playerGenerator renvoi le numero de port qui sera stocke
    */
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
    * Initialise la liste des etats de surface des jouers (ordre Id)
    */
   fun{InitSurfaceJoueursList}
      fun{ISJLrec P}
         case P
         of H|T then
            0|{ISJLrec T}
         else
            nil
         end
      end
   in
      {ISJLrec Input.players}
   end


   /*
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
      {IVJLrec Input.players}
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
      /*
       * Turn by turn Actions : 
       * PPL = PlayerPortList qui sera parcouru pour donner la main au joueur dans l'ordre des Id
       * Id = Id du joueur en cours
       * SJL = EtatJoueurList
       */
      proc{TBTActions PPL SJL VJL Id} % Recursion sur les joueurs (ordre PlayerPortList est dans l'ordre des Ids)
         case PPL
         of PlayerPort|T then % Actions pour un tour d'un joueur

            {System.show '---------- Debut du tour joueur ----------'}

            %%%%  -- Pt.0 --  %%% Si le joueur est mort, on skip

            {System.show '--------------- Pt.0'}

            local
               DeadAnswer
            in
               {Send PlayerPort isDead(DeadAnswer)}
               {Wait DeadAnswer}
               if(DeadAnswer == true) then
                  {TBTActions T SJL {AdjoinListAt VJL Id 0} Id+1}
               end
            end

            %%%%  -- Pt.1 --  %%%

            {System.show '--------------- Pt.1'}

            local
               NiveauSurface = {List.nth SJL Id}
            in
               if(NiveauSurface > 0) then % Variable Round inutile car au 1er Round, tout le monde a sa surface a 0
                  {TBTActions T {AdjoinListAt SJL Id (NiveauSurface-1)} VJL Id+1} % Joueur doit encore passer un tour en surface
               end            
            end

            %%%%  -- Pt.2 --  %%%

            {System.show '--------------- Pt.2'}

            if({List.nth SJL Id} == 0) then
               {Send PlayerPort dive}
            end

            %%%%  -- Pt.3 --  %%%

            {System.show '--------------- Pt.3'}

            local
               MoveId MovePos MoveDir
            in
               {Send PlayerPort move(MoveId MovePos MoveDir)}
               {Wait MoveId}
               {Wait MovePos}
               {Wait MoveDir}

               %%%%  -- Pt.4 --  %%%

               {System.show '--------------- Pt.4'}

               local
                  NiveauSurface = {List.nth SJL Id}
               in
                  if(MoveDir == surface) then
                     {Radio saySurface(MoveId)}
                     {TBTActions T {AdjoinListAt SJL Id (NiveauSurface-1)} VJL Id+1}
                  end
               end

               %%%%  -- Pt.5 --  %%%

               {System.show '--------------- Pt.5'}
               
               {Radio sayMove(MoveId MoveDir)}

            end

            %%%%  -- Pt.6 --  %%%

            {System.show '--------------- Pt.6'}

            local
               ChargeId ChargeItem
            in
               {Send PlayerPort chargeItem(ChargeId ChargeItem)}
               {Wait ChargeId}
               {Wait ChargeItem}

               if(ChargeItem \= null) then
                  {Radio sayCharge(ChargeId ChargeItem)}
               end
            end

            %%%%  -- Pt.7 --  %%%

            {System.show '--------------- Pt.7'}

            local
               FireId FireItem
            in
               {Send PlayerPort fireItem(FireId FireItem)} %FireItem <fireitem>
               {Wait FireId}
               {Wait FireItem}

               case FireItem
               of mine(Position) then 

                  {System.show '------------------ Pt.7 : Mine'} 

                  {Radio sayMinePlaced(FireId)}
               [] missile(Position) then

                  {System.show '------------------ Pt.7 : Missile'}   

                  for Port in PlayerPortList do
                     local
                        MissileMessage
                     in 
                        {Send Port sayMissileExplode(FireId Position MissileMessage)}
                        {Wait MissileMessage}
                        if(MissileMessage \= null) then 
                           {Radio MissileMessage}
                        end
                     end
                  end
               [] drone(Dim Num) then % drone(row <x>) / drone(column <y>)

                  {System.show '------------------ Pt.7 : Drone'} 

                  for Port in PlayerPortList do
                     local
                        PassingId PassingAnswer
                     in 
                        {Send Port sayPassingDrone(drone(Dim Num) PassingId PassingAnswer)}
                        {Wait PassingId}
                        {Wait PassingAnswer}

                        {Send PlayerPort sayAnswerDrone(drone(Dim Num) PassingId PassingAnswer)}
                     end
                  end
               [] sonar then 

                  {System.show '------------------ Pt.7 : Sonar'} 

                  for Port in PlayerPortList do
                     local
                        SonarId SonarPos
                     in 
                        {Send Port sayPassingSonar(SonarId SonarPos)}
                        {Wait SonarId}
                        {Wait SonarPos}

                        {Send PlayerPort sayAnswerSOnar(SonarId SonarPos)}
                     end
                  end
               else % null ou autre 

                  {System.show '------------------ Pt.7 : Pas de tir'} % Pas d'item tire

               end
            end

            %%%%  -- Pt.8 --  %%% 

            {System.show '--------------- Pt.8'}

            local
               MineId MinePosition
            in
               {Send PlayerPort fireMine(MineId MinePosition)} % J'envoi la requete, le player est honette, si il n'a pas de mine
               {Wait MineId} % Tjrs bound
               {Wait MinePosition} % MinePosition : <mine> ::= null | <position>. Si null, pas d'explosion

               if(MinePosition \= null) then
                  for Port in PlayerPortList do
                     local
                        MineMessage
                     in 
                        {Send Port sayMineExplode(MineId MinePosition MineMessage)}
                        {Wait MineMessage}
                        if(MineMessage \= null) then 
                           {Radio MineMessage}
                        end
                     end
                  end
               end
            end

            %%%%  -- Pt.9 --  %%%

            {System.show '--------------- Pt.9'}
            {System.show '---------- Fin du tour joueur ----------'}

            {TBTActions T SJL VJL Id+1} % Recursion du tour pour le prochain joueur

         else

         local
            Vivant = {SumList SJL}
         in
            if(Vivant == 1) then

               {System.show '--- Partie termine '}

               skip
            else

               {System.show '------ Fin du Round ------'}
               {Wait Vivant}
               {System.show '%%% Nombre de joueurs vivant : '}
               {System.show Vivant}
               {System.show '------ Lancement nouveau Round ------'}

               {TBTActions PlayerPortList SJL VJL 1} % Chaque jouer a joue, nouveau round
            end
         end



         end
      end
   in
      {TBTActions PlayerPortList SurfaceJoueursList VieJoueursList 1} 
   end


   /*
    * Partie en simultane
    */
   proc{StartSim}
      skip
   end


in
   

   /**************************************
    *            --- Main ---
    *************************************/

   % Cree l'interface graphique
   {System.show '- Lancement de la GUI -'}
   GUIP = {GUI.portWindow} % Recuperation du port de l'interface
   {Send GUIP buildWindow} % Lancement de l'interface

   {System.show '- Initialisations du jeux -'}
   PlayerPortList = {InitPlayerPortList} % Initialise la liste des ports des joueurs dans l'ordre des Id
   SurfaceJoueursList = {InitSurfaceJoueursList} % Initialise le tuple des etats des joueurs dans l'ordre des Ids
   VieJoueursList = {InitVieJoueursList}
   {SetUpPlayers} % Demande a chaque joueur de choisir un point de depart

   if(Input.isTurnByTurn) then
      {System.show '--- Lancement de la partie en TPT ---'}
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
   
   ctrl+f {TBTActions PPL Id+1 {AdjoinListAt SJL Id (Input.turnSurface-1)}} : 
   Pas sur du Input.turnSurface-1... C'est car on dit qu'une fois a la surface on y a deja passe 1 tour

   Ma procedure Radio, broadcast et envoi a la GUI en meme temps, ca pose probleme ? 

   Dans le Pt.8, c'est la main qui doit verifier si le joueur a deja place une mine ? Ou j'envoi et le joueur est honnete
 
   Trouver un moyen de finir la boucle de TPT ? Quand il ne reste plus qu'un joueur en jeux
 
 
*/