module Evergreen.V175.Types exposing (..)

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
import Evergreen.V175.AiChat
import Evergreen.V175.ChannelName
import Evergreen.V175.Coord
import Evergreen.V175.CssPixels
import Evergreen.V175.Discord
import Evergreen.V175.DiscordAttachmentId
import Evergreen.V175.DiscordUserData
import Evergreen.V175.DmChannel
import Evergreen.V175.Editable
import Evergreen.V175.EmailAddress
import Evergreen.V175.Embed
import Evergreen.V175.Emoji
import Evergreen.V175.FileStatus
import Evergreen.V175.GuildName
import Evergreen.V175.Id
import Evergreen.V175.ImageEditor
import Evergreen.V175.Local
import Evergreen.V175.LocalState
import Evergreen.V175.Log
import Evergreen.V175.LoginForm
import Evergreen.V175.MembersAndOwner
import Evergreen.V175.Message
import Evergreen.V175.MessageInput
import Evergreen.V175.MessageView
import Evergreen.V175.MyUi
import Evergreen.V175.NonemptyDict
import Evergreen.V175.NonemptySet
import Evergreen.V175.OneToOne
import Evergreen.V175.Pages.Admin
import Evergreen.V175.Pagination
import Evergreen.V175.PersonName
import Evergreen.V175.Ports
import Evergreen.V175.Postmark
import Evergreen.V175.RichText
import Evergreen.V175.Route
import Evergreen.V175.SecretId
import Evergreen.V175.SessionIdHash
import Evergreen.V175.Slack
import Evergreen.V175.TextEditor
import Evergreen.V175.Touch
import Evergreen.V175.TwoFactorAuthentication
import Evergreen.V175.Ui.Anim
import Evergreen.V175.User
import Evergreen.V175.UserAgent
import Evergreen.V175.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V175.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V175.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) Evergreen.V175.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) Evergreen.V175.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.LocalState.DiscordFrontendGuild
    , user : Evergreen.V175.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V175.SessionIdHash.SessionIdHash Evergreen.V175.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V175.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V175.Route.Route
    , windowSize : Evergreen.V175.Coord.Coord Evergreen.V175.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V175.Ports.NotificationPermission
    , pwaStatus : Evergreen.V175.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V175.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V175.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V175.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))) Evergreen.V175.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Evergreen.V175.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V175.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))) Evergreen.V175.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Evergreen.V175.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) Evergreen.V175.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) Evergreen.V175.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.UserSession.ToBeFilledInByBackend (Evergreen.V175.SecretId.SecretId Evergreen.V175.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V175.GuildName.GuildName (Evergreen.V175.UserSession.ToBeFilledInByBackend (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage Evergreen.V175.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage Evergreen.V175.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V175.Id.GuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))) (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Evergreen.V175.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V175.Id.DiscordGuildOrDmId_DmData (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V175.UserSession.SetViewing
    | Local_SetName Evergreen.V175.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V175.Id.GuildOrDmId (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V175.Id.GuildOrDmId (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId) (Evergreen.V175.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ThreadMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V175.Id.DiscordGuildOrDmId (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V175.Id.DiscordGuildOrDmId (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId) (Evergreen.V175.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId) (Evergreen.V175.Message.Message Evergreen.V175.Id.ThreadMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) Evergreen.V175.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V175.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V175.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V175.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V175.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V175.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V175.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Effect.Time.Posix Evergreen.V175.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))) Evergreen.V175.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Evergreen.V175.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V175.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))) Evergreen.V175.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Evergreen.V175.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) Evergreen.V175.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) Evergreen.V175.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.SecretId.SecretId Evergreen.V175.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) Evergreen.V175.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V175.LocalState.JoinGuildError
            { guildId : Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId
            , guild : Evergreen.V175.LocalState.FrontendGuild
            , owner : Evergreen.V175.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.Id.GuildOrDmId Evergreen.V175.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.Id.GuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage Evergreen.V175.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.Id.GuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage Evergreen.V175.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage Evergreen.V175.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) Evergreen.V175.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage Evergreen.V175.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) Evergreen.V175.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.Id.GuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))) (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Evergreen.V175.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V175.Id.DiscordGuildOrDmId_DmData (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) Evergreen.V175.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V175.SessionIdHash.SessionIdHash Evergreen.V175.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V175.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V175.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V175.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.ChannelName.ChannelName (Evergreen.V175.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId)
        (Evergreen.V175.NonemptyDict.NonemptyDict
            (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) Evergreen.V175.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Maybe (Evergreen.V175.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V175.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V175.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V175.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V175.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V175.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V175.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) (Evergreen.V175.Discord.OptionalData String) (Evergreen.V175.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId)
        (Evergreen.V175.MembersAndOwner.MembersAndOwner
            (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) Evergreen.V175.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Evergreen.V175.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V175.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V175.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V175.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V175.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V175.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V175.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V175.Coord.Coord Evergreen.V175.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V175.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V175.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V175.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V175.Coord.Coord Evergreen.V175.CssPixels.CssPixels) (Maybe Evergreen.V175.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId) (Evergreen.V175.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V175.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V175.Local.Local LocalMsg Evergreen.V175.LocalState.LocalState
    , admin : Evergreen.V175.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId, Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V175.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V175.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V175.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) (Evergreen.V175.NonemptyDict.NonemptyDict (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Evergreen.V175.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V175.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V175.TextEditor.Model
    , profilePictureEditor : Evergreen.V175.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V175.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V175.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V175.SecretId.SecretId Evergreen.V175.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V175.NonemptyDict.NonemptyDict Int Evergreen.V175.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V175.NonemptyDict.NonemptyDict Int Evergreen.V175.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V175.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V175.Coord.Coord Evergreen.V175.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V175.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V175.Ports.NotificationPermission
    , pwaStatus : Evergreen.V175.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V175.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V175.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V175.Emoji.CachedEmojiData
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V175.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V175.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V175.Coord.Coord Evergreen.V175.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V175.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V175.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId, Evergreen.V175.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V175.DmChannel.DmChannelId, Evergreen.V175.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId, Evergreen.V175.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId, Evergreen.V175.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V175.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V175.NonemptyDict.NonemptyDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V175.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V175.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V175.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V175.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) Evergreen.V175.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V175.DmChannel.DmChannelId Evergreen.V175.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) Evergreen.V175.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V175.OneToOne.OneToOne (Evergreen.V175.Slack.Id Evergreen.V175.Slack.ChannelId) Evergreen.V175.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V175.OneToOne.OneToOne String (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    , slackUsers : Evergreen.V175.OneToOne.OneToOne (Evergreen.V175.Slack.Id Evergreen.V175.Slack.UserId) (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
    , slackServers : Evergreen.V175.OneToOne.OneToOne (Evergreen.V175.Slack.Id Evergreen.V175.Slack.TeamId) (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    , slackToken : Maybe Evergreen.V175.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V175.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V175.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V175.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V175.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId, Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V175.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V175.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V175.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V175.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.LocalState.LoadingDiscordChannel (List Evergreen.V175.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V175.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V175.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V175.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V175.Route.Route
    | SelectedFilesToAttach ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) Evergreen.V175.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) Evergreen.V175.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V175.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage (Evergreen.V175.Coord.Coord Evergreen.V175.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V175.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V175.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V175.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V175.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V175.NonemptyDict.NonemptyDict Int Evergreen.V175.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V175.NonemptyDict.NonemptyDict Int Evergreen.V175.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V175.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V175.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V175.Editable.Msg Evergreen.V175.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V175.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V175.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V175.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V175.Id.AnyGuildOrDmId, Evergreen.V175.Id.ThreadRoute ) (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRouteWithMessage Evergreen.V175.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V175.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V175.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) Evergreen.V175.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) Evergreen.V175.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V175.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V175.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId
        , otherUserId : Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V175.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRoute Evergreen.V175.MessageInput.Msg
    | MessageInputMsg Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRoute Evergreen.V175.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V175.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V175.Id.AnyGuildOrDmId Evergreen.V175.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V175.Id.Id Evergreen.V175.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V175.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V175.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V175.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V175.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V175.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V175.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.SecretId.SecretId Evergreen.V175.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V175.PersonName.PersonName Evergreen.V175.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V175.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V175.Slack.OAuthCode Evergreen.V175.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V175.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V175.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V175.Id.Id Evergreen.V175.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V175.EmailAddress.EmailAddress (Result Evergreen.V175.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V175.EmailAddress.EmailAddress (Result Evergreen.V175.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Evergreen.V175.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V175.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMaybeMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Result Evergreen.V175.Discord.HttpError Evergreen.V175.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V175.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Result Evergreen.V175.Discord.HttpError Evergreen.V175.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) (Result Evergreen.V175.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) (Result Evergreen.V175.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) (Result Evergreen.V175.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) (Result Evergreen.V175.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Emoji.Emoji (Result Evergreen.V175.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Emoji.Emoji (Result Evergreen.V175.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Emoji.Emoji (Result Evergreen.V175.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) Evergreen.V175.Emoji.Emoji (Result Evergreen.V175.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V175.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V175.Discord.HttpError (List ( Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId, Maybe Evergreen.V175.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V175.Slack.CurrentUser
            , team : Evergreen.V175.Slack.Team
            , users : List Evergreen.V175.Slack.User
            , channels : List ( Evergreen.V175.Slack.Channel, List Evergreen.V175.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Result Effect.Http.Error Evergreen.V175.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) Evergreen.V175.Discord.UserAuth (Result Evergreen.V175.Discord.HttpError Evergreen.V175.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Result Evergreen.V175.Discord.HttpError Evergreen.V175.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
        (Result
            Evergreen.V175.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId
                , members : List (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
                }
            , List
                ( Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId
                , { guild : Evergreen.V175.Discord.GatewayGuild
                  , channels : List Evergreen.V175.Discord.Channel
                  , icon : Maybe Evergreen.V175.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V175.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V175.Discord.Id Evergreen.V175.Discord.AttachmentId, Evergreen.V175.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V175.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V175.Discord.Id Evergreen.V175.Discord.AttachmentId, Evergreen.V175.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V175.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V175.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V175.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V175.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) (Result Evergreen.V175.Discord.HttpError (List Evergreen.V175.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Result Evergreen.V175.Discord.HttpError (List Evergreen.V175.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V175.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V175.DmChannel.DmChannelId Evergreen.V175.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V175.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) Evergreen.V175.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V175.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V175.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
        (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V175.Discord.HttpError
            { guild : Evergreen.V175.Discord.GatewayGuild
            , channels : List Evergreen.V175.Discord.Channel
            , icon : Maybe Evergreen.V175.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId) (Result Evergreen.V175.Discord.HttpError ()) Effect.Time.Posix


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
    | AdminToFrontend Evergreen.V175.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V175.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V175.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V175.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V175.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V175.ImageEditor.ToFrontend
