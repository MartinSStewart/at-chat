module Evergreen.V378.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V378.BackendMsgLog
import Evergreen.V378.Discord
import Evergreen.V378.DmChannelId
import Evergreen.V378.Editable
import Evergreen.V378.Id
import Evergreen.V378.LocalState
import Evergreen.V378.NonemptyDict
import Evergreen.V378.Pagination
import Evergreen.V378.Postmark
import Evergreen.V378.SessionIdHash
import Evergreen.V378.Slack
import Evergreen.V378.Table
import Evergreen.V378.ToBackendLog
import Evergreen.V378.User
import Evergreen.V378.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V378.Id.Id Evergreen.V378.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V378.Id.Id Evergreen.V378.Pagination.ItemId)
    | PressedExpandSection Evergreen.V378.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | UserTableMsg Evergreen.V378.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V378.Editable.Msg (Maybe Evergreen.V378.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V378.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V378.Editable.Msg Evergreen.V378.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V378.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V378.Editable.Msg Evergreen.V378.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V378.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V378.Id.Id Evergreen.V378.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V378.Id.Id Evergreen.V378.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V378.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V378.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V378.NonemptyDict.NonemptyDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V378.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V378.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V378.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V378.DmChannelId.DmChannelId Evergreen.V378.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId) Evergreen.V378.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) Evergreen.V378.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) Evergreen.V378.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) Evergreen.V378.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V378.Pagination.Pagination Evergreen.V378.LocalState.LogWithTime
    , connections : List ( Evergreen.V378.SessionIdHash.SessionIdHash, Evergreen.V378.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V378.LocalState.ConnectionData )
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V378.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V378.BackendMsgLog.BackendMsgLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V378.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V378.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V378.SessionIdHash.SessionIdHash Evergreen.V378.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V378.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V378.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
        }
    | ExpandSection Evergreen.V378.User.AdminUiSection
    | CollapseSection Evergreen.V378.User.AdminUiSection
    | LogPageChanged (Evergreen.V378.Id.Id Evergreen.V378.Pagination.PageId) (Evergreen.V378.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V378.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V378.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V378.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V378.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    | DeleteGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | RestoreGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) (Evergreen.V378.UserSession.ToBeFilledInByBackend (Result Evergreen.V378.Discord.HttpError (List Evergreen.V378.Discord.Role)))
    | ExpandGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | CollapseGuild (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    | HideLog (Evergreen.V378.Id.Id Evergreen.V378.Pagination.ItemId)
    | UnhideLog (Evergreen.V378.Id.Id Evergreen.V378.Pagination.ItemId)
    | DisconnectClient Evergreen.V378.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V378.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V378.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V378.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
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
        { channelsRemaining : Int
        , encoded : Int
        , total : Int
        }
    | ExportingDmChannels
        { encoded : Int
        , total : Int
        }
    | ExportingDiscordGuilds
        { channelsRemaining : Int
        , encoded : Int
        , total : Int
        }
    | ExportingDiscordDmChannels
        { encoded : Int
        , total : Int
        }


type alias ExportSubsetSelection =
    { guilds : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V378.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V378.Id.Id Evergreen.V378.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V378.Id.Id Evergreen.V378.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V378.Editable.Model
    , publicVapidKey : Evergreen.V378.Editable.Model
    , privateVapidKey : Evergreen.V378.Editable.Model
    , openRouterKey : Evergreen.V378.Editable.Model
    , postmarkKey : Evergreen.V378.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , countToFrontend : String
    , downloadingBackup : Maybe DownloadingBackup
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress
    | ExportBackendFinished
    | DownloadLastBackupChunk Evergreen.V378.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
