module Evergreen.V423.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V423.BackendMsgLog
import Evergreen.V423.Discord
import Evergreen.V423.DmChannelId
import Evergreen.V423.Editable
import Evergreen.V423.FileStatus
import Evergreen.V423.Id
import Evergreen.V423.LocalState
import Evergreen.V423.NonemptyDict
import Evergreen.V423.Pagination
import Evergreen.V423.Postmark
import Evergreen.V423.SessionIdHash
import Evergreen.V423.Slack
import Evergreen.V423.Table
import Evergreen.V423.ToBackendLog
import Evergreen.V423.User
import Evergreen.V423.UserSession
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
    = ExistingUserId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V423.Id.Id Evergreen.V423.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V423.Id.Id Evergreen.V423.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | UserTableMsg Evergreen.V423.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V423.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V423.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V423.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V423.Editable.Msg Evergreen.V423.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V423.Editable.Msg (Maybe String))
    | NotifyAdminsTokenEditableMsg (Evergreen.V423.Editable.Msg (Maybe String))
    | NotifyAdminsBotUserIdEditableMsg (Evergreen.V423.Editable.Msg (Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)))
    | PostmarkKeyEditableMsg (Evergreen.V423.Editable.Msg Evergreen.V423.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V423.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V423.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V423.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V423.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    , postmarkApiKey : Evergreen.V423.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V423.Pagination.Pagination Evergreen.V423.LocalState.LogWithTime
    , connections : List ( Evergreen.V423.SessionIdHash.SessionIdHash, Evergreen.V423.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V423.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V423.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V423.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V423.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
        }
    | LogPageChanged (Evergreen.V423.Id.Id Evergreen.V423.Pagination.PageId) (Evergreen.V423.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V423.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V423.UserSession.ToBeFilledInByBackend (Evergreen.V423.NonemptyDict.NonemptyDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.User.BackendUser))
    | LoadGuilds (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) Evergreen.V423.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V423.DmChannelId.DmChannelId Evergreen.V423.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) Evergreen.V423.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) Evergreen.V423.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) Evergreen.V423.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) Evergreen.V423.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) Evergreen.V423.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V423.SessionIdHash.SessionIdHash Evergreen.V423.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V423.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V423.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V423.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V423.FileStatus.FileHash Evergreen.V423.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V423.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V423.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V423.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V423.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V423.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetNotifyAdminsToken (Maybe String)
    | SetNotifyAdminsBotUserId (Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))
    | SetPostmarkKey Evergreen.V423.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | RestoreGuild (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) (Evergreen.V423.UserSession.ToBeFilledInByBackend (Result Evergreen.V423.Discord.HttpError (List Evergreen.V423.Discord.Role)))
    | DisconnectClient Evergreen.V423.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V423.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V423.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V423.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V423.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V423.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V423.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V423.Id.Id Evergreen.V423.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V423.Id.Id Evergreen.V423.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V423.Editable.Model
    , privateVapidKey : Evergreen.V423.Editable.Model
    , openRouterKey : Evergreen.V423.Editable.Model
    , notifyAdminsToken : Evergreen.V423.Editable.Model
    , notifyAdminsBotUserId : Evergreen.V423.Editable.Model
    , postmarkKey : Evergreen.V423.Editable.Model
    , discordLinkLimit : Evergreen.V423.Editable.Model
    , slackLinkLimit : Evergreen.V423.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V423.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
