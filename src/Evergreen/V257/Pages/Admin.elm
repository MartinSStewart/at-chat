module Evergreen.V257.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V257.Cloudflare
import Evergreen.V257.Discord
import Evergreen.V257.DmChannel
import Evergreen.V257.Editable
import Evergreen.V257.Id
import Evergreen.V257.LocalState
import Evergreen.V257.NonemptyDict
import Evergreen.V257.Pagination
import Evergreen.V257.Postmark
import Evergreen.V257.SessionIdHash
import Evergreen.V257.Slack
import Evergreen.V257.Table
import Evergreen.V257.ToBackendLog
import Evergreen.V257.User
import Evergreen.V257.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V257.NonemptyDict.NonemptyDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Evergreen.V257.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V257.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V257.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V257.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V257.Cloudflare.AppId
    , postmarkApiKey : Evergreen.V257.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V257.DmChannel.DmChannelId Evergreen.V257.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) Evergreen.V257.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) Evergreen.V257.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) Evergreen.V257.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) Evergreen.V257.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V257.Pagination.Pagination Evergreen.V257.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V257.SessionIdHash.SessionIdHash (Evergreen.V257.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V257.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V257.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V257.LocalState.WebsocketClosedEvent
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
        }
    | ExpandSection Evergreen.V257.User.AdminUiSection
    | CollapseSection Evergreen.V257.User.AdminUiSection
    | LogPageChanged (Evergreen.V257.Id.Id Evergreen.V257.Pagination.PageId) (Evergreen.V257.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V257.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V257.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V257.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetCloudflareRealtimeApiToken (Maybe Evergreen.V257.Cloudflare.RealtimeApiToken)
    | SetCloudflareRealtimeAppId (Maybe Evergreen.V257.Cloudflare.AppId)
    | SetPostmarkKey Evergreen.V257.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
    | DeleteGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | RestoreGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | CollapseGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
    | HideLog (Evergreen.V257.Id.Id Evergreen.V257.Pagination.ItemId)
    | UnhideLog (Evergreen.V257.Id.Id Evergreen.V257.Pagination.ItemId)
    | DisconnectClient Evergreen.V257.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V257.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | EndAllCalls


type UserTableId
    = ExistingUserId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
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
    { table : Evergreen.V257.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V257.DmChannel.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId)
    }


type RealtimeSessionInfoStatus
    = LoadingRealtimeSessionInfo
    | LoadedRealtimeSessionInfo Evergreen.V257.Cloudflare.SessionStateResponse
    | FailedToLoadRealtimeSessionInfo Effect.Http.Error


type alias Model =
    { highlightLog : Maybe (Evergreen.V257.Id.Id Evergreen.V257.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V257.Id.Id Evergreen.V257.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V257.Editable.Model
    , publicVapidKey : Evergreen.V257.Editable.Model
    , privateVapidKey : Evergreen.V257.Editable.Model
    , openRouterKey : Evergreen.V257.Editable.Model
    , cloudflareRealtimeApiToken : Evergreen.V257.Editable.Model
    , cloudflareRealtimeAppId : Evergreen.V257.Editable.Model
    , postmarkKey : Evergreen.V257.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , realtimeSessionData : SeqDict.SeqDict Evergreen.V257.Cloudflare.RealtimeSessionId RealtimeSessionInfoStatus
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V257.Id.Id Evergreen.V257.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V257.Id.Id Evergreen.V257.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V257.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V257.User.AdminUiSection
    | PressedExpandSection Evergreen.V257.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V257.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V257.Editable.Msg (Maybe Evergreen.V257.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V257.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V257.Editable.Msg Evergreen.V257.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V257.Editable.Msg (Maybe String))
    | CloudflareRealtimeApiTokenEditableMsg (Evergreen.V257.Editable.Msg (Maybe Evergreen.V257.Cloudflare.RealtimeApiToken))
    | CloudflareRealtimeAppIdEditableMsg (Evergreen.V257.Editable.Msg (Maybe Evergreen.V257.Cloudflare.AppId))
    | PostmarkKeyEditableMsg (Evergreen.V257.Editable.Msg Evergreen.V257.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V257.DmChannel.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V257.Id.Id Evergreen.V257.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V257.Id.Id Evergreen.V257.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V257.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret
    | PressedDeleteCall
    | PressedWebsocketCloseEventsPage Int
    | PressedLoadRealtimeSessionData Evergreen.V257.Cloudflare.RealtimeSessionId
    | GotRealtimeSessionInfo Evergreen.V257.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V257.Cloudflare.SessionStateResponse)


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
