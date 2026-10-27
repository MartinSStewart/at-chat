module Evergreen.V417.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V417.BackendMsgLog
import Evergreen.V417.Discord
import Evergreen.V417.DmChannelId
import Evergreen.V417.Editable
import Evergreen.V417.FileStatus
import Evergreen.V417.Id
import Evergreen.V417.LocalState
import Evergreen.V417.NonemptyDict
import Evergreen.V417.Pagination
import Evergreen.V417.Postmark
import Evergreen.V417.SessionIdHash
import Evergreen.V417.Slack
import Evergreen.V417.Table
import Evergreen.V417.ToBackendLog
import Evergreen.V417.User
import Evergreen.V417.UserSession
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
    = ExistingUserId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V417.Id.Id Evergreen.V417.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V417.Id.Id Evergreen.V417.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | UserTableMsg Evergreen.V417.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V417.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V417.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V417.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V417.Editable.Msg Evergreen.V417.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V417.Editable.Msg (Maybe String))
    | NotifyAdminsTokenEditableMsg (Evergreen.V417.Editable.Msg (Maybe String))
    | NotifyAdminsBotUserIdEditableMsg (Evergreen.V417.Editable.Msg (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)))
    | PostmarkKeyEditableMsg (Evergreen.V417.Editable.Msg Evergreen.V417.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V417.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V417.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V417.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V417.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    , postmarkApiKey : Evergreen.V417.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V417.Pagination.Pagination Evergreen.V417.LocalState.LogWithTime
    , connections : List ( Evergreen.V417.SessionIdHash.SessionIdHash, Evergreen.V417.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V417.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V417.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V417.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V417.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
        }
    | LogPageChanged (Evergreen.V417.Id.Id Evergreen.V417.Pagination.PageId) (Evergreen.V417.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V417.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V417.UserSession.ToBeFilledInByBackend (Evergreen.V417.NonemptyDict.NonemptyDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.User.BackendUser))
    | LoadGuilds (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) Evergreen.V417.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V417.DmChannelId.DmChannelId Evergreen.V417.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) Evergreen.V417.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) Evergreen.V417.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) Evergreen.V417.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) Evergreen.V417.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId) Evergreen.V417.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V417.SessionIdHash.SessionIdHash Evergreen.V417.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V417.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V417.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V417.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V417.FileStatus.FileHash Evergreen.V417.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V417.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V417.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V417.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V417.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V417.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetNotifyAdminsToken (Maybe String)
    | SetNotifyAdminsBotUserId (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    | SetPostmarkKey Evergreen.V417.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | RestoreGuild (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) (Evergreen.V417.UserSession.ToBeFilledInByBackend (Result Evergreen.V417.Discord.HttpError (List Evergreen.V417.Discord.Role)))
    | DisconnectClient Evergreen.V417.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V417.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V417.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V417.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V417.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V417.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V417.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V417.Editable.Model
    , privateVapidKey : Evergreen.V417.Editable.Model
    , openRouterKey : Evergreen.V417.Editable.Model
    , notifyAdminsToken : Evergreen.V417.Editable.Model
    , notifyAdminsBotUserId : Evergreen.V417.Editable.Model
    , postmarkKey : Evergreen.V417.Editable.Model
    , discordLinkLimit : Evergreen.V417.Editable.Model
    , slackLinkLimit : Evergreen.V417.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V417.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
