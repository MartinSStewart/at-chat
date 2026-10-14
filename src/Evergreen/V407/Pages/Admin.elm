module Evergreen.V407.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V407.BackendMsgLog
import Evergreen.V407.Discord
import Evergreen.V407.DmChannelId
import Evergreen.V407.Editable
import Evergreen.V407.FileStatus
import Evergreen.V407.Id
import Evergreen.V407.LocalState
import Evergreen.V407.NonemptyDict
import Evergreen.V407.Pagination
import Evergreen.V407.Postmark
import Evergreen.V407.SessionIdHash
import Evergreen.V407.Slack
import Evergreen.V407.Table
import Evergreen.V407.ToBackendLog
import Evergreen.V407.User
import Evergreen.V407.UserSession
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
    = ExistingUserId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V407.Id.Id Evergreen.V407.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V407.Id.Id Evergreen.V407.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | UserTableMsg Evergreen.V407.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V407.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V407.Slack.Id Evergreen.V407.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V407.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V407.Editable.Msg Evergreen.V407.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V407.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V407.Editable.Msg Evergreen.V407.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V407.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V407.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V407.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V407.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V407.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V407.Pagination.Pagination Evergreen.V407.LocalState.LogWithTime
    , connections : List ( Evergreen.V407.SessionIdHash.SessionIdHash, Evergreen.V407.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V407.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V407.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V407.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V407.LocalState.WordSpellingGameStatus
    , seqDictWorks : List ( String, Int )
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
        }
    | LogPageChanged (Evergreen.V407.Id.Id Evergreen.V407.Pagination.PageId) (Evergreen.V407.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V407.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V407.UserSession.ToBeFilledInByBackend (Evergreen.V407.NonemptyDict.NonemptyDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.User.BackendUser))
    | LoadGuilds (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) Evergreen.V407.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V407.DmChannelId.DmChannelId Evergreen.V407.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) Evergreen.V407.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) Evergreen.V407.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) Evergreen.V407.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId) Evergreen.V407.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V407.Slack.Id Evergreen.V407.Slack.DmChannelId) Evergreen.V407.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V407.SessionIdHash.SessionIdHash Evergreen.V407.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V407.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V407.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V407.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V407.FileStatus.FileHash Evergreen.V407.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V407.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V407.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V407.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V407.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V407.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V407.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V407.Slack.Id Evergreen.V407.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | RestoreGuild (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) (Evergreen.V407.UserSession.ToBeFilledInByBackend (Result Evergreen.V407.Discord.HttpError (List Evergreen.V407.Discord.Role)))
    | DisconnectClient Evergreen.V407.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V407.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V407.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V407.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V407.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V407.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V407.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V407.Id.Id Evergreen.V407.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V407.Id.Id Evergreen.V407.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V407.Editable.Model
    , privateVapidKey : Evergreen.V407.Editable.Model
    , openRouterKey : Evergreen.V407.Editable.Model
    , postmarkKey : Evergreen.V407.Editable.Model
    , discordLinkLimit : Evergreen.V407.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V407.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
