module Evergreen.V384.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V384.BackendMsgLog
import Evergreen.V384.Discord
import Evergreen.V384.DmChannelId
import Evergreen.V384.Editable
import Evergreen.V384.Id
import Evergreen.V384.LocalState
import Evergreen.V384.NonemptyDict
import Evergreen.V384.Pagination
import Evergreen.V384.Postmark
import Evergreen.V384.SessionIdHash
import Evergreen.V384.Slack
import Evergreen.V384.Table
import Evergreen.V384.ToBackendLog
import Evergreen.V384.User
import Evergreen.V384.UserSession
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
    = ExistingUserId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V384.Id.Id Evergreen.V384.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V384.Id.Id Evergreen.V384.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | UserTableMsg Evergreen.V384.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V384.Editable.Msg (Maybe Evergreen.V384.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V384.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V384.Editable.Msg Evergreen.V384.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V384.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V384.Editable.Msg Evergreen.V384.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V384.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V384.Id.Id Evergreen.V384.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V384.Id.Id Evergreen.V384.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V384.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V384.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V384.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V384.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V384.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V384.Pagination.Pagination Evergreen.V384.LocalState.LogWithTime
    , connections : List ( Evergreen.V384.SessionIdHash.SessionIdHash, Evergreen.V384.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V384.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V384.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V384.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V384.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
        }
    | LogPageChanged (Evergreen.V384.Id.Id Evergreen.V384.Pagination.PageId) (Evergreen.V384.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V384.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V384.UserSession.ToBeFilledInByBackend (Evergreen.V384.NonemptyDict.NonemptyDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) Evergreen.V384.User.BackendUser))
    | LoadGuilds (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) Evergreen.V384.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V384.DmChannelId.DmChannelId Evergreen.V384.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) Evergreen.V384.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId) Evergreen.V384.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) Evergreen.V384.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V384.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V384.SessionIdHash.SessionIdHash Evergreen.V384.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V384.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V384.LocalState.WebsocketClosedEvent))
    | LoadToBackendLogs (Evergreen.V384.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V384.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V384.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V384.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V384.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V384.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V384.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
    | DeleteGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | RestoreGuild (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) (Evergreen.V384.UserSession.ToBeFilledInByBackend (Result Evergreen.V384.Discord.HttpError (List Evergreen.V384.Discord.Role)))
    | HideLog (Evergreen.V384.Id.Id Evergreen.V384.Pagination.ItemId)
    | UnhideLog (Evergreen.V384.Id.Id Evergreen.V384.Pagination.ItemId)
    | DisconnectClient Evergreen.V384.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V384.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V384.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V384.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V384.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V384.Id.Id Evergreen.V384.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V384.Id.Id Evergreen.V384.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V384.Editable.Model
    , publicVapidKey : Evergreen.V384.Editable.Model
    , privateVapidKey : Evergreen.V384.Editable.Model
    , openRouterKey : Evergreen.V384.Editable.Model
    , postmarkKey : Evergreen.V384.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V384.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
