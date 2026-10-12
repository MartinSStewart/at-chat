module Evergreen.V405.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V405.BackendMsgLog
import Evergreen.V405.Discord
import Evergreen.V405.DmChannelId
import Evergreen.V405.Editable
import Evergreen.V405.FileStatus
import Evergreen.V405.Id
import Evergreen.V405.LocalState
import Evergreen.V405.NonemptyDict
import Evergreen.V405.Pagination
import Evergreen.V405.Postmark
import Evergreen.V405.SessionIdHash
import Evergreen.V405.Slack
import Evergreen.V405.Table
import Evergreen.V405.ToBackendLog
import Evergreen.V405.User
import Evergreen.V405.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DmChannelsSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
    | SlackWorkspacesSection
    | SlackDmChannelsSection
    | GuildsSection
    | DeletedGuildsSection
    | ApiKeysSection
    | ExportSection
    | ConnectionsSection
    | FilesSection
    | UpdateLogsSection
    | StickersAndEmojisSection
    | WebsocketCloseEventsSection
    | SessionsSection
    | WordSpellingGameSwedishSection


type UserTableId
    = ExistingUserId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V405.Id.Id Evergreen.V405.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V405.Id.Id Evergreen.V405.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | UserTableMsg Evergreen.V405.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V405.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V405.Slack.Id Evergreen.V405.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V405.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V405.Editable.Msg Evergreen.V405.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V405.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V405.Editable.Msg Evergreen.V405.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V405.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V405.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V405.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V405.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V405.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V405.Pagination.Pagination Evergreen.V405.LocalState.LogWithTime
    , connections : List ( Evergreen.V405.SessionIdHash.SessionIdHash, Evergreen.V405.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V405.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V405.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V405.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V405.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
        }
    | LogPageChanged (Evergreen.V405.Id.Id Evergreen.V405.Pagination.PageId) (Evergreen.V405.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V405.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V405.UserSession.ToBeFilledInByBackend (Evergreen.V405.NonemptyDict.NonemptyDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.User.BackendUser))
    | LoadGuilds (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) Evergreen.V405.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V405.DmChannelId.DmChannelId Evergreen.V405.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) Evergreen.V405.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) Evergreen.V405.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) Evergreen.V405.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId) Evergreen.V405.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V405.Slack.Id Evergreen.V405.Slack.DmChannelId) Evergreen.V405.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V405.SessionIdHash.SessionIdHash Evergreen.V405.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V405.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V405.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V405.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V405.FileStatus.FileHash Evergreen.V405.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V405.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V405.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V405.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V405.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V405.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V405.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V405.Slack.Id Evergreen.V405.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | RestoreGuild (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.UserSession.ToBeFilledInByBackend (Result Evergreen.V405.Discord.HttpError (List Evergreen.V405.Discord.Role)))
    | DisconnectClient Evergreen.V405.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V405.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V405.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V405.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V405.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V405.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V405.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V405.Id.Id Evergreen.V405.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V405.Id.Id Evergreen.V405.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V405.Editable.Model
    , privateVapidKey : Evergreen.V405.Editable.Model
    , openRouterKey : Evergreen.V405.Editable.Model
    , postmarkKey : Evergreen.V405.Editable.Model
    , discordLinkLimit : Evergreen.V405.Editable.Model
    , importBackendStatus : ImportBackendStatus
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
    | DownloadLastBackupChunk Evergreen.V405.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
