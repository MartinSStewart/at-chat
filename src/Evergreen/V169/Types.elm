module Evergreen.V169.Types exposing (..)

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
import Evergreen.V169.AiChat
import Evergreen.V169.ChannelName
import Evergreen.V169.Coord
import Evergreen.V169.CssPixels
import Evergreen.V169.Discord
import Evergreen.V169.DiscordAttachmentId
import Evergreen.V169.DiscordUserData
import Evergreen.V169.DmChannel
import Evergreen.V169.Editable
import Evergreen.V169.EmailAddress
import Evergreen.V169.Embed
import Evergreen.V169.Emoji
import Evergreen.V169.FileStatus
import Evergreen.V169.GuildName
import Evergreen.V169.Id
import Evergreen.V169.ImageEditor
import Evergreen.V169.Local
import Evergreen.V169.LocalState
import Evergreen.V169.Log
import Evergreen.V169.LoginForm
import Evergreen.V169.MembersAndOwner
import Evergreen.V169.Message
import Evergreen.V169.MessageInput
import Evergreen.V169.MessageView
import Evergreen.V169.MyUi
import Evergreen.V169.NonemptyDict
import Evergreen.V169.NonemptySet
import Evergreen.V169.OneToOne
import Evergreen.V169.Pages.Admin
import Evergreen.V169.Pagination
import Evergreen.V169.PersonName
import Evergreen.V169.Ports
import Evergreen.V169.Postmark
import Evergreen.V169.RichText
import Evergreen.V169.Route
import Evergreen.V169.SecretId
import Evergreen.V169.SessionIdHash
import Evergreen.V169.Slack
import Evergreen.V169.TextEditor
import Evergreen.V169.Touch
import Evergreen.V169.TwoFactorAuthentication
import Evergreen.V169.Ui.Anim
import Evergreen.V169.User
import Evergreen.V169.UserAgent
import Evergreen.V169.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V169.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V169.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) Evergreen.V169.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) Evergreen.V169.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) Evergreen.V169.LocalState.DiscordFrontendGuild
    , user : Evergreen.V169.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V169.SessionIdHash.SessionIdHash Evergreen.V169.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V169.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V169.Route.Route
    , windowSize : Evergreen.V169.Coord.Coord Evergreen.V169.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V169.Ports.NotificationPermission
    , pwaStatus : Evergreen.V169.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V169.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V169.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V169.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))) Evergreen.V169.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Evergreen.V169.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V169.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))) Evergreen.V169.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Evergreen.V169.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) Evergreen.V169.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) Evergreen.V169.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.UserSession.ToBeFilledInByBackend (Evergreen.V169.SecretId.SecretId Evergreen.V169.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V169.GuildName.GuildName (Evergreen.V169.UserSession.ToBeFilledInByBackend (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage Evergreen.V169.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage Evergreen.V169.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V169.Id.GuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))) (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Evergreen.V169.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V169.Id.DiscordGuildOrDmId_DmData (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V169.UserSession.SetViewing
    | Local_SetName Evergreen.V169.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V169.Id.GuildOrDmId (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V169.Id.GuildOrDmId (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId) (Evergreen.V169.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ThreadMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V169.Id.DiscordGuildOrDmId (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V169.Id.DiscordGuildOrDmId (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId) (Evergreen.V169.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ThreadMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) Evergreen.V169.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) Evergreen.V169.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V169.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V169.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V169.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V169.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V169.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V169.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Effect.Time.Posix Evergreen.V169.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))) Evergreen.V169.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Evergreen.V169.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V169.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))) Evergreen.V169.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Evergreen.V169.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) Evergreen.V169.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) Evergreen.V169.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.SecretId.SecretId Evergreen.V169.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) Evergreen.V169.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V169.LocalState.JoinGuildError
            { guildId : Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId
            , guild : Evergreen.V169.LocalState.FrontendGuild
            , owner : Evergreen.V169.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.Id.GuildOrDmId Evergreen.V169.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.Id.GuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage Evergreen.V169.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.Id.GuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage Evergreen.V169.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage Evergreen.V169.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) Evergreen.V169.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage Evergreen.V169.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) Evergreen.V169.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.Id.GuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))) (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Evergreen.V169.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V169.Id.DiscordGuildOrDmId_DmData (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) Evergreen.V169.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) Evergreen.V169.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V169.SessionIdHash.SessionIdHash Evergreen.V169.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V169.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V169.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V169.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.ChannelName.ChannelName (Evergreen.V169.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId)
        (Evergreen.V169.NonemptyDict.NonemptyDict
            (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) Evergreen.V169.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) Evergreen.V169.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Maybe (Evergreen.V169.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V169.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V169.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V169.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V169.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V169.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V169.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) Evergreen.V169.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) (Evergreen.V169.Discord.OptionalData String) (Evergreen.V169.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId)
        (Evergreen.V169.MembersAndOwner.MembersAndOwner
            (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) Evergreen.V169.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Evergreen.V169.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V169.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V169.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V169.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V169.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V169.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V169.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V169.Coord.Coord Evergreen.V169.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V169.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V169.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V169.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V169.Coord.Coord Evergreen.V169.CssPixels.CssPixels) (Maybe Evergreen.V169.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId) (Evergreen.V169.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V169.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V169.Local.Local LocalMsg Evergreen.V169.LocalState.LocalState
    , admin : Evergreen.V169.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId, Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V169.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V169.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V169.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) (Evergreen.V169.NonemptyDict.NonemptyDict (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Evergreen.V169.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V169.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V169.TextEditor.Model
    , profilePictureEditor : Evergreen.V169.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V169.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V169.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V169.SecretId.SecretId Evergreen.V169.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V169.NonemptyDict.NonemptyDict Int Evergreen.V169.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V169.NonemptyDict.NonemptyDict Int Evergreen.V169.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V169.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V169.Coord.Coord Evergreen.V169.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V169.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V169.Ports.NotificationPermission
    , pwaStatus : Evergreen.V169.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V169.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V169.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V169.Emoji.CachedEmojiData
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V169.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V169.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V169.Coord.Coord Evergreen.V169.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V169.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V169.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId, Evergreen.V169.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V169.DmChannel.DmChannelId, Evergreen.V169.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId, Evergreen.V169.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId, Evergreen.V169.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V169.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V169.NonemptyDict.NonemptyDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V169.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V169.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V169.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V169.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) Evergreen.V169.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) Evergreen.V169.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V169.DmChannel.DmChannelId Evergreen.V169.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) Evergreen.V169.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V169.OneToOne.OneToOne (Evergreen.V169.Slack.Id Evergreen.V169.Slack.ChannelId) Evergreen.V169.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V169.OneToOne.OneToOne String (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    , slackUsers : Evergreen.V169.OneToOne.OneToOne (Evergreen.V169.Slack.Id Evergreen.V169.Slack.UserId) (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
    , slackServers : Evergreen.V169.OneToOne.OneToOne (Evergreen.V169.Slack.Id Evergreen.V169.Slack.TeamId) (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    , slackToken : Maybe Evergreen.V169.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V169.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V169.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V169.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V169.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId, Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V169.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V169.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V169.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V169.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.LocalState.LoadingDiscordChannel (List Evergreen.V169.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V169.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V169.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V169.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V169.Route.Route
    | SelectedFilesToAttach ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) Evergreen.V169.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) Evergreen.V169.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V169.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage (Evergreen.V169.Coord.Coord Evergreen.V169.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V169.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V169.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V169.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V169.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V169.NonemptyDict.NonemptyDict Int Evergreen.V169.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V169.NonemptyDict.NonemptyDict Int Evergreen.V169.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V169.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V169.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V169.Editable.Msg Evergreen.V169.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V169.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V169.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V169.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute ) (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRouteWithMessage Evergreen.V169.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V169.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V169.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) Evergreen.V169.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) Evergreen.V169.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V169.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V169.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId
        , otherUserId : Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V169.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRoute Evergreen.V169.MessageInput.Msg
    | MessageInputMsg Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRoute Evergreen.V169.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V169.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V169.Id.AnyGuildOrDmId Evergreen.V169.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V169.Id.Id Evergreen.V169.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V169.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V169.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V169.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V169.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V169.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V169.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.SecretId.SecretId Evergreen.V169.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V169.PersonName.PersonName Evergreen.V169.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V169.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V169.Slack.OAuthCode Evergreen.V169.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V169.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V169.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V169.Id.Id Evergreen.V169.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V169.EmailAddress.EmailAddress (Result Evergreen.V169.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V169.EmailAddress.EmailAddress (Result Evergreen.V169.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Evergreen.V169.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V169.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMaybeMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Result Evergreen.V169.Discord.HttpError Evergreen.V169.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V169.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Result Evergreen.V169.Discord.HttpError Evergreen.V169.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) (Result Evergreen.V169.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) (Result Evergreen.V169.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) (Result Evergreen.V169.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) (Result Evergreen.V169.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Emoji.Emoji (Result Evergreen.V169.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Emoji.Emoji (Result Evergreen.V169.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Emoji.Emoji (Result Evergreen.V169.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) Evergreen.V169.Emoji.Emoji (Result Evergreen.V169.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V169.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V169.Discord.HttpError (List ( Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId, Maybe Evergreen.V169.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V169.Slack.CurrentUser
            , team : Evergreen.V169.Slack.Team
            , users : List Evergreen.V169.Slack.User
            , channels : List ( Evergreen.V169.Slack.Channel, List Evergreen.V169.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Result Effect.Http.Error Evergreen.V169.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.Discord.UserAuth (Result Evergreen.V169.Discord.HttpError Evergreen.V169.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Result Evergreen.V169.Discord.HttpError Evergreen.V169.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
        (Result
            Evergreen.V169.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId
                , members : List (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
                }
            , List
                ( Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId
                , { guild : Evergreen.V169.Discord.GatewayGuild
                  , channels : List Evergreen.V169.Discord.Channel
                  , icon : Maybe Evergreen.V169.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V169.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V169.Discord.Id Evergreen.V169.Discord.AttachmentId, Evergreen.V169.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V169.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V169.Discord.Id Evergreen.V169.Discord.AttachmentId, Evergreen.V169.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V169.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V169.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V169.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V169.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) (Result Evergreen.V169.Discord.HttpError (List Evergreen.V169.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Result Evergreen.V169.Discord.HttpError (List Evergreen.V169.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V169.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V169.DmChannel.DmChannelId Evergreen.V169.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V169.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) Evergreen.V169.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V169.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V169.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
        (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V169.Discord.HttpError
            { guild : Evergreen.V169.Discord.GatewayGuild
            , channels : List Evergreen.V169.Discord.Channel
            , icon : Maybe Evergreen.V169.FileStatus.UploadResponse
            }
        )


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
    | AdminToFrontend Evergreen.V169.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V169.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V169.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V169.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V169.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V169.ImageEditor.ToFrontend
