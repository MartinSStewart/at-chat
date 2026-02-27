module Evergreen.V124.Discord.Id exposing (..)

import UInt64


type UserId
    = UserId Never


type Id idType
    = Id UInt64.UInt64


type GuildId
    = GuildId Never


type ChannelId
    = ChannelId Never


type PrivateChannelId
    = PrivateChannelId Never


type MessageId
    = MessageId Never


type RoleId
    = RoleId Never


type AttachmentId
    = AttachmentId Never


type CustomEmojiId
    = CustomEmojiId Never


type WebhookId
    = WebhookId Never


type ApplicationId
    = ApplicationId Never


type StickerId
    = StickerId Never


type StickerPackId
    = StickerPackId Never
