module Evergreen.V368.X25519 exposing (..)


type alias Key =
    { w0 : Int
    , w1 : Int
    , w2 : Int
    , w3 : Int
    , w4 : Int
    , w5 : Int
    , w6 : Int
    , w7 : Int
    }


type PublicKey
    = PublicKey Key


type PrivateKey
    = PrivateKey Key
