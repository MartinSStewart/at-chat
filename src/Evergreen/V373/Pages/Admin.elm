module Evergreen.V373.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V373.Discord
import Evergreen.V373.DmChannelId
import Evergreen.V373.Editable
import Evergreen.V373.Id
import Evergreen.V373.LocalState
import Evergreen.V373.NonemptyDict
import Evergreen.V373.Pagination
import Evergreen.V373.Postmark
import Evergreen.V373.SessionIdHash
import Evergreen.V373.Slack
import Evergreen.V373.Table
import Evergreen.V373.ToBackendLog
import Evergreen.V373.User
import Evergreen.V373.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V373.Id.Id Evergreen.V373.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V373.Id.Id Evergreen.V373.Pagination.ItemId)
    | PressedExpandSection Evergreen.V373.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | UserTableMsg Evergreen.V373.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V373.Editable.Msg (Maybe Evergreen.V373.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V373.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V373.Editable.Msg Evergreen.V373.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V373.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V373.Editable.Msg Evergreen.V373.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V373.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V373.Id.Id Evergreen.V373.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V373.Id.Id Evergreen.V373.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V373.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V373.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V373.NonemptyDict.NonemptyDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Evergreen.V373.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V373.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V373.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V373.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V373.DmChannelId.DmChannelId Evergreen.V373.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId) Evergreen.V373.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) Evergreen.V373.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) Evergreen.V373.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) Evergreen.V373.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V373.Pagination.Pagination Evergreen.V373.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V373.SessionIdHash.SessionIdHash (Evergreen.V373.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V373.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V373.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V373.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V373.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V373.SessionIdHash.SessionIdHash Evergreen.V373.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V373.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V373.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
        }
    | ExpandSection Evergreen.V373.User.AdminUiSection
    | CollapseSection Evergreen.V373.User.AdminUiSection
    | LogPageChanged (Evergreen.V373.Id.Id Evergreen.V373.Pagination.PageId) (Evergreen.V373.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V373.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V373.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V373.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V373.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    | DeleteGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | RestoreGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) (Evergreen.V373.UserSession.ToBeFilledInByBackend (Result Evergreen.V373.Discord.HttpError (List Evergreen.V373.Discord.Role)))
    | ExpandGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | CollapseGuild (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    | HideLog (Evergreen.V373.Id.Id Evergreen.V373.Pagination.ItemId)
    | UnhideLog (Evergreen.V373.Id.Id Evergreen.V373.Pagination.ItemId)
    | DisconnectClient Evergreen.V373.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V373.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V373.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V373.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V373.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V373.Id.Id Evergreen.V373.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V373.Id.Id Evergreen.V373.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V373.Editable.Model
    , publicVapidKey : Evergreen.V373.Editable.Model
    , privateVapidKey : Evergreen.V373.Editable.Model
    , openRouterKey : Evergreen.V373.Editable.Model
    , postmarkKey : Evergreen.V373.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V373.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
