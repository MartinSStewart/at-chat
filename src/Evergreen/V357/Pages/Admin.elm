module Evergreen.V357.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V357.Discord
import Evergreen.V357.DmChannelId
import Evergreen.V357.Editable
import Evergreen.V357.Id
import Evergreen.V357.LocalState
import Evergreen.V357.NonemptyDict
import Evergreen.V357.Pagination
import Evergreen.V357.Postmark
import Evergreen.V357.SessionIdHash
import Evergreen.V357.Slack
import Evergreen.V357.Table
import Evergreen.V357.ToBackendLog
import Evergreen.V357.User
import Evergreen.V357.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V357.Id.Id Evergreen.V357.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V357.Id.Id Evergreen.V357.Pagination.ItemId)
    | PressedExpandSection Evergreen.V357.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | UserTableMsg Evergreen.V357.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V357.Editable.Msg (Maybe Evergreen.V357.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V357.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V357.Editable.Msg Evergreen.V357.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V357.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V357.Editable.Msg Evergreen.V357.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V357.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V357.Id.Id Evergreen.V357.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V357.Id.Id Evergreen.V357.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V357.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V357.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V357.NonemptyDict.NonemptyDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V357.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V357.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V357.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V357.DmChannelId.DmChannelId Evergreen.V357.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId) Evergreen.V357.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) Evergreen.V357.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) Evergreen.V357.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) Evergreen.V357.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V357.Pagination.Pagination Evergreen.V357.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V357.SessionIdHash.SessionIdHash (Evergreen.V357.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V357.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V357.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V357.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V357.SessionIdHash.SessionIdHash Evergreen.V357.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V357.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V357.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
        }
    | ExpandSection Evergreen.V357.User.AdminUiSection
    | CollapseSection Evergreen.V357.User.AdminUiSection
    | LogPageChanged (Evergreen.V357.Id.Id Evergreen.V357.Pagination.PageId) (Evergreen.V357.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V357.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V357.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V357.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V357.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
    | DeleteGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | RestoreGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) (Evergreen.V357.UserSession.ToBeFilledInByBackend (Result Evergreen.V357.Discord.HttpError (List Evergreen.V357.Discord.Role)))
    | ExpandGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | CollapseGuild (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId)
    | HideLog (Evergreen.V357.Id.Id Evergreen.V357.Pagination.ItemId)
    | UnhideLog (Evergreen.V357.Id.Id Evergreen.V357.Pagination.ItemId)
    | DisconnectClient Evergreen.V357.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V357.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V357.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V357.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V357.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V357.Id.Id Evergreen.V357.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V357.Id.Id Evergreen.V357.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V357.Editable.Model
    , publicVapidKey : Evergreen.V357.Editable.Model
    , privateVapidKey : Evergreen.V357.Editable.Model
    , openRouterKey : Evergreen.V357.Editable.Model
    , postmarkKey : Evergreen.V357.Editable.Model
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
