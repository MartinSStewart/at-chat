module Discord.Id exposing
    ( AchievementId
    , ApplicationId
    , AttachmentId
    , ChannelId
    , CustomEmojiId
    , GuildId
    , Id(..)
    , MessageId
    , OverwriteId
    , RoleId
    , StickerId
    , StickerPackId
    , TeamId
    , UserId
    , WebhookId
    , decodeId
    , encodeId
    , fromUInt64
    , toString
    , toUInt64
    )

{-| In Discord's documentation these are called snowflakes. They are always 64bit positive integers.
-}

import Json.Decode as JD
import Json.Encode as JE
import UInt64 exposing (UInt64)


type Id idType
    = Id UInt64


type MessageId
    = MessageId Never


type UserId
    = UserId Never


type RoleId
    = RoleId Never


type ChannelId
    = ChannelId Never


type GuildId
    = GuildId Never


type WebhookId
    = WebhookId Never


type AttachmentId
    = AttachmentId Never


type CustomEmojiId
    = CustomEmojiId Never


type ApplicationId
    = ApplicationId Never


type OverwriteId
    = OverwriteId Never


type TeamId
    = TeamId Never


type AchievementId
    = AchievementId Never


type StickerId
    = StickerId Never


type StickerPackId
    = StickerPackId Never


encodeId : Id idType -> JE.Value
encodeId id =
    JE.string (toString id)


decodeId : JD.Decoder (Id idType)
decodeId =
    JD.andThen
        (UInt64.fromString
            >> Maybe.map (Id >> JD.succeed)
            >> Maybe.withDefault (JD.fail "Invalid snowflake ID.")
        )
        JD.string


toString : Id idType -> String
toString =
    toUInt64 >> UInt64.toString


toUInt64 : Id idType -> UInt64
toUInt64 (Id id) =
    id


fromUInt64 : UInt64 -> Id idType
fromUInt64 =
    Id
