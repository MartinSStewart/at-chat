module Evergreen.V421.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V421.BackendMsgLog
import Evergreen.V421.Discord
import Evergreen.V421.DmChannelId
import Evergreen.V421.Editable
import Evergreen.V421.FileStatus
import Evergreen.V421.Id
import Evergreen.V421.LocalState
import Evergreen.V421.NonemptyDict
import Evergreen.V421.Pagination
import Evergreen.V421.Postmark
import Evergreen.V421.SessionIdHash
import Evergreen.V421.Slack
import Evergreen.V421.Table
import Evergreen.V421.ToBackendLog
import Evergreen.V421.User
import Evergreen.V421.UserSession
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
    = ExistingUserId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V421.Id.Id Evergreen.V421.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V421.Id.Id Evergreen.V421.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | UserTableMsg Evergreen.V421.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V421.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V421.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V421.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V421.Editable.Msg Evergreen.V421.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V421.Editable.Msg (Maybe String))
    | NotifyAdminsTokenEditableMsg (Evergreen.V421.Editable.Msg (Maybe String))
    | NotifyAdminsBotUserIdEditableMsg (Evergreen.V421.Editable.Msg (Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)))
    | PostmarkKeyEditableMsg (Evergreen.V421.Editable.Msg Evergreen.V421.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V421.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V421.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V421.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V421.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    , postmarkApiKey : Evergreen.V421.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V421.Pagination.Pagination Evergreen.V421.LocalState.LogWithTime
    , connections : List ( Evergreen.V421.SessionIdHash.SessionIdHash, Evergreen.V421.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V421.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V421.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V421.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V421.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
        }
    | LogPageChanged (Evergreen.V421.Id.Id Evergreen.V421.Pagination.PageId) (Evergreen.V421.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V421.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V421.UserSession.ToBeFilledInByBackend (Evergreen.V421.NonemptyDict.NonemptyDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.User.BackendUser))
    | LoadGuilds (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) Evergreen.V421.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V421.DmChannelId.DmChannelId Evergreen.V421.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) Evergreen.V421.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) Evergreen.V421.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) Evergreen.V421.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) Evergreen.V421.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId) Evergreen.V421.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V421.SessionIdHash.SessionIdHash Evergreen.V421.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V421.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V421.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V421.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V421.FileStatus.FileHash Evergreen.V421.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V421.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V421.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V421.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V421.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V421.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetNotifyAdminsToken (Maybe String)
    | SetNotifyAdminsBotUserId (Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    | SetPostmarkKey Evergreen.V421.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | RestoreGuild (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) (Evergreen.V421.UserSession.ToBeFilledInByBackend (Result Evergreen.V421.Discord.HttpError (List Evergreen.V421.Discord.Role)))
    | DisconnectClient Evergreen.V421.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V421.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V421.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V421.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V421.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V421.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V421.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V421.Editable.Model
    , privateVapidKey : Evergreen.V421.Editable.Model
    , openRouterKey : Evergreen.V421.Editable.Model
    , notifyAdminsToken : Evergreen.V421.Editable.Model
    , notifyAdminsBotUserId : Evergreen.V421.Editable.Model
    , postmarkKey : Evergreen.V421.Editable.Model
    , discordLinkLimit : Evergreen.V421.Editable.Model
    , slackLinkLimit : Evergreen.V421.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V421.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
