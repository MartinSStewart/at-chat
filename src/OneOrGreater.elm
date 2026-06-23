module OneOrGreater exposing
    ( OneOrGreater(..)
    , decrement
    , eight
    , five
    , four
    , fromInt
    , increment
    , nine
    , one
    , plus
    , six
    , three
    , toInt
    , toString
    , twelve
    , two
    )

{-| A integer that's guaranteed to be 1 or a value greater than 1
-}


{-| OpaqueVariants
-}
type OneOrGreater
    = OneOrGreater Int


one : OneOrGreater
one =
    OneOrGreater 1


two : OneOrGreater
two =
    OneOrGreater 2


three : OneOrGreater
three =
    OneOrGreater 3


four : OneOrGreater
four =
    OneOrGreater 4


five : OneOrGreater
five =
    OneOrGreater 5


six : OneOrGreater
six =
    OneOrGreater 6


eight : OneOrGreater
eight =
    OneOrGreater 8


nine : OneOrGreater
nine =
    OneOrGreater 9


twelve : OneOrGreater
twelve =
    OneOrGreater 12


increment : OneOrGreater -> OneOrGreater
increment (OneOrGreater a) =
    OneOrGreater (a + 1)


decrement : OneOrGreater -> Maybe OneOrGreater
decrement (OneOrGreater a) =
    if a > 0 then
        OneOrGreater (a - 1) |> Just

    else
        Nothing


toInt : OneOrGreater -> Int
toInt (OneOrGreater a) =
    a


fromInt : Int -> Maybe OneOrGreater
fromInt int =
    if int > 0 then
        OneOrGreater int |> Just

    else
        Nothing


plus : OneOrGreater -> OneOrGreater -> OneOrGreater
plus (OneOrGreater a) (OneOrGreater b) =
    OneOrGreater (a + b)


toString : OneOrGreater -> String
toString (OneOrGreater a) =
    String.fromInt a
