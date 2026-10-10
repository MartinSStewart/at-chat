module Evergreen.V402.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V402.BackendMsgLog
import Evergreen.V402.Discord
import Evergreen.V402.DmChannelId
import Evergreen.V402.Editable
import Evergreen.V402.FileStatus
import Evergreen.V402.Id
import Evergreen.V402.LocalState
import Evergreen.V402.NonemptyDict
import Evergreen.V402.Pagination
import Evergreen.V402.Postmark
import Evergreen.V402.SessionIdHash
import Evergreen.V402.Slack
import Evergreen.V402.Table
import Evergreen.V402.ToBackendLog
import Evergreen.V402.User
import Evergreen.V402.UserSession
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
    = ExistingUserId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V402.Id.Id Evergreen.V402.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V402.Id.Id Evergreen.V402.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | UserTableMsg Evergreen.V402.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V402.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V402.Editable.Msg (Maybe Evergreen.V402.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V402.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V402.Editable.Msg Evergreen.V402.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V402.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V402.Editable.Msg Evergreen.V402.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V402.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V402.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V402.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V402.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V402.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V402.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V402.Pagination.Pagination Evergreen.V402.LocalState.LogWithTime
    , connections : List ( Evergreen.V402.SessionIdHash.SessionIdHash, Evergreen.V402.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V402.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V402.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V402.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V402.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
        }
    | LogPageChanged (Evergreen.V402.Id.Id Evergreen.V402.Pagination.PageId) (Evergreen.V402.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V402.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V402.UserSession.ToBeFilledInByBackend (Evergreen.V402.NonemptyDict.NonemptyDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.User.BackendUser))
    | LoadGuilds (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) Evergreen.V402.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V402.DmChannelId.DmChannelId Evergreen.V402.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) Evergreen.V402.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) Evergreen.V402.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) Evergreen.V402.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V402.SessionIdHash.SessionIdHash Evergreen.V402.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V402.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V402.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V402.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V402.FileStatus.FileHash Evergreen.V402.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V402.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V402.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V402.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V402.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V402.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V402.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V402.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    | DeleteGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | RestoreGuild (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) (Evergreen.V402.UserSession.ToBeFilledInByBackend (Result Evergreen.V402.Discord.HttpError (List Evergreen.V402.Discord.Role)))
    | DisconnectClient Evergreen.V402.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V402.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V402.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V402.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V402.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V402.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V402.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V402.Id.Id Evergreen.V402.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V402.Id.Id Evergreen.V402.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V402.Editable.Model
    , publicVapidKey : Evergreen.V402.Editable.Model
    , privateVapidKey : Evergreen.V402.Editable.Model
    , openRouterKey : Evergreen.V402.Editable.Model
    , postmarkKey : Evergreen.V402.Editable.Model
    , discordLinkLimit : Evergreen.V402.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V402.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
