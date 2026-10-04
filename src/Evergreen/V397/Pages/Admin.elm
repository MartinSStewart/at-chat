module Evergreen.V397.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V397.BackendMsgLog
import Evergreen.V397.Discord
import Evergreen.V397.DmChannelId
import Evergreen.V397.Editable
import Evergreen.V397.FileStatus
import Evergreen.V397.Id
import Evergreen.V397.LocalState
import Evergreen.V397.NonemptyDict
import Evergreen.V397.Pagination
import Evergreen.V397.Postmark
import Evergreen.V397.SessionIdHash
import Evergreen.V397.Slack
import Evergreen.V397.Table
import Evergreen.V397.ToBackendLog
import Evergreen.V397.User
import Evergreen.V397.UserSession
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
    = ExistingUserId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V397.Id.Id Evergreen.V397.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V397.Id.Id Evergreen.V397.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | UserTableMsg Evergreen.V397.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | DiscordLinkLimitEditableMsg (Evergreen.V397.Editable.Msg (Maybe Int))
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V397.Editable.Msg (Maybe Evergreen.V397.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V397.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V397.Editable.Msg Evergreen.V397.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V397.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V397.Editable.Msg Evergreen.V397.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V397.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V397.Id.Id Evergreen.V397.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V397.Id.Id Evergreen.V397.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V397.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V397.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V397.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V397.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V397.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , discordLinkLimit : Maybe Int
    , logs : Evergreen.V397.Pagination.Pagination Evergreen.V397.LocalState.LogWithTime
    , connections : List ( Evergreen.V397.SessionIdHash.SessionIdHash, Evergreen.V397.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V397.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V397.LocalState.LastBackup
    , invalidChannelNames : List Evergreen.V397.LocalState.AdminData_InvalidChannelName
    , wordSpellingGameEnglish : Evergreen.V397.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V397.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
        }
    | LogPageChanged (Evergreen.V397.Id.Id Evergreen.V397.Pagination.PageId) (Evergreen.V397.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V397.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V397.UserSession.ToBeFilledInByBackend (Evergreen.V397.NonemptyDict.NonemptyDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) Evergreen.V397.User.BackendUser))
    | LoadGuilds (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) Evergreen.V397.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V397.DmChannelId.DmChannelId Evergreen.V397.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) Evergreen.V397.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId) Evergreen.V397.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) Evergreen.V397.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V397.SessionIdHash.SessionIdHash Evergreen.V397.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V397.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V397.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V397.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V397.FileStatus.FileHash Evergreen.V397.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V397.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V397.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V397.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V397.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetDiscordLinkLimit (Maybe Int)
    | SetPrivateVapidKey Evergreen.V397.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V397.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V397.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    | DeleteGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | RestoreGuild (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) (Evergreen.V397.UserSession.ToBeFilledInByBackend (Result Evergreen.V397.Discord.HttpError (List Evergreen.V397.Discord.Role)))
    | HideLog (Evergreen.V397.Id.Id Evergreen.V397.Pagination.ItemId)
    | UnhideLog (Evergreen.V397.Id.Id Evergreen.V397.Pagination.ItemId)
    | DisconnectClient Evergreen.V397.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V397.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V397.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V397.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V397.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V397.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V397.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V397.Id.Id Evergreen.V397.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V397.Id.Id Evergreen.V397.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V397.Editable.Model
    , publicVapidKey : Evergreen.V397.Editable.Model
    , privateVapidKey : Evergreen.V397.Editable.Model
    , openRouterKey : Evergreen.V397.Editable.Model
    , postmarkKey : Evergreen.V397.Editable.Model
    , discordLinkLimit : Evergreen.V397.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V397.LocalState.BackupContents Int Bytes.Bytes


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendChunkRequest
        { totalBytes : Int
        , offset : Int
        }
        Bytes.Bytes
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
