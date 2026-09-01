module Evergreen.V365.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V365.Discord
import Evergreen.V365.DmChannelId
import Evergreen.V365.Editable
import Evergreen.V365.Id
import Evergreen.V365.LocalState
import Evergreen.V365.NonemptyDict
import Evergreen.V365.Pagination
import Evergreen.V365.Postmark
import Evergreen.V365.SessionIdHash
import Evergreen.V365.Slack
import Evergreen.V365.Table
import Evergreen.V365.ToBackendLog
import Evergreen.V365.User
import Evergreen.V365.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V365.Id.Id Evergreen.V365.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V365.Id.Id Evergreen.V365.Pagination.ItemId)
    | PressedExpandSection Evergreen.V365.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
    | UserTableMsg Evergreen.V365.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V365.Editable.Msg (Maybe Evergreen.V365.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V365.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V365.Editable.Msg Evergreen.V365.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V365.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V365.Editable.Msg Evergreen.V365.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V365.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V365.Id.Id Evergreen.V365.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V365.Id.Id Evergreen.V365.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V365.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V365.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V365.NonemptyDict.NonemptyDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Evergreen.V365.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V365.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V365.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V365.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V365.DmChannelId.DmChannelId Evergreen.V365.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId) Evergreen.V365.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) Evergreen.V365.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) Evergreen.V365.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) Evergreen.V365.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V365.Pagination.Pagination Evergreen.V365.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V365.SessionIdHash.SessionIdHash (Evergreen.V365.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V365.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V365.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V365.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V365.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V365.SessionIdHash.SessionIdHash Evergreen.V365.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V365.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V365.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
        }
    | ExpandSection Evergreen.V365.User.AdminUiSection
    | CollapseSection Evergreen.V365.User.AdminUiSection
    | LogPageChanged (Evergreen.V365.Id.Id Evergreen.V365.Pagination.PageId) (Evergreen.V365.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V365.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V365.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V365.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V365.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    | DeleteGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | RestoreGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) (Evergreen.V365.UserSession.ToBeFilledInByBackend (Result Evergreen.V365.Discord.HttpError (List Evergreen.V365.Discord.Role)))
    | ExpandGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | CollapseGuild (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    | HideLog (Evergreen.V365.Id.Id Evergreen.V365.Pagination.ItemId)
    | UnhideLog (Evergreen.V365.Id.Id Evergreen.V365.Pagination.ItemId)
    | DisconnectClient Evergreen.V365.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V365.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V365.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V365.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V365.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V365.Id.Id Evergreen.V365.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V365.Id.Id Evergreen.V365.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V365.Editable.Model
    , publicVapidKey : Evergreen.V365.Editable.Model
    , privateVapidKey : Evergreen.V365.Editable.Model
    , openRouterKey : Evergreen.V365.Editable.Model
    , postmarkKey : Evergreen.V365.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , countToFrontend : String
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress
    | ExportBackendFinished
    | DownloadLastBackupResponse Evergreen.V365.LocalState.BackupContents Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
