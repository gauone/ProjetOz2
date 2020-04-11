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
    * -1 = En plonge (Inutile car on ne sait pas quand un sous-marin plonge)
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
      {System.show '-------------------- Lancement de SumList'}
      {SLacc List 0}
   end


   /*
    * Renvoi la liste List sans l'indice I
    */
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
    * Envoi le Message sur la radio (donc a tout les ports)
    */
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
    * InformMissile envoi les informations du missile a chaque sub dans l'ordre de PPL (ordre Id)
    * Retourne une MaJ de la VieJoueurList
    * PPL = PlayerPortList
    * FID = FireId
    * MP = MissilePosition
    * VJL = VieJoueurList (car c'est la premiere utilisation d'une subVJL)
    */
   fun{InformMissile PPL FID MP VJL}
      local
         MissileMessage DeadAnswer
      in 
         case PPL
         of Port|T then
            {Send Port isDead(DeadAnswer)}
            {Wait DeadAnswer}
            if(DeadAnswer == false) then
               {Send Port sayMissileExplode(FID MP MissileMessage)}
               {Wait MissileMessage}

               if(MissileMessage \= null) then
                  {Radio MissileMessage}

                  case MissileMessage
                  of sayDeath(id(color:ActualColor id:ActualId name:ActualName)) then % Note la mort d'un joueur
                     {Send GUIP lifeUpdate(id(color:ActualColor id:ActualId name:ActualName) 0)}
                     {System.show '-------------------- Death'}
                     {System.show '-------------------- Mine Position : '}
                     {Wait MP}
                     {System.show MP}
                     
                     {Send GUIP removePlayer(id(color:ActualColor id:ActualId name:ActualName))}
                     {InformMissile T FID MP {AdjoinListAt VJL ActualId 0}}
                  [] sayDamageTaken(ActualId ActualDamage ActualLifeLeft) then
                     {System.show '-------------------- Damage Taken : '}
                     {System.show ActualLifeLeft} 
                     {Send GUIP lifeUpdate(ActualId ActualLifeLeft)}
                     {InformMissile T FID MP VJL}
                  end
               else
                  {InformMissile T FID MP VJL}
               end
            else
               {InformMissile T FID MP VJL}
            end
         else
            VJL
         end
      end
   end


   /*
    * SubVJLMine = {InformMine PlayerPortList MineId MinePosition SubVJLMissile}
    *
    * InformMine envoi les informations de la mine a chaque sub dans l'ordre de PPL (ordre Id)
    * Retourne une MaJ de la VieJoueurList
    * PPL = PlayerPortList
    * MID = MineId
    * MP = MinePosition
    * SVJLM = SubVJLMissile (car c'est le dernier cas ou il y aurait pu y avoir un mort)
    */
   fun{InformMine PPL MID MP SVJLM}
      local
         MineMessage DeadAnswer
      in 
         case PPL
         of Port|T then
            {Send Port isDead(DeadAnswer)}
            {Wait DeadAnswer}
            if(DeadAnswer == false) then
               {Send Port sayMineExplode(MID MP MineMessage)}
               {Wait MineMessage}

               if(MineMessage \= null) then
                  {Radio MineMessage}

                  case MineMessage
                  of sayDeath(id(color:ActualColor id:ActualId name:ActualName)) then % Note la mort d'un joueur
                     {System.show '-------------------- Death'}
                     {System.show '-------------------- Mine Position : '}
                     {Wait MP}
                     {System.show MP}

                     {Send GUIP lifeUpdate(id(color:ActualColor id:ActualId name:ActualName) 0)}
                     {Send GUIP removePlayer(id(color:ActualColor id:ActualId name:ActualName))}
                     {InformMine T MID MP {AdjoinListAt SVJLM ActualId 0}}
                  [] sayDamageTaken(ActualId ActualDamage ActualLifeLeft) then
                     {System.show '-------------------- Damage Taken : '}
                     {System.show ActualLifeLeft} 
                     {Send GUIP lifeUpdate(ActualId ActualLifeLeft)}
                     {InformMine T MID MP SVJLM}                  
                  end

               else
                  {InformMine T MID MP SVJLM}
               end
            else
               {InformMine T MID MP SVJLM}
            end
         else
            SVJLM
         end
      end
   end


   /*
    * Partie tour par tour
    */
   proc{StartTBT}
      /*
       * Turn by turn Actions : 
       * PPL = PlayerPortList qui sera parcouru pour donner la main au joueur dans l'ordre des Id
       * Id = Id du joueur en cours
       * SJL = SurfaceJoueurList
       */
      proc{TBTActions PPL SJL VJL Id} % Recursion sur les joueurs (ordre PlayerPortList est dans l'ordre des Ids)
         local
            SubVJLMissile SubVJLMine DeadAnswer MoveId MovePos MoveDir ChargeId ChargeItem FireId FireItem MineId MinePosition
         in
            %%%%%%%%%%%%%%%%%%%%

            case PPL
            of PlayerPort|T then % Actions pour un tour d'un joueur

               {System.show '-------------------- Debut du tour joueur'}

               %%%%  -- Pt.0 --  %%%%
               /*
               * Verifie si il ne reste qu'un joueur.
               * Sinon, verifie si le joueur est mort.
               * Si oui, on passe au joueur prochain
               */

               {System.show '-------------------- Pt.0'}

               if({SumList VJL} == 1) then
                  {System.show '-------------------- Partie terminee '}
                  {TBTActions nil SJL VJL 1}
               else

                  {Send PlayerPort isDead(DeadAnswer)}
                  {System.show '-------------------- Joueur est il vivant ?'}
                  {Wait DeadAnswer}
                  if(DeadAnswer == true) then
                     {System.show '-------------------- Non il est mort !'}
                     %{Radio sayDead(ID)} Jsp comment recuperer l'ID complet mais je pense que cette fonction n'est plus utile
                     {TBTActions T SJL {AdjoinListAt VJL Id 0} Id+1}
                  else

                     {System.show '-------------------- Oui !'}

                     %%%%  -- Pt.1 --  %%%%
                     /*
                     * Verifie si le sous-marin peut jouer (s'il n'est plus a la surface).
                     * Si le sous-marin est a la surface : Pt.9.
                     */

                     {System.show '-------------------- Pt.1'}

                     if({List.nth SJL Id} > 0) then % Variable Round inutile car au 1er Round, tout le monde a sa surface a 0
                        {TBTActions T {AdjoinListAt SJL Id ({List.nth SJL Id}-1)} VJL Id+1} % Joueur doit encore passer un tour en surface
                     else
                        %%%%  -- Pt.2 --  %%%%
                        /*
                        * S'il s'agit du premier tour, ou si au tour precedent le sous-marin a fait surface : 
                        * Envoie le message de plongee au sous-marin
                        */

                        {System.show '-------------------- Pt.2'}

                        if({List.nth SJL Id} == 0) then
                           {Send PlayerPort dive}
                        end

                        %%%%  -- Pt.3 --  %%%%
                        /*
                        * Demande au sous-marin de choisir sa direction.
                        * Si la direction n'est pas surface : Pt.5
                        */

                        {System.show '-------------------- Pt.3'}


                        {Send PlayerPort move(MoveId MovePos MoveDir)}
                        {Wait MoveId}
                        {Wait MovePos}
                        {Wait MoveDir}

                        %%%%  -- Pt.4 --  %%%%
                        /*
                        * La surface a ete choisie, le tour du joueur s'arrete et est compte comme le premier tour passe a la surface.
                        * L'informations que ce joueur a fait surface est diffusee par la radio.
                        * Le sous-marin reste un total de tours Input.turnSurface a la surface avant de continuer
                        */

                        {System.show '-------------------- Pt.4'}

                        if(MoveDir == surface) then
                           {Radio saySurface(MoveId)}
                           {Send GUIP surface(MoveId)}
                           {TBTActions T {AdjoinListAt SJL Id (Input.turnSurface-1)} VJL Id+1}
                        else

                           %%%%  -- Pt.5 --  %%%%
                           /*
                           * La direction choisie est diffusee par la radio.
                           */

                           {System.show '-------------------- Pt.5'}
                           
                           {Radio sayMove(MoveId MoveDir)}
                           {Send GUIP movePlayer(MoveId MovePos)}


                           %%%%  -- Pt.6 --  %%%%
                           /*
                           * Le sous-marin est desormais autorise a charger un objet.
                           * Si la reponse contient des informations sur un nouveau item, l'information est diffusee par la radio.
                           */

                           {System.show '-------------------- Pt.6'}

                           {Send PlayerPort chargeItem(ChargeId ChargeItem)}
                           {Wait ChargeId}
                           {Wait ChargeItem}

                           if(ChargeItem \= null) then
                              {Radio sayCharge(ChargeId ChargeItem)}
                           end

                           %%%%  -- Pt.7 --  %%%%
                           /*
                           * Le sous-marin est desormais autorise a tirer un objet.
                           * Si la reponse contient des informations sur un objet tire l'information est diffusee par la radio.
                           */

                           {System.show '-------------------- Pt.7'}

                           {Send PlayerPort fireItem(FireId FireItem)} %FireItem <fireitem>
                           {Wait FireId}
                           {Wait FireItem}

                           case FireItem
                           of mine(MinePosition) then 

                              {System.show '-------------------- Pt.7 : Mine'} 

                              {Radio sayMinePlaced(FireId)}
                              {Send GUIP putMine(FireId MinePosition)}

                              SubVJLMissile = VJL

                           [] missile(MissilePosition) then

                              {System.show '-------------------- Pt.7 : Missile'}
                              {Send GUIP explosion(FireId MissilePosition)}

                              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                              %%%%
                              %%%%     Morts potentiels
                              %%%%
                              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                              {System.show '-------------------- Lancement InforMissile'}

                              /*
                                 * Modification de VJL sans relancer la proc{TBTActions ...} m'oblige a faire des variables locales
                                 * J'utilise une function plutot qu'une boucle for pour les memes raisons
                                 */
                              SubVJLMissile = {InformMissile PlayerPortList FireId MissilePosition VJL}

                           [] drone(Dim Num) then % drone(row <x>) / drone(column <y>)

                              {System.show '-------------------- Pt.7 : Drone'} 
                              {Send GUIP drone(FireId drone(Dim Num))}

                              for Port in PlayerPortList do
                                 local
                                    PassingId PassingAnswer DeadAnswer
                                 in
                                    {Send Port isDead(DeadAnswer)}
                                    {Wait DeadAnswer}
                                    if(DeadAnswer == false) then
                                       {Send Port sayPassingDrone(drone(Dim Num) PassingId PassingAnswer)}
                                       {Wait PassingId}
                                       {Wait PassingAnswer}

                                       {System.show '-------------------- Pt.7 : sayPassingDrone binded'} 

                                       {Send PlayerPort sayAnswerDrone(drone(Dim Num) PassingId PassingAnswer)}
                                    end
                                 end
                              end

                              SubVJLMissile = VJL

                           [] sonar then 

                              {System.show '-------------------- Pt.7 : Sonar'}
                              {Send GUIP sonar(FireId)}

                              for Port in PlayerPortList do
                                 local
                                    SonarId SonarPos DeadAnswer
                                 in
                                    {Send Port isDead(DeadAnswer)}
                                    {Wait DeadAnswer}
                                    if(DeadAnswer == false) then
                                       {Send Port sayPassingSonar(SonarId SonarPos)}
                                       {Wait SonarId}
                                       {Wait SonarPos}

                                       {System.show '-------------------- Pt.7 : sayPassingSonar binded'} 

                                       {Send PlayerPort sayAnswerSonar(SonarId SonarPos)}
                                    end
                                 end
                              end

                              SubVJLMissile = VJL
                              
                           else % null ou autre 

                              SubVJLMissile = VJL
                              {System.show '-------------------- Pt.7 : Pas de tir'} % Pas d'item tire

                           end

                           %%%%  -- Pt.8 --  %%%
                           /*
                           * Le sous-marin est desormais autorise a faire exploser une mine.
                           * Si la reponse contient des informations sur l'explosion une mine, l'information est diffusee par la radio.
                           */

                           {System.show '-------------------- Pt.8'}

                           {Send PlayerPort fireMine(MineId MinePosition)} % J'envoi la requete, le player est honette, si il n'a pas de mine
                           {Wait MineId} % Tjrs bound

                           if(MineId \= null) then % En cas de suicide par un missile
                              {Wait MinePosition} % MinePosition : <mine> ::= null | <position>. Si null, pas d'explosion

                              if(MinePosition \= null) then 

                                 {System.show '-------------------- Lancement InforMine'}
                                 {Send GUIP explosion(MineId MinePosition)}
                                 {Send GUIP removeMine(MineId MinePosition)}

                                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                 %%%%
                                 %%%%     Morts potentiels
                                 %%%%
                                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                                 /*
                                 * Modification de VJL sans relancer la proc{TBTActions ...} m'oblige a faire des variables locales
                                 * J'utilise une function plutot qu'une boucle for pour les memes raisons
                                 */
                                 SubVJLMine = {InformMine PlayerPortList MineId MinePosition SubVJLMissile}

                                 {System.show '-------------------- Terminaison InforMine'}
                                 {System.show '-------------------- SubVJLMine : '}
                                 {Wait SubVJLMine}
                                 {System.show SubVJLMine}

                              else
                                 SubVJLMine = SubVJLMissile % Comme le recursion finale prend d'office SubVJLMine
                              end
                           else
                              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù Je pense que c'est ca en suicide
                              SubVJLMine = SubVJLMissile % Comme le recursion finale prend d'office SubVJLMine
                           end

                           %%%%  -- Pt.9 --  %%%
                           /*
                           * Le tour est termine pour ce sous-marin
                           */

                           {System.show '-------------------- Pt.9'}
                           {System.show '-------------------- Fin du tour joueur'}

                           {TBTActions T SJL SubVJLMine Id+1} % Recursion du tour pour le prochain joueur

                        end                        
                     end            
                  end
               end
            else
               if({SumList VJL} < 2) then % Parfois les 2 derniers joueurs meurent en meme temps
                  {System.show '-------------------- Fermeture de la partie'}
               else
                  {System.show '-------------------- Fin du Round'}

                  {Wait PPL}
                  {Wait SJL}
                  {Wait VJL}
                  {System.show '-------------------- Recaptilulatif du Round : PPL, SJL, VJL'}
                  {System.show PPL}
                  {System.show SJL}
                  {System.show VJL}

                  {System.show '-------------------- Lancement nouveau Round'}

                  % Je peux pas {Ecrase PlayerPortList VJL} sinon je perds la concordance entre mon Id local et la PPL 
                  {TBTActions PlayerPortList SJL VJL 1} % Chaque jouer a joue, nouveau round
               end
            end

               %%%%%%%%%%%%%%%%%%%%

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
   {System.show '-------------------- Lancement de la GUI'}
   GUIP = {GUI.portWindow} % Recuperation du port de l'interface
   {Send GUIP buildWindow} % Lancement de l'interface

   {System.show '-------------------- Initialisations du jeux'}
   PlayerPortList = {InitPlayerPortList} % Initialise la liste des ports des joueurs dans l'ordre des Id
   SurfaceJoueursList = {InitSurfaceJoueursList} % Initialise le tuple des etats des joueurs dans l'ordre des Ids
   VieJoueursList = {InitVieJoueursList}

   {System.show '- Valeur de PPL, SJL, VJL -'}
   {System.show PlayerPortList}
   {System.show SurfaceJoueursList}
   {System.show VieJoueursList}

   {SetUpPlayers} % Demande a chaque joueur de choisir un point de depart

   if(Input.isTurnByTurn) then
      {System.show '-------------------- Lancement de la partie en TPT'}
      {StartTBT}
   else
      {StartSim}
   end

   {System.show '-------------------- Fermeture de la main'}

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
 
   Joueur sous l'eau doit avoir surface ~1 \= -1

   {Wait Id} et seulement Id quand on en attend plusieurs car un sub mort ne repond que ca ! 

   ctrl+f %{Send GUIP lifeUpdate(ActualId Life)} Comment obtenir life ? : 
   Je ne sais pas comment obtenir Life facilement... a pensez plus tard

 
 
*/