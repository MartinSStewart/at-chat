module Evergreen.V406.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V406.BackendMsgLog
import Evergreen.V406.Discord
import Evergreen.V406.DmChannelId
import Evergreen.V406.Editable
import Evergreen.V406.FileStatus
import Evergreen.V406.Id
import Evergreen.V406.LocalState
import Evergreen.V406.NonemptyDict
import Evergreen.V406.Pagination
import Evergreen.V406.Postmark
import Evergreen.V406.SessionIdHash
import Evergreen.V406.Slack
import Evergreen.V406.Table
import Evergreen.V406.ToBackendLog
import Evergreen.V406.User
import Evergreen.V406.UserSession
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
    = ExistingUserId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V406.Id.Id Evergreen.V406.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V406.Id.Id Evergreen.V406.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | UserTableMsg Evergreen.V406.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V406.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V406.Slack.Id Evergreen.V406.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V406.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V406.Editable.Msg Evergreen.V406.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V406.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V406.Editable.Msg Evergreen.V406.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V406.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V406.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V406.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V406.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V406.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V406.Pagination.Pagination Evergreen.V406.LocalState.LogWithTime
    , connections : List ( Evergreen.V406.SessionIdHash.SessionIdHash, Evergreen.V406.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V406.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V406.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V406.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V406.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
        }
    | LogPageChanged (Evergreen.V406.Id.Id Evergreen.V406.Pagination.PageId) (Evergreen.V406.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V406.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V406.UserSession.ToBeFilledInByBackend (Evergreen.V406.NonemptyDict.NonemptyDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) Evergreen.V406.User.BackendUser))
    | LoadGuilds (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) Evergreen.V406.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V406.DmChannelId.DmChannelId Evergreen.V406.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) Evergreen.V406.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId) Evergreen.V406.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) Evergreen.V406.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId) Evergreen.V406.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V406.Slack.Id Evergreen.V406.Slack.DmChannelId) Evergreen.V406.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V406.SessionIdHash.SessionIdHash Evergreen.V406.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V406.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V406.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V406.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V406.FileStatus.FileHash Evergreen.V406.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V406.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V406.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V406.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V406.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V406.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V406.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V406.Slack.Id Evergreen.V406.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | RestoreGuild (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId) (Evergreen.V406.UserSession.ToBeFilledInByBackend (Result Evergreen.V406.Discord.HttpError (List Evergreen.V406.Discord.Role)))
    | DisconnectClient Evergreen.V406.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V406.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V406.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V406.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V406.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V406.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V406.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V406.Id.Id Evergreen.V406.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V406.Id.Id Evergreen.V406.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V406.Editable.Model
    , privateVapidKey : Evergreen.V406.Editable.Model
    , openRouterKey : Evergreen.V406.Editable.Model
    , postmarkKey : Evergreen.V406.Editable.Model
    , discordLinkLimit : Evergreen.V406.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V406.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
