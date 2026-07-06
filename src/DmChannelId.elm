module DmChannelId exposing
    ( DmChannelId
    , GuildOrFullDmId(..)
    , channelIdFromString
    , channelIdFromUserIds
    , channelIdToString
    , otherUserId
    , userIdsFromChannelId
    )

import Id exposing (ChannelId, GuildId, Id, UserId)


{-| OpaqueVariants
-}
type DmChannelId
    = DmChannelId (Id UserId) (Id UserId)


type GuildOrFullDmId
    = GuildOrFullDmId_Guild (Id GuildId) (Id ChannelId)
    | GuildOrFullDmId_Dm DmChannelId


channelIdFromUserIds : Id UserId -> Id UserId -> DmChannelId
channelIdFromUserIds userIdA userIdB =
    DmChannelId
        (min (Id.toInt userIdA) (Id.toInt userIdB) |> Id.fromInt)
        (max (Id.toInt userIdA) (Id.toInt userIdB) |> Id.fromInt)


userIdsFromChannelId : DmChannelId -> ( Id UserId, Id UserId )
userIdsFromChannelId (DmChannelId userIdA userIdB) =
    ( userIdA, userIdB )


channelIdToString : DmChannelId -> String
channelIdToString (DmChannelId userIdA userIdB) =
    Id.toString userIdA ++ "-" ++ Id.toString userIdB


channelIdFromString : String -> Result () DmChannelId
channelIdFromString text =
    case String.split "-" text of
        [ idA, idB ] ->
            case ( Id.fromString idA, Id.fromString idB ) of
                ( Just idA2, Just idB2 ) ->
                    channelIdFromUserIds idA2 idB2 |> Ok

                _ ->
                    Err ()

        _ ->
            Err ()


otherUserId : Id UserId -> DmChannelId -> Maybe (Id UserId)
otherUserId userId (DmChannelId userIdA userIdB) =
    if userId == userIdA then
        Just userIdB

    else if userId == userIdB then
        Just userIdA

    else
        Nothing
