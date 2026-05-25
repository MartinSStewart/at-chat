module Evergreen.V254.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V254.Cloudflare
import Evergreen.V254.Discord
import Evergreen.V254.DmChannel
import Evergreen.V254.Editable
import Evergreen.V254.Id
import Evergreen.V254.LocalState
import Evergreen.V254.NonemptyDict
import Evergreen.V254.Pagination
import Evergreen.V254.Postmark
import Evergreen.V254.SessionIdHash
import Evergreen.V254.Slack
import Evergreen.V254.Table
import Evergreen.V254.ToBackendLog
import Evergreen.V254.User
import Evergreen.V254.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V254.NonemptyDict.NonemptyDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) Evergreen.V254.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V254.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V254.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V254.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V254.Cloudflare.AppId
    , postmarkApiKey : Evergreen.V254.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V254.DmChannel.DmChannelId Evergreen.V254.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) Evergreen.V254.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) Evergreen.V254.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) Evergreen.V254.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) Evergreen.V254.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) Evergreen.V254.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V254.Pagination.Pagination Evergreen.V254.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V254.SessionIdHash.SessionIdHash (Evergreen.V254.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V254.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V254.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V254.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
        }
    | ExpandSection Evergreen.V254.User.AdminUiSection
    | CollapseSection Evergreen.V254.User.AdminUiSection
    | LogPageChanged (Evergreen.V254.Id.Id Evergreen.V254.Pagination.PageId) (Evergreen.V254.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V254.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V254.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V254.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V254.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V254.Cloudflare.AppId)
    | SetPostmarkKey Evergreen.V254.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId)
    | DeleteGuild (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId)
    | RestoreGuild (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId)
    | CollapseGuild (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId)
    | HideLog (Evergreen.V254.Id.Id Evergreen.V254.Pagination.ItemId)
    | UnhideLog (Evergreen.V254.Id.Id Evergreen.V254.Pagination.ItemId)
    | DisconnectClient Evergreen.V254.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V254.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
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
    { table : Evergreen.V254.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V254.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V254.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V254.Id.Id Evergreen.V254.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V254.Id.Id Evergreen.V254.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V254.Editable.Model
    , publicVapidKey : Evergreen.V254.Editable.Model
    , privateVapidKey : Evergreen.V254.Editable.Model
    , openRouterKey : Evergreen.V254.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V254.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V254.Editable.Model
    , postmarkKey : Evergreen.V254.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V254.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V254.Id.Id Evergreen.V254.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V254.Id.Id Evergreen.V254.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V254.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V254.User.AdminUiSection
    | PressedExpandSection Evergreen.V254.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V254.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V254.Editable.Msg (Maybe Evergreen.V254.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V254.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V254.Editable.Msg Evergreen.V254.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V254.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V254.Editable.Msg (Maybe Evergreen.V254.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V254.Editable.Msg (Maybe Evergreen.V254.Cloudflare.AppId))
    | PostmarkKeyEditableMsg (Evergreen.V254.Editable.Msg Evergreen.V254.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V254.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V254.Id.Id Evergreen.V254.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V254.Id.Id Evergreen.V254.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V254.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V254.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V254.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V254.Cloudflare.SessionStateResponse)


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
