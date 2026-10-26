module Evergreen.V414.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V414.BackendMsgLog
import Evergreen.V414.Discord
import Evergreen.V414.DmChannelId
import Evergreen.V414.Editable
import Evergreen.V414.FileStatus
import Evergreen.V414.Id
import Evergreen.V414.LocalState
import Evergreen.V414.NonemptyDict
import Evergreen.V414.Pagination
import Evergreen.V414.Postmark
import Evergreen.V414.SessionIdHash
import Evergreen.V414.Slack
import Evergreen.V414.Table
import Evergreen.V414.ToBackendLog
import Evergreen.V414.User
import Evergreen.V414.UserSession
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
    = ExistingUserId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V414.Id.Id Evergreen.V414.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V414.Id.Id Evergreen.V414.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    | UserTableMsg Evergreen.V414.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V414.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V414.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V414.Slack.Id Evergreen.V414.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V414.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V414.Editable.Msg Evergreen.V414.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V414.Editable.Msg (Maybe String))
    | NotifyAdminsTokenEditableMsg (Evergreen.V414.Editable.Msg (Maybe String))
    | NotifyAdminsBotUserIdEditableMsg (Evergreen.V414.Editable.Msg (Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)))
    | PostmarkKeyEditableMsg (Evergreen.V414.Editable.Msg Evergreen.V414.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V414.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V414.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V414.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V414.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    , postmarkApiKey : Evergreen.V414.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V414.Pagination.Pagination Evergreen.V414.LocalState.LogWithTime
    , connections : List ( Evergreen.V414.SessionIdHash.SessionIdHash, Evergreen.V414.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V414.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V414.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V414.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V414.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
        }
    | LogPageChanged (Evergreen.V414.Id.Id Evergreen.V414.Pagination.PageId) (Evergreen.V414.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V414.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V414.UserSession.ToBeFilledInByBackend (Evergreen.V414.NonemptyDict.NonemptyDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) Evergreen.V414.User.BackendUser))
    | LoadGuilds (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) Evergreen.V414.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) Evergreen.V414.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V414.DmChannelId.DmChannelId Evergreen.V414.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) Evergreen.V414.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) Evergreen.V414.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) Evergreen.V414.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) Evergreen.V414.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.DmChannelId) Evergreen.V414.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V414.SessionIdHash.SessionIdHash Evergreen.V414.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V414.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V414.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V414.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V414.FileStatus.FileHash Evergreen.V414.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V414.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V414.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V414.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V414.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V414.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetNotifyAdminsToken (Maybe String)
    | SetNotifyAdminsBotUserId (Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId))
    | SetPostmarkKey Evergreen.V414.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V414.Slack.Id Evergreen.V414.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId)
    | RestoreGuild (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) (Evergreen.V414.UserSession.ToBeFilledInByBackend (Result Evergreen.V414.Discord.HttpError (List Evergreen.V414.Discord.Role)))
    | DisconnectClient Evergreen.V414.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V414.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V414.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V414.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V414.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V414.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V414.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V414.Id.Id Evergreen.V414.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V414.Id.Id Evergreen.V414.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V414.Editable.Model
    , privateVapidKey : Evergreen.V414.Editable.Model
    , openRouterKey : Evergreen.V414.Editable.Model
    , notifyAdminsToken : Evergreen.V414.Editable.Model
    , notifyAdminsBotUserId : Evergreen.V414.Editable.Model
    , postmarkKey : Evergreen.V414.Editable.Model
    , discordLinkLimit : Evergreen.V414.Editable.Model
    , slackLinkLimit : Evergreen.V414.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V414.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
