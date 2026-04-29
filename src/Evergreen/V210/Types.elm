module Evergreen.V210.Types exposing (..)

import Array
import Browser
import Bytes
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V210.AiChat
import Evergreen.V210.ChannelName
import Evergreen.V210.Coord
import Evergreen.V210.CssPixels
import Evergreen.V210.CustomEmoji
import Evergreen.V210.Discord
import Evergreen.V210.DiscordAttachmentId
import Evergreen.V210.DiscordUserData
import Evergreen.V210.DmChannel
import Evergreen.V210.Editable
import Evergreen.V210.EmailAddress
import Evergreen.V210.Embed
import Evergreen.V210.Emoji
import Evergreen.V210.FileStatus
import Evergreen.V210.GuildName
import Evergreen.V210.Id
import Evergreen.V210.ImageEditor
import Evergreen.V210.Local
import Evergreen.V210.LocalState
import Evergreen.V210.Log
import Evergreen.V210.LoginForm
import Evergreen.V210.MembersAndOwner
import Evergreen.V210.Message
import Evergreen.V210.MessageInput
import Evergreen.V210.MessageView
import Evergreen.V210.NonemptyDict
import Evergreen.V210.NonemptySet
import Evergreen.V210.OneToOne
import Evergreen.V210.Pages.Admin
import Evergreen.V210.Pagination
import Evergreen.V210.PersonName
import Evergreen.V210.Ports
import Evergreen.V210.Postmark
import Evergreen.V210.Range
import Evergreen.V210.RichText
import Evergreen.V210.Route
import Evergreen.V210.SecretId
import Evergreen.V210.SessionIdHash
import Evergreen.V210.Slack
import Evergreen.V210.Sticker
import Evergreen.V210.TextEditor
import Evergreen.V210.ToBackendLog
import Evergreen.V210.Touch
import Evergreen.V210.TwoFactorAuthentication
import Evergreen.V210.Ui.Anim
import Evergreen.V210.Untrusted
import Evergreen.V210.User
import Evergreen.V210.UserAgent
import Evergreen.V210.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V210.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V210.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) Evergreen.V210.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) Evergreen.V210.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.LocalState.DiscordFrontendGuild
    , user : Evergreen.V210.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V210.SessionIdHash.SessionIdHash Evergreen.V210.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V210.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId) Evergreen.V210.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId) Evergreen.V210.CustomEmoji.CustomEmojiData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V210.Route.Route
    , windowSize : Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V210.Ports.NotificationPermission
    , pwaStatus : Evergreen.V210.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V210.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V210.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V210.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V210.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Evergreen.V210.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V210.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V210.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Evergreen.V210.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) Evergreen.V210.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) Evergreen.V210.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.UserSession.ToBeFilledInByBackend (Evergreen.V210.SecretId.SecretId Evergreen.V210.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V210.GuildName.GuildName (Evergreen.V210.UserSession.ToBeFilledInByBackend (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V210.Id.GuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Evergreen.V210.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V210.Id.DiscordGuildOrDmId_DmData (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V210.UserSession.SetViewing
    | Local_SetName Evergreen.V210.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V210.Id.GuildOrDmId (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V210.Id.GuildOrDmId (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId) (Evergreen.V210.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ThreadMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V210.Id.DiscordGuildOrDmId (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V210.Id.DiscordGuildOrDmId (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId) (Evergreen.V210.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId) (Evergreen.V210.Message.Message Evergreen.V210.Id.ThreadMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) Evergreen.V210.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V210.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V210.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V210.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V210.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V210.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V210.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Effect.Time.Posix Evergreen.V210.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V210.RichText.RichText (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))) Evergreen.V210.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Evergreen.V210.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId) Evergreen.V210.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V210.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V210.RichText.RichText (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))) Evergreen.V210.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Evergreen.V210.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId) Evergreen.V210.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) Evergreen.V210.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) Evergreen.V210.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.SecretId.SecretId Evergreen.V210.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) Evergreen.V210.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V210.LocalState.JoinGuildError
            { guildId : Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId
            , guild : Evergreen.V210.LocalState.FrontendGuild
            , owner : Evergreen.V210.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.Id.GuildOrDmId Evergreen.V210.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.Id.GuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.Id.GuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.Id.GuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V210.RichText.RichText (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))) (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Evergreen.V210.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V210.RichText.RichText (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V210.Id.DiscordGuildOrDmId_DmData (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V210.RichText.RichText (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) Evergreen.V210.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V210.SessionIdHash.SessionIdHash Evergreen.V210.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V210.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V210.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V210.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.ChannelName.ChannelName (Evergreen.V210.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId)
        (Evergreen.V210.NonemptyDict.NonemptyDict
            (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) Evergreen.V210.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Maybe (Evergreen.V210.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V210.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V210.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V210.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V210.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V210.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V210.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) (Evergreen.V210.Discord.OptionalData String) (Evergreen.V210.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
        (Evergreen.V210.MembersAndOwner.MembersAndOwner
            (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId) Evergreen.V210.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId) Evergreen.V210.CustomEmoji.CustomEmojiData)


type LocalMsg
    = LocalChange (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) Evergreen.V210.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Evergreen.V210.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V210.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V210.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V210.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V210.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V210.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V210.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V210.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V210.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V210.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels) (Maybe Evergreen.V210.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId) (Evergreen.V210.NonemptySet.NonemptySet Int))
    }


type ChannelSidebarMode
    = ChannelSidebarClosed
    | ChannelSidebarOpened
    | ChannelSidebarClosing
        { offset : Float
        }
    | ChannelSidebarOpening
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }


