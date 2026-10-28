module Evergreen.V419.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V419.BackendMsgLog
import Evergreen.V419.Discord
import Evergreen.V419.DmChannelId
import Evergreen.V419.Editable
import Evergreen.V419.FileStatus
import Evergreen.V419.Id
import Evergreen.V419.LocalState
import Evergreen.V419.NonemptyDict
import Evergreen.V419.Pagination
import Evergreen.V419.Postmark
import Evergreen.V419.SessionIdHash
import Evergreen.V419.Slack
import Evergreen.V419.Table
import Evergreen.V419.ToBackendLog
import Evergreen.V419.User
import Evergreen.V419.UserSession
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
    = ExistingUserId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V419.Id.Id Evergreen.V419.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V419.Id.Id Evergreen.V419.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | UserTableMsg Evergreen.V419.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V419.Editable.Msg (Maybe Int))
    | ToggledSlackLinkingEnabled Bool
    | SlackLinkLimitEditableMsg (Evergreen.V419.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    | PressedDeleteSlackWorkspace (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    | PressedExpandSlackWorkspace (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    | PressedDeleteSlackDmChannel (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId)
    | PressedExpandGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | PublicVapidKeyEditableMsg (Evergreen.V419.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V419.Editable.Msg Evergreen.V419.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V419.Editable.Msg (Maybe String))
    | NotifyAdminsTokenEditableMsg (Evergreen.V419.Editable.Msg (Maybe String))
    | NotifyAdminsBotUserIdEditableMsg (Evergreen.V419.Editable.Msg (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)))
    | PostmarkKeyEditableMsg (Evergreen.V419.Editable.Msg Evergreen.V419.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V419.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V419.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V419.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V419.LocalState.PrivateVapidKey
    , openRouterKey : Maybe String
    , notifyAdminsToken : Maybe String
    , notifyAdminsBotUserId : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    , postmarkApiKey : Evergreen.V419.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , slackLinkingEnabled : Bool
    , slackLinkLimit : Maybe Int
    , logs : Evergreen.V419.Pagination.Pagination Evergreen.V419.LocalState.LogWithTime
    , connections : List ( Evergreen.V419.SessionIdHash.SessionIdHash, Evergreen.V419.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V419.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V419.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V419.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V419.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
        }
    | LogPageChanged (Evergreen.V419.Id.Id Evergreen.V419.Pagination.PageId) (Evergreen.V419.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V419.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V419.UserSession.ToBeFilledInByBackend (Evergreen.V419.NonemptyDict.NonemptyDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) Evergreen.V419.User.BackendUser))
    | LoadGuilds (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) Evergreen.V419.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V419.DmChannelId.DmChannelId Evergreen.V419.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) Evergreen.V419.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) Evergreen.V419.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) Evergreen.V419.LocalState.DiscordUserData_ForAdmin))
    | LoadSlackWorkspaces (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) Evergreen.V419.LocalState.AdminData_SlackWorkspace))
    | LoadSlackDmChannels (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId) Evergreen.V419.LocalState.AdminData_SlackDmChannel))
    | LoadSessions (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V419.SessionIdHash.SessionIdHash Evergreen.V419.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V419.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V419.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V419.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V419.FileStatus.FileHash Evergreen.V419.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V419.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V419.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V419.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V419.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetSlackLinkingEnabled Bool
    | SetSlackLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V419.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetOpenRouterKey (Maybe String)
    | SetNotifyAdminsToken (Maybe String)
    | SetNotifyAdminsBotUserId (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    | SetPostmarkKey Evergreen.V419.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    | DeleteSlackWorkspace (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    | DeleteSlackDmChannel (Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId)
    | DeleteGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | RestoreGuild (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) (Evergreen.V419.UserSession.ToBeFilledInByBackend (Result Evergreen.V419.Discord.HttpError (List Evergreen.V419.Discord.Role)))
    | DisconnectClient Evergreen.V419.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V419.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V419.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V419.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V419.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V419.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V419.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId)
    , expandedSlackWorkspaces : SeqSet.SeqSet (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , publicVapidKey : Evergreen.V419.Editable.Model
    , privateVapidKey : Evergreen.V419.Editable.Model
    , openRouterKey : Evergreen.V419.Editable.Model
    , notifyAdminsToken : Evergreen.V419.Editable.Model
    , notifyAdminsBotUserId : Evergreen.V419.Editable.Model
    , postmarkKey : Evergreen.V419.Editable.Model
    , discordLinkLimit : Evergreen.V419.Editable.Model
    , slackLinkLimit : Evergreen.V419.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V419.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
