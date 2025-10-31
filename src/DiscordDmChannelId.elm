module DiscordDmChannelId exposing
    ( DiscordDmChannelId
    , chattingWithYourself
    , currentAndOtherUserId
    , fromUserIds
    , toHtmlId
    , toPath
    , toUserIds
    )

{-| OpaqueVariants
-}

import Discord.Id
import Effect.Browser.Dom as Dom exposing (HtmlId)
import SeqDict exposing (SeqDict)
import UInt64 exposing (UInt64)


type DiscordDmChannelId
    = DiscordDmChannelId (Discord.Id.Id Discord.Id.UserId) (Discord.Id.Id Discord.Id.UserId)


maxUInt64 : UInt64 -> UInt64 -> UInt64
maxUInt64 a b =
    case UInt64.compare a b of
        LT ->
            b

        _ ->
            a


minUInt64 : UInt64 -> UInt64 -> UInt64
minUInt64 a b =
    case UInt64.compare a b of
        GT ->
            b

        _ ->
            a


fromUserIds : Discord.Id.Id Discord.Id.UserId -> Discord.Id.Id Discord.Id.UserId -> DiscordDmChannelId
fromUserIds userIdA userIdB =
    DiscordDmChannelId
        (minUInt64 (Discord.Id.toUInt64 userIdA) (Discord.Id.toUInt64 userIdB) |> Discord.Id.Id)
        (maxUInt64 (Discord.Id.toUInt64 userIdA) (Discord.Id.toUInt64 userIdB) |> Discord.Id.Id)


toUserIds : DiscordDmChannelId -> ( Discord.Id.Id Discord.Id.UserId, Discord.Id.Id Discord.Id.UserId )
toUserIds (DiscordDmChannelId userIdA userIdB) =
    ( userIdA, userIdB )


toPath : DiscordDmChannelId -> List String
toPath (DiscordDmChannelId userIdA userIdB) =
    [ Discord.Id.toString userIdA, Discord.Id.toString userIdB ]


toHtmlId : String -> DiscordDmChannelId -> HtmlId
toHtmlId prefix (DiscordDmChannelId userIdA userIdB) =
    prefix ++ "_" ++ Discord.Id.toString userIdA ++ "_" ++ Discord.Id.toString userIdB |> Dom.id


chattingWithYourself : DiscordDmChannelId -> Bool
chattingWithYourself (DiscordDmChannelId userIdA userIdB) =
    userIdA == userIdB


currentAndOtherUserId :
    DiscordDmChannelId
    -> SeqDict (Discord.Id.Id Discord.Id.UserId) a
    -> { currentUserId : Discord.Id.Id Discord.Id.UserId, otherUserId : Discord.Id.Id Discord.Id.UserId }
currentAndOtherUserId (DiscordDmChannelId userIdA userIdB) linkedUserIds =
    if SeqDict.member userIdA linkedUserIds then
        { currentUserId = userIdA, otherUserId = userIdB }

    else
        { currentUserId = userIdB, otherUserId = userIdA }
