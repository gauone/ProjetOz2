functor
import
    Player
    System
define
    Port = {Player.portPlayer blue 992}

    /*
     * Print le comportement de player suite a chaque message.
     * Le print est d abord le message envoye puis les differentes reponses a ce message en fct des differents cas testes
     */
    proc {TestRetrieving}
        {System.show 'lancement testRetrieving'}
        local
            ID Position
            {Send Port initPosition(ID Position)}
            ID2 Position2 Direction2 
            {Send Port move(ID2 Position2 Direction2)}
            ID3 KindItem3
            {Send Port chargeItem(ID3 KindItem3)}
            ID4 KindFire4
            {Send Port fireItem(ID4 KindFire4)}
            ID5 Mine5
            {Send Port fireMine(ID5 Mine5)}
            Answer6
            {Send Port isDead(Answer6)}

            Message11
            {Send Port sayMissileExplode( id(id:992 color:blue name:'Antoine') Position2 Message11)}%je me fais toucher a fond
            Message111
            {Send Port sayMissileExplode( id(id:992 color:blue name:'Antoine') pt(x:Position2.x y:Position2.y+1) Message111)}%je me fais toucher un peu
            Message112
            {Send Port sayMissileExplode( id(id:992 color:blue name:'Antoine') pt(x:Position2.x y:Position2.y+2) Message112)}%je me fais pas toucher
            Message113
            {Send Port sayMissileExplode( id(id:992 color:blue name:'Antoine') pt(x:Position2.x+1 y:Position2.y) Message113)}%je me fais toucher un peu
            Message114
            {Send Port sayMissileExplode( id(id:992 color:blue name:'Antoine') pt(x:Position2.x+2 y:Position2.y) Message114)}%je me fais pas toucher

            Message12
            {Send Port sayMineExplode( id(id:992 color:blue name:'Antoine') Position2 Message12)}%je me fais toucher a fond
            Message121
            {Send Port sayMineExplode( id(id:992 color:blue name:'Antoine') pt(x:Position2.x y:Position2.y+1) Message121)}%je me fais toucher un peu
            Message122
            {Send Port sayMineExplode( id(id:992 color:blue name:'Antoine') pt(x:Position2.x y:Position2.y+2) Message122)}%je me fais pas toucher
            Message123
            {Send Port sayMineExplode( id(id:992 color:blue name:'Antoine') pt(x:Position2.x+1 y:Position2.y) Message123)}%je me fais toucher un peu
            Message124
            {Send Port sayMineExplode( id(id:992 color:blue name:'Antoine') pt(x:Position2.x+2 y:Position2.y) Message124)}%je me fais pas toucher
            
            ID13 Answer13 
            {Send Port sayPassingDrone(drone(row Position2.x) ID13 Answer13)}%un drone passe au dessus de moi en x
            ID14 Answer131
            {Send Port sayPassingDrone(drone(column Position2.y) ID14 Answer131)}%un drone passe au dessus de moi en y
            ID15 Answer132
            {Send Port sayPassingDrone(drone(row Position2.x-1) ID15 Answer132)}%un drone passe a coté de moi en x
            ID16 Answer133
            {Send Port sayPassingDrone(drone(column Position2.y-1) ID16 Answer133)}%un drone passe a coté de moi en y
            
            ID17 Answer14
            {Send Port sayPassingSonar( ID17 Answer14)}%reponse doit etre un coordinee vraie l autre fausse
            
            ListOfVariable = [initPosition ID Position move ID2 Position2 Direction2 chargeItem ID3 KindItem3 fireItem ID4 KindFire4 fireMine ID5 Mine5 isDead Answer6 sayMissileExplode Message11 Message111 Message112 Message113 Message114 sayMineExplode Message12 Message121 Message122 Message123 Message124 sayPassingDrone ID13 Answer13 ID14 Answer131 ID15 Answer132 ID16 Answer133 sayPassingSonar ID17 Answer14 ]

            proc {Loop List}
                case List
                of H|T then
                    if {IsFree H} then {System.show unbound}
                    else {System.show H} {Loop T}
                    end
                [] nil then skip
                end
            end
        in
            {System.show delay}
            {Time.delay 1000}
            {Loop ListOfVariable}
            
        end
        {System.show fini}
    end
in
    {TestRetrieving}
end
