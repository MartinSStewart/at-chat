module IdString exposing
    ( IdString(..)
    , changeType
    , codec
    , fromString
    , toString
    )

{-| OpaqueVariants
-}

import Codec exposing (Codec)


type IdString a
    = IdString String


fromString : String -> IdString a
fromString =
    IdString


toString : IdString a -> String
toString (IdString a) =
    a


changeType : IdString a -> IdString b
changeType (IdString a) =
    IdString a


codec : Codec (IdString a)
codec =
    Codec.map fromString toString Codec.string
