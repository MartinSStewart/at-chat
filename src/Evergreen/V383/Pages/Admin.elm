module Evergreen.V383.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V383.BackendMsgLog
import Evergreen.V383.Discord
import Evergreen.V383.DmChannelId
import Evergreen.V383.Editable
import Evergreen.V383.Id
import Evergreen.V383.LocalState
import Evergreen.V383.NonemptyDict
import Evergreen.V383.Pagination
import Evergreen.V383.Postmark
import Evergreen.V383.SessionIdHash
import Evergreen.V383.Slack
import Evergreen.V383.Table
import Evergreen.V383.ToBackendLog
import Evergreen.V383.User
import Evergreen.V383.UserSession
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
    = ExistingUserId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V383.Id.Id Evergreen.V383.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V383.Id.Id Evergreen.V383.Pagination.ItemId)
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
    | PressedResetUser (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | UserTableMsg Evergreen.V383.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V383.Editable.Msg (Maybe Evergreen.V383.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V383.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V383.Editable.Msg Evergreen.V383.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V383.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V383.Editable.Msg Evergreen.V383.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V383.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V383.Id.Id Evergreen.V383.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V383.Id.Id Evergreen.V383.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V383.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V383.SessionIdHash.SessionIdHash
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
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V383.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V383.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V383.Postmark.ApiKey
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V383.Pagination.Pagination Evergreen.V383.LocalState.LogWithTime
    , connections : List ( Evergreen.V383.SessionIdHash.SessionIdHash, Evergreen.V383.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V383.LocalState.ConnectionData )
    , filesCount : Int
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V383.LocalState.LastBackup
    , wordSpellingGameEnglish : Evergreen.V383.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V383.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
        }
    | LogPageChanged (Evergreen.V383.Id.Id Evergreen.V383.Pagination.PageId) (Evergreen.V383.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V383.LocalState.LogWithTime))
    | LoadUsers (Evergreen.V383.UserSession.ToBeFilledInByBackend (Evergreen.V383.NonemptyDict.NonemptyDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) Evergreen.V383.User.BackendUser))
    | LoadGuilds (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.LocalState.AdminData_Guild))
    | LoadDeletedGuilds (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) Evergreen.V383.LocalState.AdminData_DeletedGuild))
    | LoadDmChannels (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V383.DmChannelId.DmChannelId Evergreen.V383.LocalState.AdminData_DmChannel))
    | LoadDiscordGuilds (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) Evergreen.V383.LocalState.AdminData_DiscordGuild))
    | LoadDiscordDmChannels (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId) Evergreen.V383.LocalState.AdminData_DiscordDmChannel))
    | LoadDiscordUsers (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) Evergreen.V383.LocalState.DiscordUserData_ForAdmin))
    | LoadSessions (Evergreen.V383.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict Evergreen.V383.SessionIdHash.SessionIdHash Evergreen.V383.UserSession.UserSession))
    | LoadWebsocketCloseEvents (Evergreen.V383.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V383.LocalState.WebsocketClosedEvent))
    | LoadToBackendLogs (Evergreen.V383.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V383.ToBackendLog.ToBackendLogData))
    | LoadBackendMsgLogs (Evergreen.V383.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V383.BackendMsgLog.BackendMsgLogData))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V383.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V383.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V383.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
    | DeleteGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | RestoreGuild (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) (Evergreen.V383.UserSession.ToBeFilledInByBackend (Result Evergreen.V383.Discord.HttpError (List Evergreen.V383.Discord.Role)))
    | HideLog (Evergreen.V383.Id.Id Evergreen.V383.Pagination.ItemId)
    | UnhideLog (Evergreen.V383.Id.Id Evergreen.V383.Pagination.ItemId)
    | DisconnectClient Evergreen.V383.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V383.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V383.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V383.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V383.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V383.Id.Id Evergreen.V383.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V383.Id.Id Evergreen.V383.Pagination.ItemId)
    , expandedSections : SeqSet.SeqSet AdminUiSection
    , expandedGuilds : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId)
    , expandedDiscordGuilds : SeqSet.SeqSet (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V383.Editable.Model
    , publicVapidKey : Evergreen.V383.Editable.Model
    , privateVapidKey : Evergreen.V383.Editable.Model
    , openRouterKey : Evergreen.V383.Editable.Model
    , postmarkKey : Evergreen.V383.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V383.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
