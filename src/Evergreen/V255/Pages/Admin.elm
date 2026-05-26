module Evergreen.V255.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V255.Cloudflare
import Evergreen.V255.Discord
import Evergreen.V255.DmChannel
import Evergreen.V255.Editable
import Evergreen.V255.Id
import Evergreen.V255.LocalState
import Evergreen.V255.NonemptyDict
import Evergreen.V255.Pagination
import Evergreen.V255.Postmark
import Evergreen.V255.SessionIdHash
import Evergreen.V255.Slack
import Evergreen.V255.Table
import Evergreen.V255.ToBackendLog
import Evergreen.V255.User
import Evergreen.V255.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V255.NonemptyDict.NonemptyDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V255.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V255.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V255.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V255.Cloudflare.AppId
    , postmarkApiKey : Evergreen.V255.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V255.DmChannel.DmChannelId Evergreen.V255.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) Evergreen.V255.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) Evergreen.V255.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) Evergreen.V255.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) Evergreen.V255.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V255.Pagination.Pagination Evergreen.V255.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V255.SessionIdHash.SessionIdHash (Evergreen.V255.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V255.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V255.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V255.LocalState.WebsocketClosedEvent
    }


type alias EditedBackendUser =
    { name : String
    , email : String
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }


type AdminChange
    = ChangeUsers
        { time : Effect.Time.Posix
        , changedUsers : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
        }
    | ExpandSection Evergreen.V255.User.AdminUiSection
    | CollapseSection Evergreen.V255.User.AdminUiSection
    | LogPageChanged (Evergreen.V255.Id.Id Evergreen.V255.Pagination.PageId) (Evergreen.V255.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V255.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V255.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V255.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V255.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V255.Cloudflare.AppId)
    | SetPostmarkKey Evergreen.V255.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
    | DeleteGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | RestoreGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | CollapseGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
    | HideLog (Evergreen.V255.Id.Id Evergreen.V255.Pagination.ItemId)
    | UnhideLog (Evergreen.V255.Id.Id Evergreen.V255.Pagination.ItemId)
    | DisconnectClient Evergreen.V255.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V255.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V255.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type ExportProgress
    = ExportStarting
    | ExportingGuilds
        { encoded : Int
        , total : Int
        }
    | ExportingDmChannels
        { encoded : Int
        , total : Int
        }
    | ExportingDiscordGuilds
        { encoded : Int
        , total : Int
        }
    | ExportingDiscordDmChannels
        { encoded : Int
        , total : Int
        }
    | ExportingFinalStep Bytes.Bytes


type alias ExportSubsetSelection =
    { dmChannels : SeqSet.SeqSet Evergreen.V255.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V255.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V255.Id.Id Evergreen.V255.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V255.Id.Id Evergreen.V255.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V255.Editable.Model
    , publicVapidKey : Evergreen.V255.Editable.Model
    , privateVapidKey : Evergreen.V255.Editable.Model
    , openRouterKey : Evergreen.V255.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V255.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V255.Editable.Model
    , postmarkKey : Evergreen.V255.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V255.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V255.Id.Id Evergreen.V255.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V255.Id.Id Evergreen.V255.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V255.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V255.User.AdminUiSection
    | PressedExpandSection Evergreen.V255.User.AdminUiSection
    | PressedEditCell UserTableId UserColumn
    | TypedEditCell String
    | EditCellLostFocus UserTableId UserColumn
    | FocusedOnEditCell
    | EnterKeyInEditCell UserTableId UserColumn
    | PressedSaveUserChanges
    | TabKeyInEditCell Bool
    | PressedResetUserChanges
    | EscapeKeyInEditCell
    | PressedAddUserRow
    | PressedDeleteUser UserTableId
    | PressedResetUser (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V255.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V255.Editable.Msg (Maybe Evergreen.V255.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V255.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V255.Editable.Msg Evergreen.V255.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V255.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V255.Editable.Msg (Maybe Evergreen.V255.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V255.Editable.Msg (Maybe Evergreen.V255.Cloudflare.AppId))
    | PostmarkKeyEditableMsg (Evergreen.V255.Editable.Msg Evergreen.V255.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V255.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V255.Id.Id Evergreen.V255.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V255.Id.Id Evergreen.V255.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V255.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V255.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V255.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V255.Cloudflare.SessionStateResponse)


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
