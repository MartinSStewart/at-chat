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
    = Id Int


nextId : SeqDict (Id a) b -> Id a
nextId dict =
    case SeqDict.keys dict |> List.Extra.maximumWith (\(Id a) (Id b) -> compare a b) of
        Just (Id value) ->
            Id (value + 1)

        Nothing ->
            Id 0


fromInt : Int -> Id a
fromInt =
    Id


fromString : String -> Maybe (Id a)
fromString string =
    String.toInt string |> Maybe.map Id


toString : Id a -> String
toString (Id a) =
    String.fromInt a
