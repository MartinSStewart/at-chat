module Evergreen.V408.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V408.BackendMsgLog
import Evergreen.V408.Discord
import Evergreen.V408.DmChannelId
import Evergreen.V408.Editable
import Evergreen.V408.FileStatus
import Evergreen.V408.Id
import Evergreen.V408.LocalState
import Evergreen.V408.NonemptyDict
import Evergreen.V408.Pagination
import Evergreen.V408.Postmark
import Evergreen.V408.SessionIdHash
import Evergreen.V408.Slack
import Evergreen.V408.Table
import Evergreen.V408.ToBackendLog
import Evergreen.V408.User
import Evergreen.V408.UserSession
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
    = ExistingUserId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V408.Id.Id Evergreen.V408.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V408.Id.Id Evergreen.V408.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | UserTableMsg Evergreen.V408.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V408.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V408.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V408.Slack.Id Evergreen.V408.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V408.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V408.Editable.Msg Evergreen.V408.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V408.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V408.Editable.Msg Evergreen.V408.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V408.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V408.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V408.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V408.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V408.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V408.Pagination.Pagination Evergreen.V408.LocalState.LogWithTime
    , connections : List ( Evergreen.V408.SessionIdHash.SessionIdHash, Evergreen.V408.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V408.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V408.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V408.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V408.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
        }
    | LogPageChanged (Evergreen.V408.Id.Id Evergreen.V408.Pagination.PageId) (Evergreen.V408.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V408.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V408.UserSession.ToBeFilledInByBackend (Evergreen.V408.NonemptyDict.NonemptyDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) Evergreen.V408.User.BackendUser))
    | LoadGuilds (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) Evergreen.V408.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V408.DmChannelId.DmChannelId Evergreen.V408.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) Evergreen.V408.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) Evergreen.V408.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) Evergreen.V408.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) Evergreen.V408.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.DmChannelId) Evergreen.V408.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V408.SessionIdHash.SessionIdHash Evergreen.V408.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V408.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V408.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V408.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V408.FileStatus.FileHash Evergreen.V408.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V408.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V408.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V408.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V408.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V408.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V408.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V408.Slack.Id Evergreen.V408.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | RestoreGuild (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) (Evergreen.V408.UserSession.ToBeFilledInByBackend (Result Evergreen.V408.Discord.HttpError (List Evergreen.V408.Discord.Role)))
    | DisconnectClient Evergreen.V408.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V408.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V408.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V408.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V408.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V408.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V408.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V408.Id.Id Evergreen.V408.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V408.Id.Id Evergreen.V408.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V408.Editable.Model
    , privateVapidKey : Evergreen.V408.Editable.Model
    , openRouterKey : Evergreen.V408.Editable.Model
    , postmarkKey : Evergreen.V408.Editable.Model
    , discordLinkLimit : Evergreen.V408.Editable.Model
    , slackLinkLimit : Evergreen.V408.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V408.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
