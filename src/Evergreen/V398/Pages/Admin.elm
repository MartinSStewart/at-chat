module Evergreen.V398.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V398.BackendMsgLog
import Evergreen.V398.Discord
import Evergreen.V398.DmChannelId
import Evergreen.V398.Editable
import Evergreen.V398.FileStatus
import Evergreen.V398.Id
import Evergreen.V398.LocalState
import Evergreen.V398.NonemptyDict
import Evergreen.V398.Pagination
import Evergreen.V398.Postmark
import Evergreen.V398.SessionIdHash
import Evergreen.V398.Slack
import Evergreen.V398.Table
import Evergreen.V398.ToBackendLog
import Evergreen.V398.User
import Evergreen.V398.UserSession
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
    = ExistingUserId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V398.Id.Id Evergreen.V398.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V398.Id.Id Evergreen.V398.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | UserTableMsg Evergreen.V398.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V398.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V398.Editable.Msg (Maybe Evergreen.V398.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V398.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V398.Editable.Msg Evergreen.V398.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V398.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V398.Editable.Msg Evergreen.V398.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V398.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V398.Id.Id Evergreen.V398.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V398.Id.Id Evergreen.V398.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V398.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V398.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V398.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V398.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V398.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V398.Pagination.Pagination Evergreen.V398.LocalState.LogWithTime
    , connections : List ( Evergreen.V398.SessionIdHash.SessionIdHash, Evergreen.V398.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V398.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V398.LocalState.LastBackup
    , invalidChannelNames : List Evergreen.V398.LocalState.AdminData_InvalidChannelName
    , wordSpellingGameEnglish : Evergreen.V398.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V398.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
        }
    | LogPageChanged (Evergreen.V398.Id.Id Evergreen.V398.Pagination.PageId) (Evergreen.V398.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V398.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V398.UserSession.ToBeFilledInByBackend (Evergreen.V398.NonemptyDict.NonemptyDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.User.BackendUser))
    | LoadGuilds (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) Evergreen.V398.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V398.DmChannelId.DmChannelId Evergreen.V398.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) Evergreen.V398.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) Evergreen.V398.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) Evergreen.V398.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V398.SessionIdHash.SessionIdHash Evergreen.V398.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V398.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V398.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V398.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V398.FileStatus.FileHash Evergreen.V398.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V398.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V398.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V398.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V398.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V398.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V398.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V398.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    | DeleteGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | RestoreGuild (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) (Evergreen.V398.UserSession.ToBeFilledInByBackend (Result Evergreen.V398.Discord.HttpError (List Evergreen.V398.Discord.Role)))
    | HideLog (Evergreen.V398.Id.Id Evergreen.V398.Pagination.ItemId)
    | UnhideLog (Evergreen.V398.Id.Id Evergreen.V398.Pagination.ItemId)
    | DisconnectClient Evergreen.V398.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V398.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V398.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V398.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V398.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V398.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V398.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V398.Id.Id Evergreen.V398.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V398.Id.Id Evergreen.V398.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V398.Editable.Model
    , publicVapidKey : Evergreen.V398.Editable.Model
    , privateVapidKey : Evergreen.V398.Editable.Model
    , openRouterKey : Evergreen.V398.Editable.Model
    , postmarkKey : Evergreen.V398.Editable.Model
    , discordLinkLimit : Evergreen.V398.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V398.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
