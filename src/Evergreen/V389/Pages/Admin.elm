module Evergreen.V389.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V389.BackendMsgLog
import Evergreen.V389.Discord
import Evergreen.V389.DmChannelId
import Evergreen.V389.Editable
import Evergreen.V389.FileStatus
import Evergreen.V389.Id
import Evergreen.V389.LocalState
import Evergreen.V389.NonemptyDict
import Evergreen.V389.Pagination
import Evergreen.V389.Postmark
import Evergreen.V389.SessionIdHash
import Evergreen.V389.Slack
import Evergreen.V389.Table
import Evergreen.V389.ToBackendLog
import Evergreen.V389.User
import Evergreen.V389.UserSession
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
    = ExistingUserId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V389.Id.Id Evergreen.V389.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V389.Id.Id Evergreen.V389.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | UserTableMsg Evergreen.V389.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V389.Editable.Msg (Maybe Evergreen.V389.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V389.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V389.Editable.Msg Evergreen.V389.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V389.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V389.Editable.Msg Evergreen.V389.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V389.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V389.Id.Id Evergreen.V389.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V389.Id.Id Evergreen.V389.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V389.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V389.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V389.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V389.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V389.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V389.Pagination.Pagination Evergreen.V389.LocalState.LogWithTime
    , connections : List ( Evergreen.V389.SessionIdHash.SessionIdHash, Evergreen.V389.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V389.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V389.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V389.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V389.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
        }
    | LogPageChanged (Evergreen.V389.Id.Id Evergreen.V389.Pagination.PageId) (Evergreen.V389.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V389.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V389.UserSession.ToBeFilledInByBackend (Evergreen.V389.NonemptyDict.NonemptyDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) Evergreen.V389.User.BackendUser))
    | LoadGuilds (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) Evergreen.V389.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V389.DmChannelId.DmChannelId Evergreen.V389.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) Evergreen.V389.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId) Evergreen.V389.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) Evergreen.V389.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V389.SessionIdHash.SessionIdHash Evergreen.V389.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V389.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V389.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V389.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V389.FileStatus.FileHash Evergreen.V389.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V389.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V389.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V389.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V389.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V389.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V389.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V389.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    | DeleteGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | RestoreGuild (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) (Evergreen.V389.UserSession.ToBeFilledInByBackend (Result Evergreen.V389.Discord.HttpError (List Evergreen.V389.Discord.Role)))
    | HideLog (Evergreen.V389.Id.Id Evergreen.V389.Pagination.ItemId)
    | UnhideLog (Evergreen.V389.Id.Id Evergreen.V389.Pagination.ItemId)
    | DisconnectClient Evergreen.V389.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V389.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V389.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V389.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V389.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V389.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V389.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V389.Id.Id Evergreen.V389.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V389.Id.Id Evergreen.V389.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V389.Editable.Model
    , publicVapidKey : Evergreen.V389.Editable.Model
    , privateVapidKey : Evergreen.V389.Editable.Model
    , openRouterKey : Evergreen.V389.Editable.Model
    , postmarkKey : Evergreen.V389.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V389.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
