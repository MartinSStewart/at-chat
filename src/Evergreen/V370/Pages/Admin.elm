module Evergreen.V370.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V370.Discord
import Evergreen.V370.DmChannelId
import Evergreen.V370.Editable
import Evergreen.V370.Id
import Evergreen.V370.LocalState
import Evergreen.V370.NonemptyDict
import Evergreen.V370.Pagination
import Evergreen.V370.Postmark
import Evergreen.V370.SessionIdHash
import Evergreen.V370.Slack
import Evergreen.V370.Table
import Evergreen.V370.ToBackendLog
import Evergreen.V370.User
import Evergreen.V370.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V370.Id.Id Evergreen.V370.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V370.Id.Id Evergreen.V370.Pagination.ItemId)
    | PressedExpandSection Evergreen.V370.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | UserTableMsg Evergreen.V370.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V370.Editable.Msg (Maybe Evergreen.V370.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V370.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V370.Editable.Msg Evergreen.V370.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V370.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V370.Editable.Msg Evergreen.V370.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V370.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V370.Id.Id Evergreen.V370.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V370.Id.Id Evergreen.V370.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V370.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V370.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V370.NonemptyDict.NonemptyDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Evergreen.V370.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V370.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V370.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V370.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V370.DmChannelId.DmChannelId Evergreen.V370.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId) Evergreen.V370.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) Evergreen.V370.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) Evergreen.V370.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) Evergreen.V370.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V370.Pagination.Pagination Evergreen.V370.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V370.SessionIdHash.SessionIdHash (Evergreen.V370.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V370.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V370.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V370.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V370.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V370.SessionIdHash.SessionIdHash Evergreen.V370.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V370.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V370.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
        }
    | ExpandSection Evergreen.V370.User.AdminUiSection
    | CollapseSection Evergreen.V370.User.AdminUiSection
    | LogPageChanged (Evergreen.V370.Id.Id Evergreen.V370.Pagination.PageId) (Evergreen.V370.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V370.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V370.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V370.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V370.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    | DeleteGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | RestoreGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) (Evergreen.V370.UserSession.ToBeFilledInByBackend (Result Evergreen.V370.Discord.HttpError (List Evergreen.V370.Discord.Role)))
    | ExpandGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | CollapseGuild (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    | HideLog (Evergreen.V370.Id.Id Evergreen.V370.Pagination.ItemId)
    | UnhideLog (Evergreen.V370.Id.Id Evergreen.V370.Pagination.ItemId)
    | DisconnectClient Evergreen.V370.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V370.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V370.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V370.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V370.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V370.Id.Id Evergreen.V370.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V370.Id.Id Evergreen.V370.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V370.Editable.Model
    , publicVapidKey : Evergreen.V370.Editable.Model
    , privateVapidKey : Evergreen.V370.Editable.Model
    , openRouterKey : Evergreen.V370.Editable.Model
    , postmarkKey : Evergreen.V370.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V370.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
