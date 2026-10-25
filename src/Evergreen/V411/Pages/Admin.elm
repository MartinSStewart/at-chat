module Evergreen.V411.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V411.BackendMsgLog
import Evergreen.V411.Discord
import Evergreen.V411.DmChannelId
import Evergreen.V411.Editable
import Evergreen.V411.FileStatus
import Evergreen.V411.Id
import Evergreen.V411.LocalState
import Evergreen.V411.NonemptyDict
import Evergreen.V411.Pagination
import Evergreen.V411.Postmark
import Evergreen.V411.SessionIdHash
import Evergreen.V411.Slack
import Evergreen.V411.Table
import Evergreen.V411.ToBackendLog
import Evergreen.V411.User
import Evergreen.V411.UserSession
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
    = ExistingUserId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V411.Id.Id Evergreen.V411.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V411.Id.Id Evergreen.V411.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
    | UserTableMsg Evergreen.V411.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V411.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V411.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V411.Slack.Id Evergreen.V411.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V411.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V411.Editable.Msg Evergreen.V411.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V411.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V411.Editable.Msg Evergreen.V411.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V411.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V411.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V411.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V411.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V411.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V411.Pagination.Pagination Evergreen.V411.LocalState.LogWithTime
    , connections : List ( Evergreen.V411.SessionIdHash.SessionIdHash, Evergreen.V411.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V411.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V411.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V411.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V411.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
        }
    | LogPageChanged (Evergreen.V411.Id.Id Evergreen.V411.Pagination.PageId) (Evergreen.V411.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V411.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V411.UserSession.ToBeFilledInByBackend (Evergreen.V411.NonemptyDict.NonemptyDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) Evergreen.V411.User.BackendUser))
    | LoadGuilds (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) Evergreen.V411.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) Evergreen.V411.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V411.DmChannelId.DmChannelId Evergreen.V411.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) Evergreen.V411.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId) Evergreen.V411.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) Evergreen.V411.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId) Evergreen.V411.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.DmChannelId) Evergreen.V411.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V411.SessionIdHash.SessionIdHash Evergreen.V411.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V411.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V411.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V411.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V411.FileStatus.FileHash Evergreen.V411.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V411.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V411.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V411.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V411.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V411.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V411.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V411.Slack.Id Evergreen.V411.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    | RestoreGuild (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) (Evergreen.V411.UserSession.ToBeFilledInByBackend (Result Evergreen.V411.Discord.HttpError (List Evergreen.V411.Discord.Role)))
    | DisconnectClient Evergreen.V411.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V411.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V411.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V411.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V411.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V411.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V411.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V411.Id.Id Evergreen.V411.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V411.Id.Id Evergreen.V411.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V411.Editable.Model
    , privateVapidKey : Evergreen.V411.Editable.Model
    , openRouterKey : Evergreen.V411.Editable.Model
    , postmarkKey : Evergreen.V411.Editable.Model
    , discordLinkLimit : Evergreen.V411.Editable.Model
    , slackLinkLimit : Evergreen.V411.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V411.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
