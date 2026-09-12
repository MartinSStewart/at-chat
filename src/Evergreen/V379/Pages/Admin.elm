module Evergreen.V379.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V379.BackendMsgLog
import Evergreen.V379.Discord
import Evergreen.V379.DmChannelId
import Evergreen.V379.Editable
import Evergreen.V379.Id
import Evergreen.V379.LocalState
import Evergreen.V379.NonemptyDict
import Evergreen.V379.Pagination
import Evergreen.V379.Postmark
import Evergreen.V379.SessionIdHash
import Evergreen.V379.Slack
import Evergreen.V379.Table
import Evergreen.V379.ToBackendLog
import Evergreen.V379.User
import Evergreen.V379.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V379.Id.Id Evergreen.V379.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V379.Id.Id Evergreen.V379.Pagination.ItemId)
    | PressedExpandSection Evergreen.V379.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | UserTableMsg Evergreen.V379.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V379.Editable.Msg (Maybe Evergreen.V379.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V379.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V379.Editable.Msg Evergreen.V379.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V379.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V379.Editable.Msg Evergreen.V379.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedDownloadLastBackup
    | ToggledExportSubsetGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V379.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V379.Id.Id Evergreen.V379.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V379.Id.Id Evergreen.V379.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V379.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V379.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend
    | PressedSendTypeThatIsAlwaysInvalid


type TypeThatIsAlwaysInvalid
    = TypeThatIsAlwaysInvalid


type alias InitAdminData =
    { users : Evergreen.V379.NonemptyDict.NonemptyDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V379.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V379.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V379.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V379.DmChannelId.DmChannelId Evergreen.V379.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId) Evergreen.V379.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) Evergreen.V379.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) Evergreen.V379.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) Evergreen.V379.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V379.Pagination.Pagination Evergreen.V379.LocalState.LogWithTime
    , connections : List ( Evergreen.V379.SessionIdHash.SessionIdHash, Evergreen.V379.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V379.LocalState.ConnectionData )
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V379.ToBackendLog.ToBackendLogData
    , backendMsgLogs : Array.Array Evergreen.V379.BackendMsgLog.BackendMsgLogData
    , vulnerabilityChecks : String
    , checkToFrontendValidation : TypeThatIsAlwaysInvalid
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , lastBackup : Maybe Evergreen.V379.LocalState.LastBackup
    , websocketCloseEvents : Array.Array Evergreen.V379.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V379.SessionIdHash.SessionIdHash Evergreen.V379.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V379.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V379.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
        }
    | ExpandSection Evergreen.V379.User.AdminUiSection
    | CollapseSection Evergreen.V379.User.AdminUiSection
    | LogPageChanged (Evergreen.V379.Id.Id Evergreen.V379.Pagination.PageId) (Evergreen.V379.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V379.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V379.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V379.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V379.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    | DeleteGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | RestoreGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) (Evergreen.V379.UserSession.ToBeFilledInByBackend (Result Evergreen.V379.Discord.HttpError (List Evergreen.V379.Discord.Role)))
    | ExpandGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | CollapseGuild (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    | HideLog (Evergreen.V379.Id.Id Evergreen.V379.Pagination.ItemId)
    | UnhideLog (Evergreen.V379.Id.Id Evergreen.V379.Pagination.ItemId)
    | DisconnectClient Evergreen.V379.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V379.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V379.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V379.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V379.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    }


type alias DownloadingBackup =
    { totalBytes : Int
    , receivedBytes : Int
    , chunks : List Bytes.Bytes
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V379.Id.Id Evergreen.V379.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V379.Id.Id Evergreen.V379.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V379.Editable.Model
    , publicVapidKey : Evergreen.V379.Editable.Model
    , privateVapidKey : Evergreen.V379.Editable.Model
    , openRouterKey : Evergreen.V379.Editable.Model
    , postmarkKey : Evergreen.V379.Editable.Model
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
    | DownloadLastBackupChunk Evergreen.V379.LocalState.BackupContents Int Bytes.Bytes
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | DownloadLastBackupRequest
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
    | TypeThatIsAlwaysInvalidRequest TypeThatIsAlwaysInvalid
