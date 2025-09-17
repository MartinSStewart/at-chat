module OneOrGreater exposing (OneOrGreater, increment, one, plus, toInt)


type OneOrGreater
    = OneOrGreater Int


one : OneOrGreater
one =
    OneOrGreater 1


increment : OneOrGreater -> Int
increment (OneOrGreater a) =
    a + 1


toInt : OneOrGreater -> Int
toInt (OneOrGreater a) =
    a


plus : Int -> OneOrGreater -> OneOrGreater
plus int (OneOrGreater a) =
    OneOrGreater (int + a)
