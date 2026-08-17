module Evergreen.V354.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V354.Discord
import Evergreen.V354.DmChannelId
import Evergreen.V354.Editable
import Evergreen.V354.Id
import Evergreen.V354.LocalState
import Evergreen.V354.NonemptyDict
import Evergreen.V354.Pagination
import Evergreen.V354.Postmark
import Evergreen.V354.SessionIdHash
import Evergreen.V354.Slack
import Evergreen.V354.Table
import Evergreen.V354.ToBackendLog
import Evergreen.V354.User
import Evergreen.V354.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V354.Id.Id Evergreen.V354.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V354.Id.Id Evergreen.V354.Pagination.ItemId)
    | PressedExpandSection Evergreen.V354.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
    | UserTableMsg Evergreen.V354.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V354.Editable.Msg (Maybe Evergreen.V354.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V354.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V354.Editable.Msg Evergreen.V354.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V354.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V354.Editable.Msg Evergreen.V354.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V354.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V354.Id.Id Evergreen.V354.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V354.Id.Id Evergreen.V354.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V354.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V354.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V354.NonemptyDict.NonemptyDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Evergreen.V354.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V354.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V354.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V354.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V354.DmChannelId.DmChannelId Evergreen.V354.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId) Evergreen.V354.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) Evergreen.V354.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) Evergreen.V354.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) Evergreen.V354.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V354.Pagination.Pagination Evergreen.V354.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V354.SessionIdHash.SessionIdHash (Evergreen.V354.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V354.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V354.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V354.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V354.SessionIdHash.SessionIdHash Evergreen.V354.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V354.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V354.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
        }
    | ExpandSection Evergreen.V354.User.AdminUiSection
    | CollapseSection Evergreen.V354.User.AdminUiSection
    | LogPageChanged (Evergreen.V354.Id.Id Evergreen.V354.Pagination.PageId) (Evergreen.V354.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V354.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V354.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V354.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V354.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
    | DeleteGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | RestoreGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) (Evergreen.V354.UserSession.ToBeFilledInByBackend (Result Evergreen.V354.Discord.HttpError (List Evergreen.V354.Discord.Role)))
    | ExpandGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | CollapseGuild (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId)
    | HideLog (Evergreen.V354.Id.Id Evergreen.V354.Pagination.ItemId)
    | UnhideLog (Evergreen.V354.Id.Id Evergreen.V354.Pagination.ItemId)
    | DisconnectClient Evergreen.V354.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V354.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V354.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V354.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
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
        { encoded : Int
        , total : Int
        }
    | ExportingDmChannels
        { encoded : Int
        , total : Int
        }
    | ExportingDiscordGuilds
        { encoded : Int
        , total : Int
        }
    | ExportingDiscordDmChannels
        { encoded : Int
        , total : Int
        }
    | ExportingFinalStep Bytes.Bytes


type alias ExportSubsetSelection =
    { dmChannels : SeqSet.SeqSet Evergreen.V354.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V354.Id.Id Evergreen.V354.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V354.Id.Id Evergreen.V354.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V354.Editable.Model
    , publicVapidKey : Evergreen.V354.Editable.Model
    , privateVapidKey : Evergreen.V354.Editable.Model
    , openRouterKey : Evergreen.V354.Editable.Model
    , postmarkKey : Evergreen.V354.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    , countToFrontend : String
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress
    | CountToFrontend Int


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
    | CountToBackendRequest
