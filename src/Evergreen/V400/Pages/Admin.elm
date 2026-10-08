module Evergreen.V400.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V400.BackendMsgLog
import Evergreen.V400.Discord
import Evergreen.V400.DmChannelId
import Evergreen.V400.Editable
import Evergreen.V400.FileStatus
import Evergreen.V400.Id
import Evergreen.V400.LocalState
import Evergreen.V400.NonemptyDict
import Evergreen.V400.Pagination
import Evergreen.V400.Postmark
import Evergreen.V400.SessionIdHash
import Evergreen.V400.Slack
import Evergreen.V400.Table
import Evergreen.V400.ToBackendLog
import Evergreen.V400.User
import Evergreen.V400.UserSession
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
    | WebCodecsTestSection


type UserTableId
    = ExistingUserId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V400.Id.Id Evergreen.V400.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V400.Id.Id Evergreen.V400.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
    | UserTableMsg Evergreen.V400.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V400.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V400.Editable.Msg (Maybe Evergreen.V400.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V400.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V400.Editable.Msg Evergreen.V400.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V400.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V400.Editable.Msg Evergreen.V400.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V400.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V400.Id.Id Evergreen.V400.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V400.Id.Id Evergreen.V400.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V400.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V400.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V400.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V400.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V400.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V400.Pagination.Pagination Evergreen.V400.LocalState.LogWithTime
    , connections : List ( Evergreen.V400.SessionIdHash.SessionIdHash, Evergreen.V400.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V400.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V400.LocalState.LastBackup
    , invalidChannelNames : List Evergreen.V400.LocalState.AdminData_InvalidChannelName
    , wordSpellingGameEnglish : Evergreen.V400.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V400.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
        }
    | LogPageChanged (Evergreen.V400.Id.Id Evergreen.V400.Pagination.PageId) (Evergreen.V400.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V400.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V400.UserSession.ToBeFilledInByBackend (Evergreen.V400.NonemptyDict.NonemptyDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) Evergreen.V400.User.BackendUser))
    | LoadGuilds (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) Evergreen.V400.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) Evergreen.V400.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V400.DmChannelId.DmChannelId Evergreen.V400.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) Evergreen.V400.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) Evergreen.V400.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) Evergreen.V400.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V400.SessionIdHash.SessionIdHash Evergreen.V400.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V400.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V400.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V400.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V400.FileStatus.FileHash Evergreen.V400.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V400.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V400.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V400.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V400.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V400.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V400.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V400.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId)
    | DeleteGuild (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId)
    | RestoreGuild (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) (Evergreen.V400.UserSession.ToBeFilledInByBackend (Result Evergreen.V400.Discord.HttpError (List Evergreen.V400.Discord.Role)))
    | HideLog (Evergreen.V400.Id.Id Evergreen.V400.Pagination.ItemId)
    | UnhideLog (Evergreen.V400.Id.Id Evergreen.V400.Pagination.ItemId)
    | DisconnectClient Evergreen.V400.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V400.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V400.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V400.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V400.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V400.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V400.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V400.Id.Id Evergreen.V400.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V400.Id.Id Evergreen.V400.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V400.Editable.Model
    , publicVapidKey : Evergreen.V400.Editable.Model
    , privateVapidKey : Evergreen.V400.Editable.Model
    , openRouterKey : Evergreen.V400.Editable.Model
    , postmarkKey : Evergreen.V400.Editable.Model
    , discordLinkLimit : Evergreen.V400.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
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
    | DownloadLastBackupChunk Evergreen.V400.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
