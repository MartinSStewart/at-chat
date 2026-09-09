module Evergreen.V375.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V375.Discord
import Evergreen.V375.DmChannelId
import Evergreen.V375.Editable
import Evergreen.V375.Id
import Evergreen.V375.LocalState
import Evergreen.V375.NonemptyDict
import Evergreen.V375.Pagination
import Evergreen.V375.Postmark
import Evergreen.V375.SessionIdHash
import Evergreen.V375.Slack
import Evergreen.V375.Table
import Evergreen.V375.ToBackendLog
import Evergreen.V375.User
import Evergreen.V375.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V375.Id.Id Evergreen.V375.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V375.Id.Id Evergreen.V375.Pagination.ItemId)
    | PressedExpandSection Evergreen.V375.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | UserTableMsg Evergreen.V375.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V375.Editable.Msg (Maybe Evergreen.V375.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V375.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V375.Editable.Msg Evergreen.V375.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V375.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V375.Editable.Msg Evergreen.V375.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V375.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V375.Id.Id Evergreen.V375.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V375.Id.Id Evergreen.V375.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V375.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V375.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V375.NonemptyDict.NonemptyDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V375.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V375.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V375.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V375.DmChannelId.DmChannelId Evergreen.V375.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId) Evergreen.V375.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) Evergreen.V375.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) Evergreen.V375.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) Evergreen.V375.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V375.Pagination.Pagination Evergreen.V375.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V375.SessionIdHash.SessionIdHash (Evergreen.V375.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V375.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V375.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V375.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V375.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V375.SessionIdHash.SessionIdHash Evergreen.V375.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V375.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V375.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
        }
    | ExpandSection Evergreen.V375.User.AdminUiSection
    | CollapseSection Evergreen.V375.User.AdminUiSection
    | LogPageChanged (Evergreen.V375.Id.Id Evergreen.V375.Pagination.PageId) (Evergreen.V375.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V375.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V375.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V375.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V375.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    | DeleteGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | RestoreGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) (Evergreen.V375.UserSession.ToBeFilledInByBackend (Result Evergreen.V375.Discord.HttpError (List Evergreen.V375.Discord.Role)))
    | ExpandGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | CollapseGuild (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    | HideLog (Evergreen.V375.Id.Id Evergreen.V375.Pagination.ItemId)
    | UnhideLog (Evergreen.V375.Id.Id Evergreen.V375.Pagination.ItemId)
    | DisconnectClient Evergreen.V375.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V375.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V375.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V375.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V375.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V375.Id.Id Evergreen.V375.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V375.Id.Id Evergreen.V375.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V375.Editable.Model
    , publicVapidKey : Evergreen.V375.Editable.Model
    , privateVapidKey : Evergreen.V375.Editable.Model
    , openRouterKey : Evergreen.V375.Editable.Model
    , postmarkKey : Evergreen.V375.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V375.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
