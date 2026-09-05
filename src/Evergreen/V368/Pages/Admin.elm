module Evergreen.V368.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V368.Discord
import Evergreen.V368.DmChannelId
import Evergreen.V368.Editable
import Evergreen.V368.Id
import Evergreen.V368.LocalState
import Evergreen.V368.NonemptyDict
import Evergreen.V368.Pagination
import Evergreen.V368.Postmark
import Evergreen.V368.SessionIdHash
import Evergreen.V368.Slack
import Evergreen.V368.Table
import Evergreen.V368.ToBackendLog
import Evergreen.V368.User
import Evergreen.V368.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V368.Id.Id Evergreen.V368.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V368.Id.Id Evergreen.V368.Pagination.ItemId)
    | PressedExpandSection Evergreen.V368.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | UserTableMsg Evergreen.V368.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V368.Editable.Msg (Maybe Evergreen.V368.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V368.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V368.Editable.Msg Evergreen.V368.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V368.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V368.Editable.Msg Evergreen.V368.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V368.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V368.Id.Id Evergreen.V368.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V368.Id.Id Evergreen.V368.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V368.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V368.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V368.NonemptyDict.NonemptyDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Evergreen.V368.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V368.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V368.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V368.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V368.DmChannelId.DmChannelId Evergreen.V368.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId) Evergreen.V368.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) Evergreen.V368.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) Evergreen.V368.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) Evergreen.V368.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V368.Pagination.Pagination Evergreen.V368.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V368.SessionIdHash.SessionIdHash (Evergreen.V368.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V368.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V368.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V368.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V368.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V368.SessionIdHash.SessionIdHash Evergreen.V368.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V368.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V368.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
        }
    | ExpandSection Evergreen.V368.User.AdminUiSection
    | CollapseSection Evergreen.V368.User.AdminUiSection
    | LogPageChanged (Evergreen.V368.Id.Id Evergreen.V368.Pagination.PageId) (Evergreen.V368.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V368.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V368.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V368.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V368.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    | DeleteGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | RestoreGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) (Evergreen.V368.UserSession.ToBeFilledInByBackend (Result Evergreen.V368.Discord.HttpError (List Evergreen.V368.Discord.Role)))
    | ExpandGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | CollapseGuild (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    | HideLog (Evergreen.V368.Id.Id Evergreen.V368.Pagination.ItemId)
    | UnhideLog (Evergreen.V368.Id.Id Evergreen.V368.Pagination.ItemId)
    | DisconnectClient Evergreen.V368.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V368.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V368.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V368.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V368.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V368.Id.Id Evergreen.V368.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V368.Id.Id Evergreen.V368.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V368.Editable.Model
    , publicVapidKey : Evergreen.V368.Editable.Model
    , privateVapidKey : Evergreen.V368.Editable.Model
    , openRouterKey : Evergreen.V368.Editable.Model
    , postmarkKey : Evergreen.V368.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V368.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
