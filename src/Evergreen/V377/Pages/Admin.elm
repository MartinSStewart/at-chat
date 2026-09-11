module Evergreen.V377.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V377.Discord
import Evergreen.V377.DmChannelId
import Evergreen.V377.Editable
import Evergreen.V377.Id
import Evergreen.V377.LocalState
import Evergreen.V377.NonemptyDict
import Evergreen.V377.Pagination
import Evergreen.V377.Postmark
import Evergreen.V377.SessionIdHash
import Evergreen.V377.Slack
import Evergreen.V377.Table
import Evergreen.V377.ToBackendLog
import Evergreen.V377.User
import Evergreen.V377.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V377.Id.Id Evergreen.V377.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V377.Id.Id Evergreen.V377.Pagination.ItemId)
    | PressedExpandSection Evergreen.V377.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | UserTableMsg Evergreen.V377.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V377.Editable.Msg (Maybe Evergreen.V377.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V377.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V377.Editable.Msg Evergreen.V377.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V377.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V377.Editable.Msg Evergreen.V377.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V377.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V377.Id.Id Evergreen.V377.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V377.Id.Id Evergreen.V377.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V377.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V377.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V377.NonemptyDict.NonemptyDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V377.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V377.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V377.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V377.DmChannelId.DmChannelId Evergreen.V377.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId) Evergreen.V377.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) Evergreen.V377.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) Evergreen.V377.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) Evergreen.V377.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V377.Pagination.Pagination Evergreen.V377.LocalState.LogWithTime
    , connections : List ( Evergreen.V377.SessionIdHash.SessionIdHash, Evergreen.V377.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V377.LocalState.ConnectionData )
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V377.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V377.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V377.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V377.SessionIdHash.SessionIdHash Evergreen.V377.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V377.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V377.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
        }
    | ExpandSection Evergreen.V377.User.AdminUiSection
    | CollapseSection Evergreen.V377.User.AdminUiSection
    | LogPageChanged (Evergreen.V377.Id.Id Evergreen.V377.Pagination.PageId) (Evergreen.V377.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V377.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V377.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V377.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V377.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    | DeleteGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | RestoreGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) (Evergreen.V377.UserSession.ToBeFilledInByBackend (Result Evergreen.V377.Discord.HttpError (List Evergreen.V377.Discord.Role)))
    | ExpandGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | CollapseGuild (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    | HideLog (Evergreen.V377.Id.Id Evergreen.V377.Pagination.ItemId)
    | UnhideLog (Evergreen.V377.Id.Id Evergreen.V377.Pagination.ItemId)
    | DisconnectClient Evergreen.V377.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V377.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V377.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V377.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V377.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V377.Id.Id Evergreen.V377.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V377.Id.Id Evergreen.V377.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V377.Editable.Model
    , publicVapidKey : Evergreen.V377.Editable.Model
    , privateVapidKey : Evergreen.V377.Editable.Model
    , openRouterKey : Evergreen.V377.Editable.Model
    , postmarkKey : Evergreen.V377.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V377.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
