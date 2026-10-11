module Evergreen.V403.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V403.BackendMsgLog
import Evergreen.V403.Discord
import Evergreen.V403.DmChannelId
import Evergreen.V403.Editable
import Evergreen.V403.FileStatus
import Evergreen.V403.Id
import Evergreen.V403.LocalState
import Evergreen.V403.NonemptyDict
import Evergreen.V403.Pagination
import Evergreen.V403.Postmark
import Evergreen.V403.SessionIdHash
import Evergreen.V403.Slack
import Evergreen.V403.Table
import Evergreen.V403.ToBackendLog
import Evergreen.V403.User
import Evergreen.V403.UserSession
import SeqDict
import SeqSet


type AdminUiSection
    = UsersSection
    | LogSection
    | DmChannelsSection
    | DiscordDmChannelsSection
    | DiscordUsersSection
    | DiscordGuildsSection
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
    = ExistingUserId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V403.Id.Id Evergreen.V403.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V403.Id.Id Evergreen.V403.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | UserTableMsg Evergreen.V403.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V403.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V403.Editable.Msg (Maybe Evergreen.V403.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V403.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V403.Editable.Msg Evergreen.V403.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V403.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V403.Editable.Msg Evergreen.V403.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V403.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V403.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V403.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V403.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V403.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V403.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V403.Pagination.Pagination Evergreen.V403.LocalState.LogWithTime
    , connections : List ( Evergreen.V403.SessionIdHash.SessionIdHash, Evergreen.V403.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V403.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V403.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V403.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V403.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
        }
    | LogPageChanged (Evergreen.V403.Id.Id Evergreen.V403.Pagination.PageId) (Evergreen.V403.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V403.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V403.UserSession.ToBeFilledInByBackend (Evergreen.V403.NonemptyDict.NonemptyDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.User.BackendUser))
    | LoadGuilds (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) Evergreen.V403.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V403.DmChannelId.DmChannelId Evergreen.V403.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) Evergreen.V403.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) Evergreen.V403.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) Evergreen.V403.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V403.SessionIdHash.SessionIdHash Evergreen.V403.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V403.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V403.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V403.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V403.FileStatus.FileHash Evergreen.V403.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V403.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V403.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V403.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V403.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V403.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V403.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V403.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    | DeleteGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | RestoreGuild (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) (Evergreen.V403.UserSession.ToBeFilledInByBackend (Result Evergreen.V403.Discord.HttpError (List Evergreen.V403.Discord.Role)))
    | DisconnectClient Evergreen.V403.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V403.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V403.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V403.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V403.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V403.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V403.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V403.Id.Id Evergreen.V403.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V403.Id.Id Evergreen.V403.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V403.Editable.Model
    , publicVapidKey : Evergreen.V403.Editable.Model
    , privateVapidKey : Evergreen.V403.Editable.Model
    , openRouterKey : Evergreen.V403.Editable.Model
    , postmarkKey : Evergreen.V403.Editable.Model
    , discordLinkLimit : Evergreen.V403.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V403.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
