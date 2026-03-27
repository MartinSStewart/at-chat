module Evergreen.V173.Types exposing (..)

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
import Evergreen.V173.AiChat
import Evergreen.V173.ChannelName
import Evergreen.V173.Coord
import Evergreen.V173.CssPixels
import Evergreen.V173.Discord
import Evergreen.V173.DiscordAttachmentId
import Evergreen.V173.DiscordUserData
import Evergreen.V173.DmChannel
import Evergreen.V173.Editable
import Evergreen.V173.EmailAddress
import Evergreen.V173.Embed
import Evergreen.V173.Emoji
import Evergreen.V173.FileStatus
import Evergreen.V173.GuildName
import Evergreen.V173.Id
import Evergreen.V173.ImageEditor
import Evergreen.V173.Local
import Evergreen.V173.LocalState
import Evergreen.V173.Log
import Evergreen.V173.LoginForm
import Evergreen.V173.MembersAndOwner
import Evergreen.V173.Message
import Evergreen.V173.MessageInput
import Evergreen.V173.MessageView
import Evergreen.V173.MyUi
import Evergreen.V173.NonemptyDict
import Evergreen.V173.NonemptySet
import Evergreen.V173.OneToOne
import Evergreen.V173.Pages.Admin
import Evergreen.V173.Pagination
import Evergreen.V173.PersonName
import Evergreen.V173.Ports
import Evergreen.V173.Postmark
import Evergreen.V173.RichText
import Evergreen.V173.Route
import Evergreen.V173.SecretId
import Evergreen.V173.SessionIdHash
import Evergreen.V173.Slack
import Evergreen.V173.TextEditor
import Evergreen.V173.Touch
import Evergreen.V173.TwoFactorAuthentication
import Evergreen.V173.Ui.Anim
import Evergreen.V173.User
import Evergreen.V173.UserAgent
import Evergreen.V173.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V173.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V173.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) Evergreen.V173.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) Evergreen.V173.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.LocalState.DiscordFrontendGuild
    , user : Evergreen.V173.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V173.SessionIdHash.SessionIdHash Evergreen.V173.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V173.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V173.Route.Route
    , windowSize : Evergreen.V173.Coord.Coord Evergreen.V173.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V173.Ports.NotificationPermission
    , pwaStatus : Evergreen.V173.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V173.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V173.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V173.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))) Evergreen.V173.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Evergreen.V173.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V173.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))) Evergreen.V173.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Evergreen.V173.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) Evergreen.V173.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) Evergreen.V173.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.UserSession.ToBeFilledInByBackend (Evergreen.V173.SecretId.SecretId Evergreen.V173.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V173.GuildName.GuildName (Evergreen.V173.UserSession.ToBeFilledInByBackend (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage Evergreen.V173.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage Evergreen.V173.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V173.Id.GuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))) (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Evergreen.V173.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V173.Id.DiscordGuildOrDmId_DmData (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V173.UserSession.SetViewing
    | Local_SetName Evergreen.V173.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V173.Id.GuildOrDmId (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V173.Id.GuildOrDmId (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId) (Evergreen.V173.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ThreadMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V173.Id.DiscordGuildOrDmId (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V173.Id.DiscordGuildOrDmId (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId) (Evergreen.V173.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId) (Evergreen.V173.Message.Message Evergreen.V173.Id.ThreadMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) Evergreen.V173.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V173.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V173.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V173.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V173.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V173.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V173.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Effect.Time.Posix Evergreen.V173.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))) Evergreen.V173.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Evergreen.V173.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V173.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))) Evergreen.V173.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Evergreen.V173.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) Evergreen.V173.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) Evergreen.V173.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.SecretId.SecretId Evergreen.V173.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) Evergreen.V173.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V173.LocalState.JoinGuildError
            { guildId : Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId
            , guild : Evergreen.V173.LocalState.FrontendGuild
            , owner : Evergreen.V173.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.Id.GuildOrDmId Evergreen.V173.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.Id.GuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage Evergreen.V173.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.Id.GuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage Evergreen.V173.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage Evergreen.V173.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) Evergreen.V173.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage Evergreen.V173.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) Evergreen.V173.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.Id.GuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))) (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Evergreen.V173.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V173.Id.DiscordGuildOrDmId_DmData (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) Evergreen.V173.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V173.SessionIdHash.SessionIdHash Evergreen.V173.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V173.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V173.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V173.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.ChannelName.ChannelName (Evergreen.V173.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId)
        (Evergreen.V173.NonemptyDict.NonemptyDict
            (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) Evergreen.V173.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Maybe (Evergreen.V173.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V173.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V173.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V173.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V173.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V173.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V173.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) (Evergreen.V173.Discord.OptionalData String) (Evergreen.V173.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId)
        (Evergreen.V173.MembersAndOwner.MembersAndOwner
            (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) Evergreen.V173.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Evergreen.V173.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V173.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V173.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V173.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V173.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V173.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V173.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V173.Coord.Coord Evergreen.V173.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V173.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V173.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V173.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V173.Coord.Coord Evergreen.V173.CssPixels.CssPixels) (Maybe Evergreen.V173.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId) (Evergreen.V173.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V173.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V173.Local.Local LocalMsg Evergreen.V173.LocalState.LocalState
    , admin : Evergreen.V173.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId, Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V173.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V173.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V173.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) (Evergreen.V173.NonemptyDict.NonemptyDict (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Evergreen.V173.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V173.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V173.TextEditor.Model
    , profilePictureEditor : Evergreen.V173.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V173.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V173.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V173.SecretId.SecretId Evergreen.V173.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V173.NonemptyDict.NonemptyDict Int Evergreen.V173.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V173.NonemptyDict.NonemptyDict Int Evergreen.V173.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V173.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V173.Coord.Coord Evergreen.V173.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V173.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V173.Ports.NotificationPermission
    , pwaStatus : Evergreen.V173.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V173.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V173.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V173.Emoji.CachedEmojiData
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V173.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V173.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V173.Coord.Coord Evergreen.V173.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V173.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V173.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId, Evergreen.V173.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V173.DmChannel.DmChannelId, Evergreen.V173.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId, Evergreen.V173.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId, Evergreen.V173.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V173.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V173.NonemptyDict.NonemptyDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V173.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V173.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V173.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V173.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) Evergreen.V173.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V173.DmChannel.DmChannelId Evergreen.V173.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) Evergreen.V173.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V173.OneToOne.OneToOne (Evergreen.V173.Slack.Id Evergreen.V173.Slack.ChannelId) Evergreen.V173.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V173.OneToOne.OneToOne String (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    , slackUsers : Evergreen.V173.OneToOne.OneToOne (Evergreen.V173.Slack.Id Evergreen.V173.Slack.UserId) (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
    , slackServers : Evergreen.V173.OneToOne.OneToOne (Evergreen.V173.Slack.Id Evergreen.V173.Slack.TeamId) (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    , slackToken : Maybe Evergreen.V173.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V173.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V173.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V173.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V173.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId, Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V173.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V173.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V173.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V173.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.LocalState.LoadingDiscordChannel (List Evergreen.V173.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V173.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V173.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V173.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V173.Route.Route
    | SelectedFilesToAttach ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) Evergreen.V173.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) Evergreen.V173.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V173.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage (Evergreen.V173.Coord.Coord Evergreen.V173.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V173.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V173.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V173.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V173.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V173.NonemptyDict.NonemptyDict Int Evergreen.V173.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V173.NonemptyDict.NonemptyDict Int Evergreen.V173.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V173.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V173.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V173.Editable.Msg Evergreen.V173.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V173.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V173.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V173.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V173.Id.AnyGuildOrDmId, Evergreen.V173.Id.ThreadRoute ) (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRouteWithMessage Evergreen.V173.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V173.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V173.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) Evergreen.V173.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) Evergreen.V173.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V173.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V173.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId
        , otherUserId : Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V173.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRoute Evergreen.V173.MessageInput.Msg
    | MessageInputMsg Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRoute Evergreen.V173.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V173.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V173.Id.AnyGuildOrDmId Evergreen.V173.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V173.Id.Id Evergreen.V173.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V173.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V173.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V173.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V173.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V173.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V173.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.SecretId.SecretId Evergreen.V173.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V173.PersonName.PersonName Evergreen.V173.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V173.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V173.Slack.OAuthCode Evergreen.V173.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V173.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V173.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V173.Id.Id Evergreen.V173.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V173.EmailAddress.EmailAddress (Result Evergreen.V173.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V173.EmailAddress.EmailAddress (Result Evergreen.V173.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Evergreen.V173.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V173.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMaybeMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Result Evergreen.V173.Discord.HttpError Evergreen.V173.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V173.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Result Evergreen.V173.Discord.HttpError Evergreen.V173.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) (Result Evergreen.V173.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) (Result Evergreen.V173.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) (Result Evergreen.V173.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) (Result Evergreen.V173.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Emoji.Emoji (Result Evergreen.V173.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Emoji.Emoji (Result Evergreen.V173.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Emoji.Emoji (Result Evergreen.V173.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) Evergreen.V173.Emoji.Emoji (Result Evergreen.V173.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V173.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V173.Discord.HttpError (List ( Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId, Maybe Evergreen.V173.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V173.Slack.CurrentUser
            , team : Evergreen.V173.Slack.Team
            , users : List Evergreen.V173.Slack.User
            , channels : List ( Evergreen.V173.Slack.Channel, List Evergreen.V173.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Result Effect.Http.Error Evergreen.V173.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) Evergreen.V173.Discord.UserAuth (Result Evergreen.V173.Discord.HttpError Evergreen.V173.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Result Evergreen.V173.Discord.HttpError Evergreen.V173.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
        (Result
            Evergreen.V173.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId
                , members : List (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
                }
            , List
                ( Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId
                , { guild : Evergreen.V173.Discord.GatewayGuild
                  , channels : List Evergreen.V173.Discord.Channel
                  , icon : Maybe Evergreen.V173.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V173.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V173.Discord.Id Evergreen.V173.Discord.AttachmentId, Evergreen.V173.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V173.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V173.Discord.Id Evergreen.V173.Discord.AttachmentId, Evergreen.V173.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V173.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V173.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V173.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V173.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) (Result Evergreen.V173.Discord.HttpError (List Evergreen.V173.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Result Evergreen.V173.Discord.HttpError (List Evergreen.V173.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V173.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V173.DmChannel.DmChannelId Evergreen.V173.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V173.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) Evergreen.V173.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V173.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V173.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
        (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V173.Discord.HttpError
            { guild : Evergreen.V173.Discord.GatewayGuild
            , channels : List Evergreen.V173.Discord.Channel
            , icon : Maybe Evergreen.V173.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId) (Result Evergreen.V173.Discord.HttpError ()) Effect.Time.Posix


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
    | AdminToFrontend Evergreen.V173.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V173.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V173.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V173.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V173.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V173.ImageEditor.ToFrontend
