module Evergreen.V412.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V412.BackendMsgLog
import Evergreen.V412.Discord
import Evergreen.V412.DmChannelId
import Evergreen.V412.Editable
import Evergreen.V412.FileStatus
import Evergreen.V412.Id
import Evergreen.V412.LocalState
import Evergreen.V412.NonemptyDict
import Evergreen.V412.Pagination
import Evergreen.V412.Postmark
import Evergreen.V412.SessionIdHash
import Evergreen.V412.Slack
import Evergreen.V412.Table
import Evergreen.V412.ToBackendLog
import Evergreen.V412.User
import Evergreen.V412.UserSession
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
    = ExistingUserId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V412.Id.Id Evergreen.V412.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V412.Id.Id Evergreen.V412.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | UserTableMsg Evergreen.V412.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V412.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V412.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V412.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V412.Editable.Msg Evergreen.V412.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V412.Editable.Msg (Maybe String))
    | NotifyAdminsTokenEditableMsg (Evergreen.V412.Editable.Msg (Maybe String))
    | NotifyAdminsBotUserIdEditableMsg (Evergreen.V412.Editable.Msg (Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)))
    | PostmarkKeyEditableMsg (Evergreen.V412.Editable.Msg Evergreen.V412.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V412.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V412.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V412.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V412.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    , postmarkApiKey : Evergreen.V412.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V412.Pagination.Pagination Evergreen.V412.LocalState.LogWithTime
    , connections : List ( Evergreen.V412.SessionIdHash.SessionIdHash, Evergreen.V412.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V412.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V412.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V412.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V412.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
        }
    | LogPageChanged (Evergreen.V412.Id.Id Evergreen.V412.Pagination.PageId) (Evergreen.V412.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V412.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V412.UserSession.ToBeFilledInByBackend (Evergreen.V412.NonemptyDict.NonemptyDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.User.BackendUser))
    | LoadGuilds (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) Evergreen.V412.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V412.DmChannelId.DmChannelId Evergreen.V412.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) Evergreen.V412.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) Evergreen.V412.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) Evergreen.V412.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) Evergreen.V412.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId) Evergreen.V412.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V412.SessionIdHash.SessionIdHash Evergreen.V412.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V412.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V412.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V412.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V412.FileStatus.FileHash Evergreen.V412.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V412.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V412.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V412.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V412.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V412.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetNotifyAdminsToken (Maybe String)
    | SetNotifyAdminsBotUserId (Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId))
    | SetPostmarkKey Evergreen.V412.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | RestoreGuild (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) (Evergreen.V412.UserSession.ToBeFilledInByBackend (Result Evergreen.V412.Discord.HttpError (List Evergreen.V412.Discord.Role)))
    | DisconnectClient Evergreen.V412.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V412.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V412.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V412.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V412.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V412.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V412.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V412.Editable.Model
    , privateVapidKey : Evergreen.V412.Editable.Model
    , openRouterKey : Evergreen.V412.Editable.Model
    , notifyAdminsToken : Evergreen.V412.Editable.Model
    , notifyAdminsBotUserId : Evergreen.V412.Editable.Model
    , postmarkKey : Evergreen.V412.Editable.Model
    , discordLinkLimit : Evergreen.V412.Editable.Model
    , slackLinkLimit : Evergreen.V412.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V412.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
