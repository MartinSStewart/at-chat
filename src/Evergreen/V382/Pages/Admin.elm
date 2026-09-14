module Evergreen.V382.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V382.BackendMsgLog
import Evergreen.V382.Discord
import Evergreen.V382.DmChannelId
import Evergreen.V382.Editable
import Evergreen.V382.Id
import Evergreen.V382.LocalState
import Evergreen.V382.NonemptyDict
import Evergreen.V382.Pagination
import Evergreen.V382.Postmark
import Evergreen.V382.SessionIdHash
import Evergreen.V382.Slack
import Evergreen.V382.Table
import Evergreen.V382.ToBackendLog
import Evergreen.V382.User
import Evergreen.V382.UserSession
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
    = ExistingUserId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V382.Id.Id Evergreen.V382.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V382.Id.Id Evergreen.V382.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | UserTableMsg Evergreen.V382.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V382.Editable.Msg (Maybe Evergreen.V382.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V382.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V382.Editable.Msg Evergreen.V382.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V382.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V382.Editable.Msg Evergreen.V382.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V382.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V382.Id.Id Evergreen.V382.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V382.Id.Id Evergreen.V382.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V382.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V382.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V382.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V382.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V382.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V382.Pagination.Pagination Evergreen.V382.LocalState.LogWithTime
    , connections : List ( Evergreen.V382.SessionIdHash.SessionIdHash, Evergreen.V382.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V382.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V382.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V382.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V382.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
        }
    | LogPageChanged (Evergreen.V382.Id.Id Evergreen.V382.Pagination.PageId) (Evergreen.V382.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V382.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V382.UserSession.ToBeFilledInByBackend (Evergreen.V382.NonemptyDict.NonemptyDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) Evergreen.V382.User.BackendUser))
    | LoadGuilds (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) Evergreen.V382.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V382.DmChannelId.DmChannelId Evergreen.V382.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) Evergreen.V382.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId) Evergreen.V382.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) Evergreen.V382.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V382.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V382.SessionIdHash.SessionIdHash Evergreen.V382.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V382.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V382.LocalState.WebsocketClosedEvent))
    | LoadToBackendLogs (Evergreen.V382.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V382.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V382.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V382.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V382.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V382.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V382.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
    | DeleteGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | RestoreGuild (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) (Evergreen.V382.UserSession.ToBeFilledInByBackend (Result Evergreen.V382.Discord.HttpError (List Evergreen.V382.Discord.Role)))
    | HideLog (Evergreen.V382.Id.Id Evergreen.V382.Pagination.ItemId)
    | UnhideLog (Evergreen.V382.Id.Id Evergreen.V382.Pagination.ItemId)
    | DisconnectClient Evergreen.V382.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V382.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V382.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V382.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V382.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V382.Id.Id Evergreen.V382.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V382.Id.Id Evergreen.V382.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V382.Editable.Model
    , publicVapidKey : Evergreen.V382.Editable.Model
    , privateVapidKey : Evergreen.V382.Editable.Model
    , openRouterKey : Evergreen.V382.Editable.Model
    , postmarkKey : Evergreen.V382.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V382.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
