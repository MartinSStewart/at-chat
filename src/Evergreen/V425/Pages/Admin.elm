module Evergreen.V425.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V425.BackendMsgLog
import Evergreen.V425.Discord
import Evergreen.V425.DmChannelId
import Evergreen.V425.Editable
import Evergreen.V425.FileStatus
import Evergreen.V425.Id
import Evergreen.V425.LocalState
import Evergreen.V425.NonemptyDict
import Evergreen.V425.Pagination
import Evergreen.V425.Postmark
import Evergreen.V425.SessionIdHash
import Evergreen.V425.Slack
import Evergreen.V425.Table
import Evergreen.V425.ToBackendLog
import Evergreen.V425.User
import Evergreen.V425.UserSession
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
    = ExistingUserId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V425.Id.Id Evergreen.V425.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V425.Id.Id Evergreen.V425.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | UserTableMsg Evergreen.V425.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V425.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V425.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V425.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V425.Editable.Msg Evergreen.V425.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V425.Editable.Msg (Maybe String))
    | NotifyAdminsTokenEditableMsg (Evergreen.V425.Editable.Msg (Maybe String))
    | NotifyAdminsBotUserIdEditableMsg (Evergreen.V425.Editable.Msg (Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)))
    | PostmarkKeyEditableMsg (Evergreen.V425.Editable.Msg Evergreen.V425.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V425.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V425.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V425.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V425.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    , postmarkApiKey : Evergreen.V425.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V425.Pagination.Pagination Evergreen.V425.LocalState.LogWithTime
    , connections : List ( Evergreen.V425.SessionIdHash.SessionIdHash, Evergreen.V425.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V425.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V425.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V425.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V425.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
        }
    | LogPageChanged (Evergreen.V425.Id.Id Evergreen.V425.Pagination.PageId) (Evergreen.V425.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V425.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V425.UserSession.ToBeFilledInByBackend (Evergreen.V425.NonemptyDict.NonemptyDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.User.BackendUser))
    | LoadGuilds (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) Evergreen.V425.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V425.DmChannelId.DmChannelId Evergreen.V425.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) Evergreen.V425.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) Evergreen.V425.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) Evergreen.V425.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) Evergreen.V425.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) Evergreen.V425.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V425.SessionIdHash.SessionIdHash Evergreen.V425.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V425.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V425.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V425.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V425.FileStatus.FileHash Evergreen.V425.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V425.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V425.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V425.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V425.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V425.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetNotifyAdminsToken (Maybe String)
    | SetNotifyAdminsBotUserId (Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    | SetPostmarkKey Evergreen.V425.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | RestoreGuild (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) (Evergreen.V425.UserSession.ToBeFilledInByBackend (Result Evergreen.V425.Discord.HttpError (List Evergreen.V425.Discord.Role)))
    | DisconnectClient Evergreen.V425.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V425.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V425.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V425.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V425.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V425.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V425.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V425.Editable.Model
    , privateVapidKey : Evergreen.V425.Editable.Model
    , openRouterKey : Evergreen.V425.Editable.Model
    , notifyAdminsToken : Evergreen.V425.Editable.Model
    , notifyAdminsBotUserId : Evergreen.V425.Editable.Model
    , postmarkKey : Evergreen.V425.Editable.Model
    , discordLinkLimit : Evergreen.V425.Editable.Model
    , slackLinkLimit : Evergreen.V425.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V425.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
