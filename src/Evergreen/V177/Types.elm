module Evergreen.V177.Types exposing (..)

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
import Evergreen.V177.AiChat
import Evergreen.V177.ChannelName
import Evergreen.V177.Coord
import Evergreen.V177.CssPixels
import Evergreen.V177.Discord
import Evergreen.V177.DiscordAttachmentId
import Evergreen.V177.DiscordUserData
import Evergreen.V177.DmChannel
import Evergreen.V177.Editable
import Evergreen.V177.EmailAddress
import Evergreen.V177.Embed
import Evergreen.V177.Emoji
import Evergreen.V177.FileStatus
import Evergreen.V177.GuildName
import Evergreen.V177.Id
import Evergreen.V177.ImageEditor
import Evergreen.V177.Local
import Evergreen.V177.LocalState
import Evergreen.V177.Log
import Evergreen.V177.LoginForm
import Evergreen.V177.MembersAndOwner
import Evergreen.V177.Message
import Evergreen.V177.MessageInput
import Evergreen.V177.MessageView
import Evergreen.V177.MyUi
import Evergreen.V177.NonemptyDict
import Evergreen.V177.NonemptySet
import Evergreen.V177.OneToOne
import Evergreen.V177.Pages.Admin
import Evergreen.V177.Pagination
import Evergreen.V177.PersonName
import Evergreen.V177.Ports
import Evergreen.V177.Postmark
import Evergreen.V177.RichText
import Evergreen.V177.Route
import Evergreen.V177.SecretId
import Evergreen.V177.SessionIdHash
import Evergreen.V177.Slack
import Evergreen.V177.TextEditor
import Evergreen.V177.Touch
import Evergreen.V177.TwoFactorAuthentication
import Evergreen.V177.Ui.Anim
import Evergreen.V177.User
import Evergreen.V177.UserAgent
import Evergreen.V177.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V177.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V177.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) Evergreen.V177.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) Evergreen.V177.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.LocalState.DiscordFrontendGuild
    , user : Evergreen.V177.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V177.SessionIdHash.SessionIdHash Evergreen.V177.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V177.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V177.Route.Route
    , windowSize : Evergreen.V177.Coord.Coord Evergreen.V177.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V177.Ports.NotificationPermission
    , pwaStatus : Evergreen.V177.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V177.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V177.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V177.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))) Evergreen.V177.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Evergreen.V177.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V177.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))) Evergreen.V177.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Evergreen.V177.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) Evergreen.V177.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) Evergreen.V177.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.UserSession.ToBeFilledInByBackend (Evergreen.V177.SecretId.SecretId Evergreen.V177.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V177.GuildName.GuildName (Evergreen.V177.UserSession.ToBeFilledInByBackend (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage Evergreen.V177.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage Evergreen.V177.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V177.Id.GuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))) (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Evergreen.V177.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V177.Id.DiscordGuildOrDmId_DmData (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V177.UserSession.SetViewing
    | Local_SetName Evergreen.V177.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V177.Id.GuildOrDmId (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V177.Id.GuildOrDmId (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId) (Evergreen.V177.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ThreadMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V177.Id.DiscordGuildOrDmId (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V177.Id.DiscordGuildOrDmId (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId) (Evergreen.V177.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId) (Evergreen.V177.Message.Message Evergreen.V177.Id.ThreadMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) Evergreen.V177.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V177.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V177.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V177.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V177.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V177.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V177.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Effect.Time.Posix Evergreen.V177.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))) Evergreen.V177.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Evergreen.V177.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V177.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))) Evergreen.V177.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Evergreen.V177.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) Evergreen.V177.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) Evergreen.V177.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.SecretId.SecretId Evergreen.V177.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) Evergreen.V177.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V177.LocalState.JoinGuildError
            { guildId : Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId
            , guild : Evergreen.V177.LocalState.FrontendGuild
            , owner : Evergreen.V177.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.Id.GuildOrDmId Evergreen.V177.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.Id.GuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage Evergreen.V177.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.Id.GuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage Evergreen.V177.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage Evergreen.V177.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) Evergreen.V177.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage Evergreen.V177.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) Evergreen.V177.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.Id.GuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))) (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Evergreen.V177.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V177.Id.DiscordGuildOrDmId_DmData (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) Evergreen.V177.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V177.SessionIdHash.SessionIdHash Evergreen.V177.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V177.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V177.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V177.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.ChannelName.ChannelName (Evergreen.V177.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId)
        (Evergreen.V177.NonemptyDict.NonemptyDict
            (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) Evergreen.V177.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Maybe (Evergreen.V177.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V177.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V177.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V177.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V177.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V177.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V177.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) (Evergreen.V177.Discord.OptionalData String) (Evergreen.V177.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId)
        (Evergreen.V177.MembersAndOwner.MembersAndOwner
            (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) Evergreen.V177.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Evergreen.V177.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V177.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V177.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V177.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V177.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V177.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V177.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V177.Coord.Coord Evergreen.V177.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V177.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V177.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V177.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V177.Coord.Coord Evergreen.V177.CssPixels.CssPixels) (Maybe Evergreen.V177.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId) (Evergreen.V177.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V177.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V177.Local.Local LocalMsg Evergreen.V177.LocalState.LocalState
    , admin : Evergreen.V177.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId, Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V177.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V177.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V177.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) (Evergreen.V177.NonemptyDict.NonemptyDict (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Evergreen.V177.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V177.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V177.TextEditor.Model
    , profilePictureEditor : Evergreen.V177.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V177.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V177.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V177.SecretId.SecretId Evergreen.V177.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V177.NonemptyDict.NonemptyDict Int Evergreen.V177.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V177.NonemptyDict.NonemptyDict Int Evergreen.V177.Touch.Touch
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
    | AdminToFrontend Evergreen.V177.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V177.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V177.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V177.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V177.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V177.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V177.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V177.Coord.Coord Evergreen.V177.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V177.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V177.Ports.NotificationPermission
    , pwaStatus : Evergreen.V177.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V177.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V177.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V177.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V177.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V177.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V177.Coord.Coord Evergreen.V177.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V177.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V177.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId, Evergreen.V177.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V177.DmChannel.DmChannelId, Evergreen.V177.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId, Evergreen.V177.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId, Evergreen.V177.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V177.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V177.NonemptyDict.NonemptyDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V177.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V177.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V177.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V177.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) Evergreen.V177.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V177.DmChannel.DmChannelId Evergreen.V177.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) Evergreen.V177.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V177.OneToOne.OneToOne (Evergreen.V177.Slack.Id Evergreen.V177.Slack.ChannelId) Evergreen.V177.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V177.OneToOne.OneToOne String (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    , slackUsers : Evergreen.V177.OneToOne.OneToOne (Evergreen.V177.Slack.Id Evergreen.V177.Slack.UserId) (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
    , slackServers : Evergreen.V177.OneToOne.OneToOne (Evergreen.V177.Slack.Id Evergreen.V177.Slack.TeamId) (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    , slackToken : Maybe Evergreen.V177.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V177.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V177.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V177.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V177.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId, Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V177.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V177.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V177.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V177.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.LocalState.LoadingDiscordChannel (List Evergreen.V177.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V177.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V177.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V177.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V177.Route.Route
    | SelectedFilesToAttach ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) Evergreen.V177.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) Evergreen.V177.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V177.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage (Evergreen.V177.Coord.Coord Evergreen.V177.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V177.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V177.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V177.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V177.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V177.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V177.NonemptyDict.NonemptyDict Int Evergreen.V177.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V177.NonemptyDict.NonemptyDict Int Evergreen.V177.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V177.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V177.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V177.Editable.Msg Evergreen.V177.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V177.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V177.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V177.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V177.Id.AnyGuildOrDmId, Evergreen.V177.Id.ThreadRoute ) (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRouteWithMessage Evergreen.V177.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V177.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V177.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) Evergreen.V177.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) Evergreen.V177.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V177.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V177.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId
        , otherUserId : Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V177.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRoute Evergreen.V177.MessageInput.Msg
    | MessageInputMsg Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRoute Evergreen.V177.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V177.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V177.Id.AnyGuildOrDmId Evergreen.V177.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V177.Id.Id Evergreen.V177.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V177.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V177.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V177.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V177.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V177.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V177.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.SecretId.SecretId Evergreen.V177.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V177.PersonName.PersonName Evergreen.V177.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V177.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V177.Slack.OAuthCode Evergreen.V177.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V177.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V177.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V177.Id.Id Evergreen.V177.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V177.EmailAddress.EmailAddress (Result Evergreen.V177.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V177.EmailAddress.EmailAddress (Result Evergreen.V177.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Evergreen.V177.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V177.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMaybeMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Result Evergreen.V177.Discord.HttpError Evergreen.V177.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V177.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Result Evergreen.V177.Discord.HttpError Evergreen.V177.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) (Result Evergreen.V177.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) (Result Evergreen.V177.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) (Result Evergreen.V177.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) (Result Evergreen.V177.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Emoji.Emoji (Result Evergreen.V177.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Emoji.Emoji (Result Evergreen.V177.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Emoji.Emoji (Result Evergreen.V177.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) Evergreen.V177.Emoji.Emoji (Result Evergreen.V177.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V177.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V177.Discord.HttpError (List ( Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId, Maybe Evergreen.V177.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V177.Slack.CurrentUser
            , team : Evergreen.V177.Slack.Team
            , users : List Evergreen.V177.Slack.User
            , channels : List ( Evergreen.V177.Slack.Channel, List Evergreen.V177.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Result Effect.Http.Error Evergreen.V177.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) Evergreen.V177.Discord.UserAuth (Result Evergreen.V177.Discord.HttpError Evergreen.V177.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Result Evergreen.V177.Discord.HttpError Evergreen.V177.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
        (Result
            Evergreen.V177.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId
                , members : List (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
                }
            , List
                ( Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId
                , { guild : Evergreen.V177.Discord.GatewayGuild
                  , channels : List Evergreen.V177.Discord.Channel
                  , icon : Maybe Evergreen.V177.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V177.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V177.Discord.Id Evergreen.V177.Discord.AttachmentId, Evergreen.V177.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V177.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V177.Discord.Id Evergreen.V177.Discord.AttachmentId, Evergreen.V177.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V177.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V177.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V177.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V177.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) (Result Evergreen.V177.Discord.HttpError (List Evergreen.V177.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Result Evergreen.V177.Discord.HttpError (List Evergreen.V177.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V177.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V177.DmChannel.DmChannelId Evergreen.V177.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V177.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) Evergreen.V177.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V177.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V177.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
        (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V177.Discord.HttpError
            { guild : Evergreen.V177.Discord.GatewayGuild
            , channels : List Evergreen.V177.Discord.Channel
            , icon : Maybe Evergreen.V177.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId) (Result Evergreen.V177.Discord.HttpError ()) Effect.Time.Posix
