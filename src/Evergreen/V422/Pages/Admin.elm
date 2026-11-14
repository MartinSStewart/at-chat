module Evergreen.V422.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V422.BackendMsgLog
import Evergreen.V422.Discord
import Evergreen.V422.DmChannelId
import Evergreen.V422.Editable
import Evergreen.V422.FileStatus
import Evergreen.V422.Id
import Evergreen.V422.LocalState
import Evergreen.V422.NonemptyDict
import Evergreen.V422.Pagination
import Evergreen.V422.Postmark
import Evergreen.V422.SessionIdHash
import Evergreen.V422.Slack
import Evergreen.V422.Table
import Evergreen.V422.ToBackendLog
import Evergreen.V422.User
import Evergreen.V422.UserSession
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
    = ExistingUserId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V422.Id.Id Evergreen.V422.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V422.Id.Id Evergreen.V422.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | UserTableMsg Evergreen.V422.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V422.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V422.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V422.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V422.Editable.Msg Evergreen.V422.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V422.Editable.Msg (Maybe String))
    | NotifyAdminsTokenEditableMsg (Evergreen.V422.Editable.Msg (Maybe String))
    | NotifyAdminsBotUserIdEditableMsg (Evergreen.V422.Editable.Msg (Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)))
    | PostmarkKeyEditableMsg (Evergreen.V422.Editable.Msg Evergreen.V422.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V422.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V422.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V422.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V422.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    , postmarkApiKey : Evergreen.V422.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V422.Pagination.Pagination Evergreen.V422.LocalState.LogWithTime
    , connections : List ( Evergreen.V422.SessionIdHash.SessionIdHash, Evergreen.V422.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V422.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V422.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V422.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V422.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
        }
    | LogPageChanged (Evergreen.V422.Id.Id Evergreen.V422.Pagination.PageId) (Evergreen.V422.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V422.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V422.UserSession.ToBeFilledInByBackend (Evergreen.V422.NonemptyDict.NonemptyDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.User.BackendUser))
    | LoadGuilds (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) Evergreen.V422.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V422.DmChannelId.DmChannelId Evergreen.V422.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) Evergreen.V422.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) Evergreen.V422.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) Evergreen.V422.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) Evergreen.V422.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) Evergreen.V422.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V422.SessionIdHash.SessionIdHash Evergreen.V422.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V422.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V422.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V422.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V422.FileStatus.FileHash Evergreen.V422.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V422.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V422.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V422.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V422.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V422.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetNotifyAdminsToken (Maybe String)
    | SetNotifyAdminsBotUserId (Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    | SetPostmarkKey Evergreen.V422.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | RestoreGuild (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) (Evergreen.V422.UserSession.ToBeFilledInByBackend (Result Evergreen.V422.Discord.HttpError (List Evergreen.V422.Discord.Role)))
    | DisconnectClient Evergreen.V422.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V422.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V422.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V422.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V422.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V422.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V422.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V422.Id.Id Evergreen.V422.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V422.Id.Id Evergreen.V422.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V422.Editable.Model
    , privateVapidKey : Evergreen.V422.Editable.Model
    , openRouterKey : Evergreen.V422.Editable.Model
    , notifyAdminsToken : Evergreen.V422.Editable.Model
    , notifyAdminsBotUserId : Evergreen.V422.Editable.Model
    , postmarkKey : Evergreen.V422.Editable.Model
    , discordLinkLimit : Evergreen.V422.Editable.Model
    , slackLinkLimit : Evergreen.V422.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V422.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
