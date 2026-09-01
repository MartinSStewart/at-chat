module Evergreen.V366.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V366.Discord
import Evergreen.V366.DmChannelId
import Evergreen.V366.Editable
import Evergreen.V366.Id
import Evergreen.V366.LocalState
import Evergreen.V366.NonemptyDict
import Evergreen.V366.Pagination
import Evergreen.V366.Postmark
import Evergreen.V366.SessionIdHash
import Evergreen.V366.Slack
import Evergreen.V366.Table
import Evergreen.V366.ToBackendLog
import Evergreen.V366.User
import Evergreen.V366.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V366.Id.Id Evergreen.V366.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V366.Id.Id Evergreen.V366.Pagination.ItemId)
    | PressedExpandSection Evergreen.V366.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
    | UserTableMsg Evergreen.V366.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V366.Editable.Msg (Maybe Evergreen.V366.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V366.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V366.Editable.Msg Evergreen.V366.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V366.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V366.Editable.Msg Evergreen.V366.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V366.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V366.Id.Id Evergreen.V366.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V366.Id.Id Evergreen.V366.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V366.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V366.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V366.NonemptyDict.NonemptyDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V366.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V366.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V366.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V366.DmChannelId.DmChannelId Evergreen.V366.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId) Evergreen.V366.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) Evergreen.V366.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) Evergreen.V366.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) Evergreen.V366.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V366.Pagination.Pagination Evergreen.V366.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V366.SessionIdHash.SessionIdHash (Evergreen.V366.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V366.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V366.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V366.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V366.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V366.SessionIdHash.SessionIdHash Evergreen.V366.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V366.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V366.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
        }
    | ExpandSection Evergreen.V366.User.AdminUiSection
    | CollapseSection Evergreen.V366.User.AdminUiSection
    | LogPageChanged (Evergreen.V366.Id.Id Evergreen.V366.Pagination.PageId) (Evergreen.V366.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V366.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V366.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V366.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V366.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    | DeleteGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | RestoreGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) (Evergreen.V366.UserSession.ToBeFilledInByBackend (Result Evergreen.V366.Discord.HttpError (List Evergreen.V366.Discord.Role)))
    | ExpandGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | CollapseGuild (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    | HideLog (Evergreen.V366.Id.Id Evergreen.V366.Pagination.ItemId)
    | UnhideLog (Evergreen.V366.Id.Id Evergreen.V366.Pagination.ItemId)
    | DisconnectClient Evergreen.V366.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V366.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V366.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V366.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V366.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V366.Id.Id Evergreen.V366.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V366.Id.Id Evergreen.V366.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V366.Editable.Model
    , publicVapidKey : Evergreen.V366.Editable.Model
    , privateVapidKey : Evergreen.V366.Editable.Model
    , openRouterKey : Evergreen.V366.Editable.Model
    , postmarkKey : Evergreen.V366.Editable.Model
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
    | DownloadLastBackupResponse Evergreen.V366.LocalState.BackupContents Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
