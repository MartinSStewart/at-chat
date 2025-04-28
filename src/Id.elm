module Id exposing
    ( ChannelId(..)
    , GuildId(..)
    , Id(..)
    , InviteLinkId(..)
    , UserId(..)
    , fromInt
    , fromString
    , nextId
    , toString
    , toUInt64
    )

import List.Extra
import SeqDict exposing (SeqDict)
import UInt64 exposing (UInt64)


type UserId
    = UserId Never


type GuildId
    = GuildId Never


type ChannelId
    = ChannelId Never


type InviteLinkId
    = InviteLinkId Never


type Id a
    = Id UInt64


nextId : SeqDict (Id a) b -> Id a
nextId dict =
    SeqDict.keys dict
        |> List.Extra.maximumWith (\(Id a) (Id b) -> UInt64.compare a b)
        |> Maybe.withDefault (Id UInt64.zero)
        |> toUInt64
        |> UInt64.increment
        |> Id


toUInt64 : Id a -> UInt64
toUInt64 (Id a) =
    a


fromInt : Int -> Id a
fromInt int =
    UInt64.fromInt int |> Id


fromString : String -> Maybe (Id a)
fromString string =
    UInt64.fromString string |> Maybe.map Id


toString : Id a -> String
toString (Id a) =
    UInt64.toString a
