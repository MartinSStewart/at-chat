module Evergreen.V386.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V386.BackendMsgLog
import Evergreen.V386.Discord
import Evergreen.V386.DmChannelId
import Evergreen.V386.Editable
import Evergreen.V386.FileStatus
import Evergreen.V386.Id
import Evergreen.V386.LocalState
import Evergreen.V386.NonemptyDict
import Evergreen.V386.Pagination
import Evergreen.V386.Postmark
import Evergreen.V386.SessionIdHash
import Evergreen.V386.Slack
import Evergreen.V386.Table
import Evergreen.V386.ToBackendLog
import Evergreen.V386.User
import Evergreen.V386.UserSession
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
    = ExistingUserId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V386.Id.Id Evergreen.V386.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V386.Id.Id Evergreen.V386.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | UserTableMsg Evergreen.V386.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V386.Editable.Msg (Maybe Evergreen.V386.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V386.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V386.Editable.Msg Evergreen.V386.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V386.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V386.Editable.Msg Evergreen.V386.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V386.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V386.Id.Id Evergreen.V386.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V386.Id.Id Evergreen.V386.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V386.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V386.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V386.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V386.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V386.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V386.Pagination.Pagination Evergreen.V386.LocalState.LogWithTime
    , connections : List ( Evergreen.V386.SessionIdHash.SessionIdHash, Evergreen.V386.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V386.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V386.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V386.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V386.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
        }
    | LogPageChanged (Evergreen.V386.Id.Id Evergreen.V386.Pagination.PageId) (Evergreen.V386.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V386.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V386.UserSession.ToBeFilledInByBackend (Evergreen.V386.NonemptyDict.NonemptyDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.User.BackendUser))
    | LoadGuilds (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) Evergreen.V386.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V386.DmChannelId.DmChannelId Evergreen.V386.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) Evergreen.V386.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId) Evergreen.V386.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) Evergreen.V386.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V386.SessionIdHash.SessionIdHash Evergreen.V386.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V386.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V386.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V386.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V386.FileStatus.FileHash Evergreen.V386.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V386.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V386.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V386.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V386.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V386.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V386.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V386.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
    | DeleteGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | RestoreGuild (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) (Evergreen.V386.UserSession.ToBeFilledInByBackend (Result Evergreen.V386.Discord.HttpError (List Evergreen.V386.Discord.Role)))
    | HideLog (Evergreen.V386.Id.Id Evergreen.V386.Pagination.ItemId)
    | UnhideLog (Evergreen.V386.Id.Id Evergreen.V386.Pagination.ItemId)
    | DisconnectClient Evergreen.V386.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V386.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V386.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V386.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V386.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V386.Id.Id Evergreen.V386.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V386.Id.Id Evergreen.V386.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V386.Editable.Model
    , publicVapidKey : Evergreen.V386.Editable.Model
    , privateVapidKey : Evergreen.V386.Editable.Model
    , openRouterKey : Evergreen.V386.Editable.Model
    , postmarkKey : Evergreen.V386.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V386.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
