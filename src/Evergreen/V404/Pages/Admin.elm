module Evergreen.V404.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V404.BackendMsgLog
import Evergreen.V404.Discord
import Evergreen.V404.DmChannelId
import Evergreen.V404.Editable
import Evergreen.V404.FileStatus
import Evergreen.V404.Id
import Evergreen.V404.LocalState
import Evergreen.V404.NonemptyDict
import Evergreen.V404.Pagination
import Evergreen.V404.Postmark
import Evergreen.V404.SessionIdHash
import Evergreen.V404.Slack
import Evergreen.V404.Table
import Evergreen.V404.ToBackendLog
import Evergreen.V404.User
import Evergreen.V404.UserSession
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
    = ExistingUserId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V404.Id.Id Evergreen.V404.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V404.Id.Id Evergreen.V404.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    | UserTableMsg Evergreen.V404.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V404.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V404.Editable.Msg (Maybe Evergreen.V404.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V404.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V404.Editable.Msg Evergreen.V404.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V404.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V404.Editable.Msg Evergreen.V404.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V404.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedDisconnectClient Evergreen.V404.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V404.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V404.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V404.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V404.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V404.Pagination.Pagination Evergreen.V404.LocalState.LogWithTime
    , connections : List ( Evergreen.V404.SessionIdHash.SessionIdHash, Evergreen.V404.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V404.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V404.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V404.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V404.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
        }
    | LogPageChanged (Evergreen.V404.Id.Id Evergreen.V404.Pagination.PageId) (Evergreen.V404.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V404.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V404.UserSession.ToBeFilledInByBackend (Evergreen.V404.NonemptyDict.NonemptyDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) Evergreen.V404.User.BackendUser))
    | LoadGuilds (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) Evergreen.V404.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) Evergreen.V404.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V404.DmChannelId.DmChannelId Evergreen.V404.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) Evergreen.V404.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) Evergreen.V404.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) Evergreen.V404.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V404.SessionIdHash.SessionIdHash Evergreen.V404.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V404.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V404.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V404.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V404.FileStatus.FileHash Evergreen.V404.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V404.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V404.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V404.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V404.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V404.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V404.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V404.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId)
    | DeleteGuild (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)
    | RestoreGuild (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) (Evergreen.V404.UserSession.ToBeFilledInByBackend (Result Evergreen.V404.Discord.HttpError (List Evergreen.V404.Discord.Role)))
    | DisconnectClient Evergreen.V404.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V404.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V404.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V404.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V404.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V404.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V404.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V404.Id.Id Evergreen.V404.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V404.Id.Id Evergreen.V404.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V404.Editable.Model
    , publicVapidKey : Evergreen.V404.Editable.Model
    , privateVapidKey : Evergreen.V404.Editable.Model
    , openRouterKey : Evergreen.V404.Editable.Model
    , postmarkKey : Evergreen.V404.Editable.Model
    , discordLinkLimit : Evergreen.V404.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V404.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