type alias UserOptionsModel =
    { name : Evergreen.V210.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V210.Local.Local LocalMsg Evergreen.V210.LocalState.LocalState
    , admin : Evergreen.V210.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId, Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V210.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V210.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V210.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) (Evergreen.V210.NonemptyDict.NonemptyDict (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Evergreen.V210.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V210.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V210.TextEditor.Model
    , profilePictureEditor : Evergreen.V210.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V210.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V210.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V210.SecretId.SecretId Evergreen.V210.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V210.Range.Range
                , direction : Evergreen.V210.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V210.NonemptyDict.NonemptyDict Int Evergreen.V210.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V210.NonemptyDict.NonemptyDict Int Evergreen.V210.Touch.Touch
        }


type LoginResult
    = LoginSuccess LoginData
    | LoginTokenInvalid Int
    | NeedsTwoFactorToken
    | NeedsAccountSetup


type ToFrontend
    = CheckLoginResponse (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | SignupsDisabledResponse
    | LoggedOutSession
    | AdminToFrontend Evergreen.V210.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V210.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V210.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V210.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V210.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V210.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V210.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V210.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V210.Ports.NotificationPermission
    , pwaStatus : Evergreen.V210.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V210.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V210.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V210.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V210.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V210.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V210.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V210.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId, Evergreen.V210.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V210.DmChannel.DmChannelId, Evergreen.V210.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId, Evergreen.V210.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId, Evergreen.V210.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V210.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V210.NonemptyDict.NonemptyDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V210.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V210.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V210.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V210.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) Evergreen.V210.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V210.DmChannel.DmChannelId Evergreen.V210.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) Evergreen.V210.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V210.OneToOne.OneToOne (Evergreen.V210.Slack.Id Evergreen.V210.Slack.ChannelId) Evergreen.V210.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V210.OneToOne.OneToOne String (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    , slackUsers : Evergreen.V210.OneToOne.OneToOne (Evergreen.V210.Slack.Id Evergreen.V210.Slack.UserId) (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
    , slackServers : Evergreen.V210.OneToOne.OneToOne (Evergreen.V210.Slack.Id Evergreen.V210.Slack.TeamId) (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    , slackToken : Maybe Evergreen.V210.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V210.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V210.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V210.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V210.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId, Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V210.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V210.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V210.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V210.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.LocalState.LoadingDiscordChannel (List Evergreen.V210.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V210.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId) Evergreen.V210.Sticker.StickerData
    , discordStickers : Evergreen.V210.OneToOne.OneToOne (Evergreen.V210.Discord.Id Evergreen.V210.Discord.StickerId) (Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId) Evergreen.V210.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V210.OneToOne.OneToOne Evergreen.V210.RichText.DiscordCustomEmojiIdAndName (Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V210.Postmark.ApiKey
    , serverSecret : Evergreen.V210.SecretId.SecretId Evergreen.V210.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V210.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V210.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V210.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V210.Route.Route
    | SelectedFilesToAttach ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) Evergreen.V210.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) Evergreen.V210.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V210.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage (Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V210.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V210.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V210.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V210.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V210.NonemptyDict.NonemptyDict Int Evergreen.V210.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V210.NonemptyDict.NonemptyDict Int Evergreen.V210.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V210.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V210.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V210.Editable.Msg Evergreen.V210.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V210.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V210.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute )
        { fileId : Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute )
        { fileId : Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V210.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V210.Id.AnyGuildOrDmId, Evergreen.V210.Id.ThreadRoute ) (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRouteWithMessage Evergreen.V210.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V210.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V210.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) Evergreen.V210.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V210.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V210.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId
        , otherUserId : Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V210.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRoute Evergreen.V210.MessageInput.Msg
    | MessageInputMsg Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRoute Evergreen.V210.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V210.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V210.Range.Range, Evergreen.V210.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V210.Range.Range, Evergreen.V210.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V210.Id.AnyGuildOrDmId Evergreen.V210.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V210.Id.Id Evergreen.V210.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V210.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V210.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V210.Untrusted.Untrusted Evergreen.V210.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V210.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V210.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V210.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.SecretId.SecretId Evergreen.V210.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V210.PersonName.PersonName Evergreen.V210.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V210.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V210.Slack.OAuthCode Evergreen.V210.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V210.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V210.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V210.Id.Id Evergreen.V210.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V210.EmailAddress.EmailAddress (Result Evergreen.V210.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V210.EmailAddress.EmailAddress (Result Evergreen.V210.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V210.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMaybeMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Result Evergreen.V210.Discord.HttpError Evergreen.V210.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V210.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Result Evergreen.V210.Discord.HttpError Evergreen.V210.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) (Result Evergreen.V210.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) (Result Evergreen.V210.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) (Result Evergreen.V210.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) (Result Evergreen.V210.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji (Result Evergreen.V210.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji (Result Evergreen.V210.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji (Result Evergreen.V210.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) Evergreen.V210.Emoji.EmojiOrCustomEmoji (Result Evergreen.V210.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V210.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V210.Discord.HttpError (List ( Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId, Maybe Evergreen.V210.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V210.Slack.CurrentUser
            , team : Evergreen.V210.Slack.Team
            , users : List Evergreen.V210.Slack.User
            , channels : List ( Evergreen.V210.Slack.Channel, List Evergreen.V210.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Result Effect.Http.Error Evergreen.V210.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.Discord.UserAuth (Result Evergreen.V210.Discord.HttpError Evergreen.V210.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Result Evergreen.V210.Discord.HttpError Evergreen.V210.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
        (Result
            Evergreen.V210.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId
                , members : List (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
                }
            , List
                ( Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId
                , { guild : Evergreen.V210.Discord.GatewayGuild
                  , channels : List Evergreen.V210.Discord.Channel
                  , icon : Maybe Evergreen.V210.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V210.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V210.Discord.Id Evergreen.V210.Discord.AttachmentId, Evergreen.V210.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V210.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V210.Discord.Id Evergreen.V210.Discord.AttachmentId, Evergreen.V210.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V210.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V210.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V210.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V210.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) (Result Evergreen.V210.Discord.HttpError (List Evergreen.V210.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Result Evergreen.V210.Discord.HttpError (List Evergreen.V210.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V210.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V210.DmChannel.DmChannelId Evergreen.V210.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V210.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) Evergreen.V210.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V210.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V210.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
        (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V210.Discord.HttpError
            { guild : Evergreen.V210.Discord.GatewayGuild
            , channels : List Evergreen.V210.Discord.Channel
            , icon : Maybe Evergreen.V210.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Result Evergreen.V210.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V210.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (List ( Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId, Result Effect.Http.Error Evergreen.V210.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V210.Id.Id Evergreen.V210.Id.StickerId, Result Effect.Http.Error Evergreen.V210.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (List ( Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V210.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V210.Id.Id Evergreen.V210.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V210.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V210.Discord.HttpError (List Evergreen.V210.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V210.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V210.SecretId.SecretId Evergreen.V210.SecretId.ServerSecret))
