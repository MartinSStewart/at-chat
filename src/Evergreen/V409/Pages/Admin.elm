module Evergreen.V409.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V409.BackendMsgLog
import Evergreen.V409.Discord
import Evergreen.V409.DmChannelId
import Evergreen.V409.Editable
import Evergreen.V409.FileStatus
import Evergreen.V409.Id
import Evergreen.V409.LocalState
import Evergreen.V409.NonemptyDict
import Evergreen.V409.Pagination
import Evergreen.V409.Postmark
import Evergreen.V409.SessionIdHash
import Evergreen.V409.Slack
import Evergreen.V409.Table
import Evergreen.V409.ToBackendLog
import Evergreen.V409.User
import Evergreen.V409.UserSession
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
    = ExistingUserId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V409.Id.Id Evergreen.V409.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V409.Id.Id Evergreen.V409.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | UserTableMsg Evergreen.V409.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V409.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V409.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V409.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V409.Editable.Msg Evergreen.V409.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V409.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V409.Editable.Msg Evergreen.V409.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V409.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V409.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V409.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V409.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V409.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V409.Pagination.Pagination Evergreen.V409.LocalState.LogWithTime
    , connections : List ( Evergreen.V409.SessionIdHash.SessionIdHash, Evergreen.V409.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V409.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V409.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V409.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V409.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
        }
    | LogPageChanged (Evergreen.V409.Id.Id Evergreen.V409.Pagination.PageId) (Evergreen.V409.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V409.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V409.UserSession.ToBeFilledInByBackend (Evergreen.V409.NonemptyDict.NonemptyDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.User.BackendUser))
    | LoadGuilds (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) Evergreen.V409.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V409.DmChannelId.DmChannelId Evergreen.V409.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) Evergreen.V409.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) Evergreen.V409.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) Evergreen.V409.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) Evergreen.V409.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId) Evergreen.V409.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V409.SessionIdHash.SessionIdHash Evergreen.V409.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V409.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V409.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V409.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V409.FileStatus.FileHash Evergreen.V409.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V409.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V409.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V409.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V409.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V409.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V409.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | RestoreGuild (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) (Evergreen.V409.UserSession.ToBeFilledInByBackend (Result Evergreen.V409.Discord.HttpError (List Evergreen.V409.Discord.Role)))
    | DisconnectClient Evergreen.V409.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V409.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V409.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V409.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V409.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V409.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V409.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V409.Id.Id Evergreen.V409.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V409.Id.Id Evergreen.V409.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V409.Editable.Model
    , privateVapidKey : Evergreen.V409.Editable.Model
    , openRouterKey : Evergreen.V409.Editable.Model
    , postmarkKey : Evergreen.V409.Editable.Model
    , discordLinkLimit : Evergreen.V409.Editable.Model
    , slackLinkLimit : Evergreen.V409.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V409.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
