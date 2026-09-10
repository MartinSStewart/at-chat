module Evergreen.V376.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V376.Discord
import Evergreen.V376.DmChannelId
import Evergreen.V376.Editable
import Evergreen.V376.Id
import Evergreen.V376.LocalState
import Evergreen.V376.NonemptyDict
import Evergreen.V376.Pagination
import Evergreen.V376.Postmark
import Evergreen.V376.SessionIdHash
import Evergreen.V376.Slack
import Evergreen.V376.Table
import Evergreen.V376.ToBackendLog
import Evergreen.V376.User
import Evergreen.V376.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V376.Id.Id Evergreen.V376.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V376.Id.Id Evergreen.V376.Pagination.ItemId)
    | PressedExpandSection Evergreen.V376.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | UserTableMsg Evergreen.V376.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V376.Editable.Msg (Maybe Evergreen.V376.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V376.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V376.Editable.Msg Evergreen.V376.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V376.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V376.Editable.Msg Evergreen.V376.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V376.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V376.Id.Id Evergreen.V376.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V376.Id.Id Evergreen.V376.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V376.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V376.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V376.NonemptyDict.NonemptyDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Evergreen.V376.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V376.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V376.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V376.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V376.DmChannelId.DmChannelId Evergreen.V376.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId) Evergreen.V376.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) Evergreen.V376.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) Evergreen.V376.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) Evergreen.V376.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V376.Pagination.Pagination Evergreen.V376.LocalState.LogWithTime
    , connections : List ( Evergreen.V376.SessionIdHash.SessionIdHash, Evergreen.V376.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V376.LocalState.ConnectionData )
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V376.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V376.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V376.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V376.SessionIdHash.SessionIdHash Evergreen.V376.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V376.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V376.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
        }
    | ExpandSection Evergreen.V376.User.AdminUiSection
    | CollapseSection Evergreen.V376.User.AdminUiSection
    | LogPageChanged (Evergreen.V376.Id.Id Evergreen.V376.Pagination.PageId) (Evergreen.V376.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V376.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V376.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V376.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V376.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    | DeleteGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | RestoreGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) (Evergreen.V376.UserSession.ToBeFilledInByBackend (Result Evergreen.V376.Discord.HttpError (List Evergreen.V376.Discord.Role)))
    | ExpandGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | CollapseGuild (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    | HideLog (Evergreen.V376.Id.Id Evergreen.V376.Pagination.ItemId)
    | UnhideLog (Evergreen.V376.Id.Id Evergreen.V376.Pagination.ItemId)
    | DisconnectClient Evergreen.V376.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V376.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V376.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V376.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V376.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V376.Id.Id Evergreen.V376.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V376.Id.Id Evergreen.V376.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V376.Editable.Model
    , publicVapidKey : Evergreen.V376.Editable.Model
    , privateVapidKey : Evergreen.V376.Editable.Model
    , openRouterKey : Evergreen.V376.Editable.Model
    , postmarkKey : Evergreen.V376.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V376.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
