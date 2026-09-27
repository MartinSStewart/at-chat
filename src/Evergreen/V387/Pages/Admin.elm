module Evergreen.V387.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V387.BackendMsgLog
import Evergreen.V387.Discord
import Evergreen.V387.DmChannelId
import Evergreen.V387.Editable
import Evergreen.V387.FileStatus
import Evergreen.V387.Id
import Evergreen.V387.LocalState
import Evergreen.V387.NonemptyDict
import Evergreen.V387.Pagination
import Evergreen.V387.Postmark
import Evergreen.V387.SessionIdHash
import Evergreen.V387.Slack
import Evergreen.V387.Table
import Evergreen.V387.ToBackendLog
import Evergreen.V387.User
import Evergreen.V387.UserSession
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
    = ExistingUserId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V387.Id.Id Evergreen.V387.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V387.Id.Id Evergreen.V387.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | UserTableMsg Evergreen.V387.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V387.Editable.Msg (Maybe Evergreen.V387.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V387.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V387.Editable.Msg Evergreen.V387.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V387.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V387.Editable.Msg Evergreen.V387.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V387.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V387.Id.Id Evergreen.V387.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V387.Id.Id Evergreen.V387.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V387.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V387.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedDeleteOrphanedFiles
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V387.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V387.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V387.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V387.Pagination.Pagination Evergreen.V387.LocalState.LogWithTime
    , connections : List ( Evergreen.V387.SessionIdHash.SessionIdHash, Evergreen.V387.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V387.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V387.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V387.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V387.LocalState.WordSpellingGameStatus
    }


type alias EditedBackendUser =
    { name : String
    , email : String
    , isAdmin : Bool
    , createdAt : Effect.Time.Posix
    }


type AdminChange
    = ChangeUsers
        { time : Effect.Time.Posix
        , changedUsers : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
        }
    | LogPageChanged (Evergreen.V387.Id.Id Evergreen.V387.Pagination.PageId) (Evergreen.V387.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V387.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V387.UserSession.ToBeFilledInByBackend (Evergreen.V387.NonemptyDict.NonemptyDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.User.BackendUser))
    | LoadGuilds (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) Evergreen.V387.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V387.DmChannelId.DmChannelId Evergreen.V387.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) Evergreen.V387.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId) Evergreen.V387.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) Evergreen.V387.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V387.SessionIdHash.SessionIdHash Evergreen.V387.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V387.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V387.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V387.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V387.FileStatus.FileHash Evergreen.V387.FileStatus.BackendFileData))
    | LoadBucketFileCount (Evergreen.V387.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Int))
    | LoadToBackendLogs (Evergreen.V387.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V387.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V387.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V387.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V387.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V387.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V387.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
    | DeleteGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | RestoreGuild (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) (Evergreen.V387.UserSession.ToBeFilledInByBackend (Result Evergreen.V387.Discord.HttpError (List Evergreen.V387.Discord.Role)))
    | HideLog (Evergreen.V387.Id.Id Evergreen.V387.Pagination.ItemId)
    | UnhideLog (Evergreen.V387.Id.Id Evergreen.V387.Pagination.ItemId)
    | DisconnectClient Evergreen.V387.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V387.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V387.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V387.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V387.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V387.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
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
    { guilds : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V387.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V387.Id.Id Evergreen.V387.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V387.Id.Id Evergreen.V387.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V387.Editable.Model
    , publicVapidKey : Evergreen.V387.Editable.Model
    , privateVapidKey : Evergreen.V387.Editable.Model
    , openRouterKey : Evergreen.V387.Editable.Model
    , postmarkKey : Evergreen.V387.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , countToFrontend : String
    , downloadingBackup : Maybe DownloadingBackup
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress
    | ExportBackendFinished
    | DownloadLastBackupChunk Evergreen.V387.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
