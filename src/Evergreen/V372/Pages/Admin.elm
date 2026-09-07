module Evergreen.V372.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V372.Discord
import Evergreen.V372.DmChannelId
import Evergreen.V372.Editable
import Evergreen.V372.Id
import Evergreen.V372.LocalState
import Evergreen.V372.NonemptyDict
import Evergreen.V372.Pagination
import Evergreen.V372.Postmark
import Evergreen.V372.SessionIdHash
import Evergreen.V372.Slack
import Evergreen.V372.Table
import Evergreen.V372.ToBackendLog
import Evergreen.V372.User
import Evergreen.V372.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V372.Id.Id Evergreen.V372.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V372.Id.Id Evergreen.V372.Pagination.ItemId)
    | PressedExpandSection Evergreen.V372.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | UserTableMsg Evergreen.V372.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V372.Editable.Msg (Maybe Evergreen.V372.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V372.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V372.Editable.Msg Evergreen.V372.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V372.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V372.Editable.Msg Evergreen.V372.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V372.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V372.Id.Id Evergreen.V372.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V372.Id.Id Evergreen.V372.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V372.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V372.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V372.NonemptyDict.NonemptyDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V372.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V372.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V372.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V372.DmChannelId.DmChannelId Evergreen.V372.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId) Evergreen.V372.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) Evergreen.V372.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) Evergreen.V372.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) Evergreen.V372.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V372.Pagination.Pagination Evergreen.V372.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V372.SessionIdHash.SessionIdHash (Evergreen.V372.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V372.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V372.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V372.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V372.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V372.SessionIdHash.SessionIdHash Evergreen.V372.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V372.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V372.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
        }
    | ExpandSection Evergreen.V372.User.AdminUiSection
    | CollapseSection Evergreen.V372.User.AdminUiSection
    | LogPageChanged (Evergreen.V372.Id.Id Evergreen.V372.Pagination.PageId) (Evergreen.V372.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V372.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V372.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V372.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V372.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    | DeleteGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | RestoreGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) (Evergreen.V372.UserSession.ToBeFilledInByBackend (Result Evergreen.V372.Discord.HttpError (List Evergreen.V372.Discord.Role)))
    | ExpandGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | CollapseGuild (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    | HideLog (Evergreen.V372.Id.Id Evergreen.V372.Pagination.ItemId)
    | UnhideLog (Evergreen.V372.Id.Id Evergreen.V372.Pagination.ItemId)
    | DisconnectClient Evergreen.V372.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V372.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V372.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V372.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V372.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V372.Id.Id Evergreen.V372.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V372.Id.Id Evergreen.V372.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V372.Editable.Model
    , publicVapidKey : Evergreen.V372.Editable.Model
    , privateVapidKey : Evergreen.V372.Editable.Model
    , openRouterKey : Evergreen.V372.Editable.Model
    , postmarkKey : Evergreen.V372.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V372.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
