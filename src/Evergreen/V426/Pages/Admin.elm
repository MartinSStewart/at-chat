module Evergreen.V426.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V426.BackendMsgLog
import Evergreen.V426.Discord
import Evergreen.V426.DmChannelId
import Evergreen.V426.Editable
import Evergreen.V426.FileStatus
import Evergreen.V426.Id
import Evergreen.V426.LocalState
import Evergreen.V426.NonemptyDict
import Evergreen.V426.Pagination
import Evergreen.V426.Postmark
import Evergreen.V426.SessionIdHash
import Evergreen.V426.Slack
import Evergreen.V426.Table
import Evergreen.V426.ToBackendLog
import Evergreen.V426.User
import Evergreen.V426.UserSession
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
    = ExistingUserId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V426.Id.Id Evergreen.V426.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V426.Id.Id Evergreen.V426.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | UserTableMsg Evergreen.V426.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V426.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V426.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V426.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V426.Editable.Msg Evergreen.V426.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V426.Editable.Msg (Maybe String))
    | NotifyAdminsTokenEditableMsg (Evergreen.V426.Editable.Msg (Maybe String))
    | NotifyAdminsBotUserIdEditableMsg (Evergreen.V426.Editable.Msg (Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)))
    | PostmarkKeyEditableMsg (Evergreen.V426.Editable.Msg Evergreen.V426.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V426.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V426.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V426.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V426.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    , postmarkApiKey : Evergreen.V426.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V426.Pagination.Pagination Evergreen.V426.LocalState.LogWithTime
    , connections : List ( Evergreen.V426.SessionIdHash.SessionIdHash, Evergreen.V426.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V426.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V426.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V426.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V426.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
        }
    | LogPageChanged (Evergreen.V426.Id.Id Evergreen.V426.Pagination.PageId) (Evergreen.V426.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V426.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V426.UserSession.ToBeFilledInByBackend (Evergreen.V426.NonemptyDict.NonemptyDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.User.BackendUser))
    | LoadGuilds (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) Evergreen.V426.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V426.DmChannelId.DmChannelId Evergreen.V426.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) Evergreen.V426.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) Evergreen.V426.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) Evergreen.V426.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) Evergreen.V426.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) Evergreen.V426.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V426.SessionIdHash.SessionIdHash Evergreen.V426.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V426.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V426.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V426.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V426.FileStatus.FileHash Evergreen.V426.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V426.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V426.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V426.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V426.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V426.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetNotifyAdminsToken (Maybe String)
    | SetNotifyAdminsBotUserId (Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    | SetPostmarkKey Evergreen.V426.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | RestoreGuild (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) (Evergreen.V426.UserSession.ToBeFilledInByBackend (Result Evergreen.V426.Discord.HttpError (List Evergreen.V426.Discord.Role)))
    | DisconnectClient Evergreen.V426.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V426.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V426.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V426.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V426.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V426.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V426.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V426.Editable.Model
    , privateVapidKey : Evergreen.V426.Editable.Model
    , openRouterKey : Evergreen.V426.Editable.Model
    , notifyAdminsToken : Evergreen.V426.Editable.Model
    , notifyAdminsBotUserId : Evergreen.V426.Editable.Model
    , postmarkKey : Evergreen.V426.Editable.Model
    , discordLinkLimit : Evergreen.V426.Editable.Model
    , slackLinkLimit : Evergreen.V426.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V426.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
