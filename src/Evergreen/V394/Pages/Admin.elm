module Evergreen.V394.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V394.BackendMsgLog
import Evergreen.V394.Discord
import Evergreen.V394.DmChannelId
import Evergreen.V394.Editable
import Evergreen.V394.FileStatus
import Evergreen.V394.Id
import Evergreen.V394.LocalState
import Evergreen.V394.NonemptyDict
import Evergreen.V394.Pagination
import Evergreen.V394.Postmark
import Evergreen.V394.SessionIdHash
import Evergreen.V394.Slack
import Evergreen.V394.Table
import Evergreen.V394.ToBackendLog
import Evergreen.V394.User
import Evergreen.V394.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DmChannelsSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | GuildsSection
    | DeletedGuildsSection
    | ApiKeysSection
    | ExportSection
    | ConnectionsSection
    | FilesSection
    | ToBackendLogsSection
    | BackendMsgLogsSection
    | StickersAndEmojisSection
    | WebsocketCloseEventsSection
    | SessionsSection
    | WordSpellingGameSwedishSection
    | WebCodecsTestSection


type UserTableId
    = ExistingUserId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V394.Id.Id Evergreen.V394.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V394.Id.Id Evergreen.V394.Pagination.ItemId)
    | PressedExpandSection AdminUiSection
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
    | PressedResetUser (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | UserTableMsg Evergreen.V394.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V394.Editable.Msg (Maybe Evergreen.V394.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V394.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V394.Editable.Msg Evergreen.V394.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V394.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V394.Editable.Msg Evergreen.V394.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V394.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V394.Id.Id Evergreen.V394.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V394.Id.Id Evergreen.V394.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V394.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V394.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V394.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V394.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V394.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V394.Pagination.Pagination Evergreen.V394.LocalState.LogWithTime
    , connections : List ( Evergreen.V394.SessionIdHash.SessionIdHash, Evergreen.V394.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V394.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V394.LocalState.LastBackup
    , invalidChannelNames : List Evergreen.V394.LocalState.AdminData_InvalidChannelName
    , wordSpellingGameEnglish : Evergreen.V394.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V394.LocalState.WordSpellingGameStatus
    }


type alias EditedBackendUser =
    { name : String
    , email : String
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    , deleteAccountAt : Maybe Effect.Time.Posix
    }


type AdminChange
    = ChangeUsers
        { time : Effect.Time.Posix
        , changedUsers : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
        }
    | LogPageChanged (Evergreen.V394.Id.Id Evergreen.V394.Pagination.PageId) (Evergreen.V394.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V394.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V394.UserSession.ToBeFilledInByBackend (Evergreen.V394.NonemptyDict.NonemptyDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.User.BackendUser))
    | LoadGuilds (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) Evergreen.V394.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V394.DmChannelId.DmChannelId Evergreen.V394.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) Evergreen.V394.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId) Evergreen.V394.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) Evergreen.V394.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V394.SessionIdHash.SessionIdHash Evergreen.V394.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V394.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V394.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V394.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V394.FileStatus.FileHash Evergreen.V394.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V394.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V394.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V394.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V394.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V394.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V394.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V394.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    | DeleteGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | RestoreGuild (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) (Evergreen.V394.UserSession.ToBeFilledInByBackend (Result Evergreen.V394.Discord.HttpError (List Evergreen.V394.Discord.Role)))
    | HideLog (Evergreen.V394.Id.Id Evergreen.V394.Pagination.ItemId)
    | UnhideLog (Evergreen.V394.Id.Id Evergreen.V394.Pagination.ItemId)
    | DisconnectClient Evergreen.V394.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V394.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V394.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V394.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V394.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V394.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
        { remainingBytes : Bytes.Bytes
        , sentBytes : Int
        , totalBytes : Int
        }
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
    { guilds : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V394.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V394.Id.Id Evergreen.V394.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V394.Id.Id Evergreen.V394.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V394.Editable.Model
    , publicVapidKey : Evergreen.V394.Editable.Model
    , privateVapidKey : Evergreen.V394.Editable.Model
    , openRouterKey : Evergreen.V394.Editable.Model
    , postmarkKey : Evergreen.V394.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , downloadingBackup : Maybe DownloadingBackup
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ImportBackendChunkReceived Int
    | ExportBackendProgress ExportSubset ExportProgress
    | ExportBackendFinished
    | DownloadLastBackupChunk Evergreen.V394.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
