module Evergreen.V381.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V381.BackendMsgLog
import Evergreen.V381.Discord
import Evergreen.V381.DmChannelId
import Evergreen.V381.Editable
import Evergreen.V381.Id
import Evergreen.V381.LocalState
import Evergreen.V381.NonemptyDict
import Evergreen.V381.Pagination
import Evergreen.V381.Postmark
import Evergreen.V381.SessionIdHash
import Evergreen.V381.Slack
import Evergreen.V381.Table
import Evergreen.V381.ToBackendLog
import Evergreen.V381.User
import Evergreen.V381.UserSession
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
    = ExistingUserId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V381.Id.Id Evergreen.V381.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V381.Id.Id Evergreen.V381.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | UserTableMsg Evergreen.V381.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V381.Editable.Msg (Maybe Evergreen.V381.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V381.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V381.Editable.Msg Evergreen.V381.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V381.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V381.Editable.Msg Evergreen.V381.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V381.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V381.Id.Id Evergreen.V381.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V381.Id.Id Evergreen.V381.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V381.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V381.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V381.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V381.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V381.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V381.Pagination.Pagination Evergreen.V381.LocalState.LogWithTime
    , connections : List ( Evergreen.V381.SessionIdHash.SessionIdHash, Evergreen.V381.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V381.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V381.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V381.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V381.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
        }
    | LogPageChanged (Evergreen.V381.Id.Id Evergreen.V381.Pagination.PageId) (Evergreen.V381.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V381.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V381.UserSession.ToBeFilledInByBackend (Evergreen.V381.NonemptyDict.NonemptyDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) Evergreen.V381.User.BackendUser))
    | LoadGuilds (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) Evergreen.V381.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V381.DmChannelId.DmChannelId Evergreen.V381.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) Evergreen.V381.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId) Evergreen.V381.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) Evergreen.V381.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V381.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V381.SessionIdHash.SessionIdHash Evergreen.V381.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V381.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V381.LocalState.WebsocketClosedEvent))
    | LoadToBackendLogs (Evergreen.V381.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V381.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V381.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V381.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V381.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V381.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V381.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
    | DeleteGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | RestoreGuild (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) (Evergreen.V381.UserSession.ToBeFilledInByBackend (Result Evergreen.V381.Discord.HttpError (List Evergreen.V381.Discord.Role)))
    | HideLog (Evergreen.V381.Id.Id Evergreen.V381.Pagination.ItemId)
    | UnhideLog (Evergreen.V381.Id.Id Evergreen.V381.Pagination.ItemId)
    | DisconnectClient Evergreen.V381.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V381.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V381.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V381.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V381.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V381.Id.Id Evergreen.V381.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V381.Id.Id Evergreen.V381.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V381.Editable.Model
    , publicVapidKey : Evergreen.V381.Editable.Model
    , privateVapidKey : Evergreen.V381.Editable.Model
    , openRouterKey : Evergreen.V381.Editable.Model
    , postmarkKey : Evergreen.V381.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V381.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
