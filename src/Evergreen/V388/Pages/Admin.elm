module Evergreen.V388.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V388.BackendMsgLog
import Evergreen.V388.Discord
import Evergreen.V388.DmChannelId
import Evergreen.V388.Editable
import Evergreen.V388.FileStatus
import Evergreen.V388.Id
import Evergreen.V388.LocalState
import Evergreen.V388.NonemptyDict
import Evergreen.V388.Pagination
import Evergreen.V388.Postmark
import Evergreen.V388.SessionIdHash
import Evergreen.V388.Slack
import Evergreen.V388.Table
import Evergreen.V388.ToBackendLog
import Evergreen.V388.User
import Evergreen.V388.UserSession
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
    = ExistingUserId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V388.Id.Id Evergreen.V388.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V388.Id.Id Evergreen.V388.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | UserTableMsg Evergreen.V388.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V388.Editable.Msg (Maybe Evergreen.V388.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V388.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V388.Editable.Msg Evergreen.V388.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V388.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V388.Editable.Msg Evergreen.V388.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V388.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V388.Id.Id Evergreen.V388.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V388.Id.Id Evergreen.V388.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V388.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V388.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V388.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V388.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V388.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V388.Pagination.Pagination Evergreen.V388.LocalState.LogWithTime
    , connections : List ( Evergreen.V388.SessionIdHash.SessionIdHash, Evergreen.V388.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V388.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V388.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V388.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V388.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
        }
    | LogPageChanged (Evergreen.V388.Id.Id Evergreen.V388.Pagination.PageId) (Evergreen.V388.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V388.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V388.UserSession.ToBeFilledInByBackend (Evergreen.V388.NonemptyDict.NonemptyDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) Evergreen.V388.User.BackendUser))
    | LoadGuilds (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) Evergreen.V388.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V388.DmChannelId.DmChannelId Evergreen.V388.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) Evergreen.V388.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId) Evergreen.V388.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) Evergreen.V388.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V388.SessionIdHash.SessionIdHash Evergreen.V388.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V388.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V388.LocalState.WebsocketClosedEvent))
    | LoadOrphanedFiles (Evergreen.V388.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V388.FileStatus.FileHash Evergreen.V388.FileStatus.BackendFileData))
    | LoadToBackendLogs (Evergreen.V388.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V388.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V388.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V388.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V388.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V388.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V388.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
    | DeleteGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | RestoreGuild (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) (Evergreen.V388.UserSession.ToBeFilledInByBackend (Result Evergreen.V388.Discord.HttpError (List Evergreen.V388.Discord.Role)))
    | HideLog (Evergreen.V388.Id.Id Evergreen.V388.Pagination.ItemId)
    | UnhideLog (Evergreen.V388.Id.Id Evergreen.V388.Pagination.ItemId)
    | DisconnectClient Evergreen.V388.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V388.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V388.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))
    | DeleteOrphanedFiles (Evergreen.V388.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error (List Evergreen.V388.FileStatus.FileHash)))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V388.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V388.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V388.Id.Id Evergreen.V388.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V388.Id.Id Evergreen.V388.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V388.Editable.Model
    , publicVapidKey : Evergreen.V388.Editable.Model
    , privateVapidKey : Evergreen.V388.Editable.Model
    , openRouterKey : Evergreen.V388.Editable.Model
    , postmarkKey : Evergreen.V388.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V388.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
