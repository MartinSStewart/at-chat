module Evergreen.V395.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V395.BackendMsgLog
import Evergreen.V395.Discord
import Evergreen.V395.DmChannelId
import Evergreen.V395.Editable
import Evergreen.V395.FileStatus
import Evergreen.V395.Id
import Evergreen.V395.LocalState
import Evergreen.V395.NonemptyDict
import Evergreen.V395.Pagination
import Evergreen.V395.Postmark
import Evergreen.V395.SessionIdHash
import Evergreen.V395.Slack
import Evergreen.V395.Table
import Evergreen.V395.ToBackendLog
import Evergreen.V395.User
import Evergreen.V395.UserSession
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
    | ToBackendLogsSection
    | BackendMsgLogsSection
    | StickersAndEmojisSection
    | WebsocketCloseEventsSection
    | SessionsSection
    | WordSpellingGameSwedishSection
    | WebCodecsTestSection


type UserTableId
    = ExistingUserId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V395.Id.Id Evergreen.V395.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V395.Id.Id Evergreen.V395.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | UserTableMsg Evergreen.V395.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V395.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V395.Editable.Msg (Maybe Evergreen.V395.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V395.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V395.Editable.Msg Evergreen.V395.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V395.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V395.Editable.Msg Evergreen.V395.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V395.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V395.Id.Id Evergreen.V395.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V395.Id.Id Evergreen.V395.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V395.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V395.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V395.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V395.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V395.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V395.Pagination.Pagination Evergreen.V395.LocalState.LogWithTime
    , connections : List ( Evergreen.V395.SessionIdHash.SessionIdHash, Evergreen.V395.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V395.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V395.LocalState.LastBackup
    , invalidChannelNames : List Evergreen.V395.LocalState.AdminData_InvalidChannelName
    , wordSpellingGameEnglish : Evergreen.V395.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V395.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
        }
    | LogPageChanged (Evergreen.V395.Id.Id Evergreen.V395.Pagination.PageId) (Evergreen.V395.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V395.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V395.UserSession.ToBeFilledInByBackend (Evergreen.V395.NonemptyDict.NonemptyDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.User.BackendUser))
    | LoadGuilds (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) Evergreen.V395.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V395.DmChannelId.DmChannelId Evergreen.V395.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) Evergreen.V395.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId) Evergreen.V395.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) Evergreen.V395.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V395.SessionIdHash.SessionIdHash Evergreen.V395.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V395.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V395.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V395.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V395.FileStatus.FileHash Evergreen.V395.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V395.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V395.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V395.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V395.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V395.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V395.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V395.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    | DeleteGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | RestoreGuild (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) (Evergreen.V395.UserSession.ToBeFilledInByBackend (Result Evergreen.V395.Discord.HttpError (List Evergreen.V395.Discord.Role)))
    | HideLog (Evergreen.V395.Id.Id Evergreen.V395.Pagination.ItemId)
    | UnhideLog (Evergreen.V395.Id.Id Evergreen.V395.Pagination.ItemId)
    | DisconnectClient Evergreen.V395.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V395.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V395.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V395.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V395.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V395.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V395.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V395.Id.Id Evergreen.V395.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V395.Id.Id Evergreen.V395.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V395.Editable.Model
    , publicVapidKey : Evergreen.V395.Editable.Model
    , privateVapidKey : Evergreen.V395.Editable.Model
    , openRouterKey : Evergreen.V395.Editable.Model
    , postmarkKey : Evergreen.V395.Editable.Model
    , discordLinkLimit : Evergreen.V395.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V395.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
