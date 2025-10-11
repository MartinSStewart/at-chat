module Unsafe exposing
    ( channelName
    , emailAddress
    , guildName
    , personName
    , uint64
    )

import ChannelName exposing (ChannelName)
import EmailAddress exposing (EmailAddress)
import GuildName exposing (GuildName)
import PersonName exposing (PersonName)
import UInt64


personName : String -> PersonName
personName a =
    case PersonName.fromString a of
        Ok b ->
            b

        Err _ ->
            unreachable 0


guildName : String -> GuildName
guildName a =
    case GuildName.fromString a of
        Ok b ->
            b

        Err _ ->
            unreachable 0


channelName : String -> ChannelName
channelName a =
    case ChannelName.fromString a of
        Ok b ->
            b

        Err _ ->
            unreachable 0


emailAddress : String -> EmailAddress
emailAddress a =
    case EmailAddress.fromString a of
        Just b ->
            b

        Nothing ->
            unreachable 0


uint64 : String -> UInt64.UInt64
uint64 text =
    case UInt64.fromString text of
        Just b ->
            b

        Nothing ->
            unreachable 0


{-| Be very careful when using this!
-}
unreachable : Int -> a
unreachable v =
    unreachable (causeStackOverflow v)


causeStackOverflow : Int -> Int
causeStackOverflow value =
    causeStackOverflow value + 1
