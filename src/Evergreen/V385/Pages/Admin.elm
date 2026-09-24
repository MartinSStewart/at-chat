module Evergreen.V385.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V385.BackendMsgLog
import Evergreen.V385.Discord
import Evergreen.V385.DmChannelId
import Evergreen.V385.Editable
import Evergreen.V385.Id
import Evergreen.V385.LocalState
import Evergreen.V385.NonemptyDict
import Evergreen.V385.Pagination
import Evergreen.V385.Postmark
import Evergreen.V385.SessionIdHash
import Evergreen.V385.Slack
import Evergreen.V385.Table
import Evergreen.V385.ToBackendLog
import Evergreen.V385.User
import Evergreen.V385.UserSession
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
    = ExistingUserId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V385.Id.Id Evergreen.V385.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V385.Id.Id Evergreen.V385.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | UserTableMsg Evergreen.V385.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V385.Editable.Msg (Maybe Evergreen.V385.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V385.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V385.Editable.Msg Evergreen.V385.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V385.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V385.Editable.Msg Evergreen.V385.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V385.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V385.Id.Id Evergreen.V385.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V385.Id.Id Evergreen.V385.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V385.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V385.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V385.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V385.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V385.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V385.Pagination.Pagination Evergreen.V385.LocalState.LogWithTime
    , connections : List ( Evergreen.V385.SessionIdHash.SessionIdHash, Evergreen.V385.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V385.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V385.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V385.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V385.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
        }
    | LogPageChanged (Evergreen.V385.Id.Id Evergreen.V385.Pagination.PageId) (Evergreen.V385.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V385.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V385.UserSession.ToBeFilledInByBackend (Evergreen.V385.NonemptyDict.NonemptyDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.User.BackendUser))
    | LoadGuilds (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) Evergreen.V385.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V385.DmChannelId.DmChannelId Evergreen.V385.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) Evergreen.V385.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId) Evergreen.V385.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) Evergreen.V385.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V385.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V385.SessionIdHash.SessionIdHash Evergreen.V385.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V385.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V385.LocalState.WebsocketClosedEvent))
    | LoadToBackendLogs (Evergreen.V385.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V385.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V385.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V385.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V385.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V385.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V385.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
    | DeleteGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | RestoreGuild (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) (Evergreen.V385.UserSession.ToBeFilledInByBackend (Result Evergreen.V385.Discord.HttpError (List Evergreen.V385.Discord.Role)))
    | HideLog (Evergreen.V385.Id.Id Evergreen.V385.Pagination.ItemId)
    | UnhideLog (Evergreen.V385.Id.Id Evergreen.V385.Pagination.ItemId)
    | DisconnectClient Evergreen.V385.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V385.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V385.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V385.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V385.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V385.Id.Id Evergreen.V385.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V385.Id.Id Evergreen.V385.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V385.Editable.Model
    , publicVapidKey : Evergreen.V385.Editable.Model
    , privateVapidKey : Evergreen.V385.Editable.Model
    , openRouterKey : Evergreen.V385.Editable.Model
    , postmarkKey : Evergreen.V385.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V385.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
