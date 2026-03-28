module Evergreen.V176.Types exposing (..)

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
import Evergreen.V176.AiChat
import Evergreen.V176.ChannelName
import Evergreen.V176.Coord
import Evergreen.V176.CssPixels
import Evergreen.V176.Discord
import Evergreen.V176.DiscordAttachmentId
import Evergreen.V176.DiscordUserData
import Evergreen.V176.DmChannel
import Evergreen.V176.Editable
import Evergreen.V176.EmailAddress
import Evergreen.V176.Embed
import Evergreen.V176.Emoji
import Evergreen.V176.FileStatus
import Evergreen.V176.GuildName
import Evergreen.V176.Id
import Evergreen.V176.ImageEditor
import Evergreen.V176.Local
import Evergreen.V176.LocalState
import Evergreen.V176.Log
import Evergreen.V176.LoginForm
import Evergreen.V176.MembersAndOwner
import Evergreen.V176.Message
import Evergreen.V176.MessageInput
import Evergreen.V176.MessageView
import Evergreen.V176.MyUi
import Evergreen.V176.NonemptyDict
import Evergreen.V176.NonemptySet
import Evergreen.V176.OneToOne
import Evergreen.V176.Pages.Admin
import Evergreen.V176.Pagination
import Evergreen.V176.PersonName
import Evergreen.V176.Ports
import Evergreen.V176.Postmark
import Evergreen.V176.RichText
import Evergreen.V176.Route
import Evergreen.V176.SecretId
import Evergreen.V176.SessionIdHash
import Evergreen.V176.Slack
import Evergreen.V176.TextEditor
import Evergreen.V176.Touch
import Evergreen.V176.TwoFactorAuthentication
import Evergreen.V176.Ui.Anim
import Evergreen.V176.User
import Evergreen.V176.UserAgent
import Evergreen.V176.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V176.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V176.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) Evergreen.V176.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) Evergreen.V176.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.LocalState.DiscordFrontendGuild
    , user : Evergreen.V176.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V176.SessionIdHash.SessionIdHash Evergreen.V176.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V176.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V176.Route.Route
    , windowSize : Evergreen.V176.Coord.Coord Evergreen.V176.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V176.Ports.NotificationPermission
    , pwaStatus : Evergreen.V176.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V176.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V176.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V176.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))) Evergreen.V176.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Evergreen.V176.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V176.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))) Evergreen.V176.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Evergreen.V176.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) Evergreen.V176.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) Evergreen.V176.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.UserSession.ToBeFilledInByBackend (Evergreen.V176.SecretId.SecretId Evergreen.V176.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V176.GuildName.GuildName (Evergreen.V176.UserSession.ToBeFilledInByBackend (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage Evergreen.V176.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage Evergreen.V176.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V176.Id.GuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))) (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Evergreen.V176.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V176.Id.DiscordGuildOrDmId_DmData (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V176.UserSession.SetViewing
    | Local_SetName Evergreen.V176.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V176.Id.GuildOrDmId (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V176.Id.GuildOrDmId (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId) (Evergreen.V176.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ThreadMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V176.Id.DiscordGuildOrDmId (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V176.Id.DiscordGuildOrDmId (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId) (Evergreen.V176.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId) (Evergreen.V176.Message.Message Evergreen.V176.Id.ThreadMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) Evergreen.V176.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V176.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V176.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V176.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V176.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V176.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V176.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Effect.Time.Posix Evergreen.V176.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))) Evergreen.V176.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Evergreen.V176.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V176.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))) Evergreen.V176.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Evergreen.V176.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) Evergreen.V176.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) Evergreen.V176.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.SecretId.SecretId Evergreen.V176.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) Evergreen.V176.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V176.LocalState.JoinGuildError
            { guildId : Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId
            , guild : Evergreen.V176.LocalState.FrontendGuild
            , owner : Evergreen.V176.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.Id.GuildOrDmId Evergreen.V176.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.Id.GuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage Evergreen.V176.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.Id.GuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage Evergreen.V176.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage Evergreen.V176.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) Evergreen.V176.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage Evergreen.V176.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) Evergreen.V176.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.Id.GuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))) (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Evergreen.V176.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V176.Id.DiscordGuildOrDmId_DmData (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) Evergreen.V176.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V176.SessionIdHash.SessionIdHash Evergreen.V176.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V176.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V176.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V176.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.ChannelName.ChannelName (Evergreen.V176.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId)
        (Evergreen.V176.NonemptyDict.NonemptyDict
            (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) Evergreen.V176.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Maybe (Evergreen.V176.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V176.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V176.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V176.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V176.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V176.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V176.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) (Evergreen.V176.Discord.OptionalData String) (Evergreen.V176.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId)
        (Evergreen.V176.MembersAndOwner.MembersAndOwner
            (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) Evergreen.V176.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Evergreen.V176.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V176.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V176.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V176.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V176.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V176.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V176.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V176.Coord.Coord Evergreen.V176.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V176.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V176.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V176.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V176.Coord.Coord Evergreen.V176.CssPixels.CssPixels) (Maybe Evergreen.V176.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId) (Evergreen.V176.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V176.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V176.Local.Local LocalMsg Evergreen.V176.LocalState.LocalState
    , admin : Evergreen.V176.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId, Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V176.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V176.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V176.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) (Evergreen.V176.NonemptyDict.NonemptyDict (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Evergreen.V176.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V176.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V176.TextEditor.Model
    , profilePictureEditor : Evergreen.V176.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V176.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V176.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V176.SecretId.SecretId Evergreen.V176.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V176.NonemptyDict.NonemptyDict Int Evergreen.V176.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V176.NonemptyDict.NonemptyDict Int Evergreen.V176.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V176.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V176.Coord.Coord Evergreen.V176.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V176.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V176.Ports.NotificationPermission
    , pwaStatus : Evergreen.V176.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V176.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V176.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V176.Emoji.CachedEmojiData
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V176.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V176.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V176.Coord.Coord Evergreen.V176.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V176.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V176.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId, Evergreen.V176.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V176.DmChannel.DmChannelId, Evergreen.V176.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId, Evergreen.V176.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId, Evergreen.V176.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V176.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V176.NonemptyDict.NonemptyDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V176.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V176.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V176.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V176.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) Evergreen.V176.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V176.DmChannel.DmChannelId Evergreen.V176.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) Evergreen.V176.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V176.OneToOne.OneToOne (Evergreen.V176.Slack.Id Evergreen.V176.Slack.ChannelId) Evergreen.V176.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V176.OneToOne.OneToOne String (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    , slackUsers : Evergreen.V176.OneToOne.OneToOne (Evergreen.V176.Slack.Id Evergreen.V176.Slack.UserId) (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
    , slackServers : Evergreen.V176.OneToOne.OneToOne (Evergreen.V176.Slack.Id Evergreen.V176.Slack.TeamId) (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    , slackToken : Maybe Evergreen.V176.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V176.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V176.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V176.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V176.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId, Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V176.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V176.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V176.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V176.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.LocalState.LoadingDiscordChannel (List Evergreen.V176.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V176.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V176.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V176.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V176.Route.Route
    | SelectedFilesToAttach ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) Evergreen.V176.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) Evergreen.V176.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V176.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage (Evergreen.V176.Coord.Coord Evergreen.V176.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V176.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V176.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V176.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V176.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V176.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V176.NonemptyDict.NonemptyDict Int Evergreen.V176.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V176.NonemptyDict.NonemptyDict Int Evergreen.V176.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V176.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V176.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V176.Editable.Msg Evergreen.V176.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V176.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V176.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V176.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V176.Id.AnyGuildOrDmId, Evergreen.V176.Id.ThreadRoute ) (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRouteWithMessage Evergreen.V176.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V176.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V176.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) Evergreen.V176.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) Evergreen.V176.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V176.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V176.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId
        , otherUserId : Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V176.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRoute Evergreen.V176.MessageInput.Msg
    | MessageInputMsg Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRoute Evergreen.V176.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V176.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V176.Id.AnyGuildOrDmId Evergreen.V176.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V176.Id.Id Evergreen.V176.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V176.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V176.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V176.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V176.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V176.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V176.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.SecretId.SecretId Evergreen.V176.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V176.PersonName.PersonName Evergreen.V176.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V176.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V176.Slack.OAuthCode Evergreen.V176.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V176.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V176.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V176.Id.Id Evergreen.V176.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V176.EmailAddress.EmailAddress (Result Evergreen.V176.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V176.EmailAddress.EmailAddress (Result Evergreen.V176.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Evergreen.V176.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V176.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMaybeMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Result Evergreen.V176.Discord.HttpError Evergreen.V176.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V176.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Result Evergreen.V176.Discord.HttpError Evergreen.V176.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) (Result Evergreen.V176.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) (Result Evergreen.V176.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) (Result Evergreen.V176.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) (Result Evergreen.V176.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Emoji.Emoji (Result Evergreen.V176.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Emoji.Emoji (Result Evergreen.V176.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Emoji.Emoji (Result Evergreen.V176.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) Evergreen.V176.Emoji.Emoji (Result Evergreen.V176.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V176.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V176.Discord.HttpError (List ( Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId, Maybe Evergreen.V176.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V176.Slack.CurrentUser
            , team : Evergreen.V176.Slack.Team
            , users : List Evergreen.V176.Slack.User
            , channels : List ( Evergreen.V176.Slack.Channel, List Evergreen.V176.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Result Effect.Http.Error Evergreen.V176.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) Evergreen.V176.Discord.UserAuth (Result Evergreen.V176.Discord.HttpError Evergreen.V176.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Result Evergreen.V176.Discord.HttpError Evergreen.V176.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
        (Result
            Evergreen.V176.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId
                , members : List (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
                }
            , List
                ( Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId
                , { guild : Evergreen.V176.Discord.GatewayGuild
                  , channels : List Evergreen.V176.Discord.Channel
                  , icon : Maybe Evergreen.V176.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V176.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V176.Discord.Id Evergreen.V176.Discord.AttachmentId, Evergreen.V176.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V176.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V176.Discord.Id Evergreen.V176.Discord.AttachmentId, Evergreen.V176.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V176.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V176.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V176.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V176.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) (Result Evergreen.V176.Discord.HttpError (List Evergreen.V176.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Result Evergreen.V176.Discord.HttpError (List Evergreen.V176.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V176.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V176.DmChannel.DmChannelId Evergreen.V176.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V176.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) Evergreen.V176.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V176.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V176.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
        (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V176.Discord.HttpError
            { guild : Evergreen.V176.Discord.GatewayGuild
            , channels : List Evergreen.V176.Discord.Channel
            , icon : Maybe Evergreen.V176.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId) (Result Evergreen.V176.Discord.HttpError ()) Effect.Time.Posix


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
    | AdminToFrontend Evergreen.V176.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V176.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V176.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V176.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V176.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V176.ImageEditor.ToFrontend
