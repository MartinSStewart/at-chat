module Evergreen.V401.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V401.BackendMsgLog
import Evergreen.V401.Discord
import Evergreen.V401.DmChannelId
import Evergreen.V401.Editable
import Evergreen.V401.FileStatus
import Evergreen.V401.Id
import Evergreen.V401.LocalState
import Evergreen.V401.NonemptyDict
import Evergreen.V401.Pagination
import Evergreen.V401.Postmark
import Evergreen.V401.SessionIdHash
import Evergreen.V401.Slack
import Evergreen.V401.Table
import Evergreen.V401.ToBackendLog
import Evergreen.V401.User
import Evergreen.V401.UserSession
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
    = ExistingUserId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V401.Id.Id Evergreen.V401.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V401.Id.Id Evergreen.V401.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | UserTableMsg Evergreen.V401.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V401.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V401.Editable.Msg (Maybe Evergreen.V401.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V401.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V401.Editable.Msg Evergreen.V401.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V401.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V401.Editable.Msg Evergreen.V401.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V401.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V401.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V401.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V401.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V401.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V401.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V401.Pagination.Pagination Evergreen.V401.LocalState.LogWithTime
    , connections : List ( Evergreen.V401.SessionIdHash.SessionIdHash, Evergreen.V401.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V401.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V401.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V401.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V401.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
        }
    | LogPageChanged (Evergreen.V401.Id.Id Evergreen.V401.Pagination.PageId) (Evergreen.V401.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V401.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V401.UserSession.ToBeFilledInByBackend (Evergreen.V401.NonemptyDict.NonemptyDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.User.BackendUser))
    | LoadGuilds (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) Evergreen.V401.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V401.DmChannelId.DmChannelId Evergreen.V401.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) Evergreen.V401.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) Evergreen.V401.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) Evergreen.V401.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V401.SessionIdHash.SessionIdHash Evergreen.V401.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V401.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V401.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V401.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V401.FileStatus.FileHash Evergreen.V401.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V401.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V401.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V401.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V401.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V401.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V401.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V401.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    | DeleteGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | RestoreGuild (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) (Evergreen.V401.UserSession.ToBeFilledInByBackend (Result Evergreen.V401.Discord.HttpError (List Evergreen.V401.Discord.Role)))
    | DisconnectClient Evergreen.V401.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V401.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V401.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V401.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V401.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V401.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V401.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V401.Id.Id Evergreen.V401.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V401.Id.Id Evergreen.V401.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V401.Editable.Model
    , publicVapidKey : Evergreen.V401.Editable.Model
    , privateVapidKey : Evergreen.V401.Editable.Model
    , openRouterKey : Evergreen.V401.Editable.Model
    , postmarkKey : Evergreen.V401.Editable.Model
    , discordLinkLimit : Evergreen.V401.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V401.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
