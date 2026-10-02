module Evergreen.V396.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V396.BackendMsgLog
import Evergreen.V396.Discord
import Evergreen.V396.DmChannelId
import Evergreen.V396.Editable
import Evergreen.V396.FileStatus
import Evergreen.V396.Id
import Evergreen.V396.LocalState
import Evergreen.V396.NonemptyDict
import Evergreen.V396.Pagination
import Evergreen.V396.Postmark
import Evergreen.V396.SessionIdHash
import Evergreen.V396.Slack
import Evergreen.V396.Table
import Evergreen.V396.ToBackendLog
import Evergreen.V396.User
import Evergreen.V396.UserSession
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
    = ExistingUserId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V396.Id.Id Evergreen.V396.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V396.Id.Id Evergreen.V396.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | UserTableMsg Evergreen.V396.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V396.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V396.Editable.Msg (Maybe Evergreen.V396.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V396.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V396.Editable.Msg Evergreen.V396.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V396.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V396.Editable.Msg Evergreen.V396.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V396.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V396.Id.Id Evergreen.V396.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V396.Id.Id Evergreen.V396.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V396.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V396.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V396.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V396.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V396.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V396.Pagination.Pagination Evergreen.V396.LocalState.LogWithTime
    , connections : List ( Evergreen.V396.SessionIdHash.SessionIdHash, Evergreen.V396.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V396.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V396.LocalState.LastBackup
    , invalidChannelNames : List Evergreen.V396.LocalState.AdminData_InvalidChannelName
    , wordSpellingGameEnglish : Evergreen.V396.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V396.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
        }
    | LogPageChanged (Evergreen.V396.Id.Id Evergreen.V396.Pagination.PageId) (Evergreen.V396.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V396.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V396.UserSession.ToBeFilledInByBackend (Evergreen.V396.NonemptyDict.NonemptyDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.User.BackendUser))
    | LoadGuilds (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) Evergreen.V396.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V396.DmChannelId.DmChannelId Evergreen.V396.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) Evergreen.V396.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId) Evergreen.V396.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) Evergreen.V396.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V396.SessionIdHash.SessionIdHash Evergreen.V396.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V396.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V396.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V396.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V396.FileStatus.FileHash Evergreen.V396.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V396.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V396.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V396.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V396.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V396.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V396.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V396.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    | DeleteGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | RestoreGuild (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) (Evergreen.V396.UserSession.ToBeFilledInByBackend (Result Evergreen.V396.Discord.HttpError (List Evergreen.V396.Discord.Role)))
    | HideLog (Evergreen.V396.Id.Id Evergreen.V396.Pagination.ItemId)
    | UnhideLog (Evergreen.V396.Id.Id Evergreen.V396.Pagination.ItemId)
    | DisconnectClient Evergreen.V396.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V396.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V396.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V396.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V396.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V396.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V396.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V396.Id.Id Evergreen.V396.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V396.Id.Id Evergreen.V396.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V396.Editable.Model
    , publicVapidKey : Evergreen.V396.Editable.Model
    , privateVapidKey : Evergreen.V396.Editable.Model
    , openRouterKey : Evergreen.V396.Editable.Model
    , postmarkKey : Evergreen.V396.Editable.Model
    , discordLinkLimit : Evergreen.V396.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V396.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
