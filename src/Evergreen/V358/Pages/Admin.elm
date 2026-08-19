module Evergreen.V358.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V358.Discord
import Evergreen.V358.DmChannelId
import Evergreen.V358.Editable
import Evergreen.V358.Id
import Evergreen.V358.LocalState
import Evergreen.V358.NonemptyDict
import Evergreen.V358.Pagination
import Evergreen.V358.Postmark
import Evergreen.V358.SessionIdHash
import Evergreen.V358.Slack
import Evergreen.V358.Table
import Evergreen.V358.ToBackendLog
import Evergreen.V358.User
import Evergreen.V358.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V358.Id.Id Evergreen.V358.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V358.Id.Id Evergreen.V358.Pagination.ItemId)
    | PressedExpandSection Evergreen.V358.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
    | UserTableMsg Evergreen.V358.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V358.Editable.Msg (Maybe Evergreen.V358.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V358.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V358.Editable.Msg Evergreen.V358.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V358.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V358.Editable.Msg Evergreen.V358.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V358.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V358.Id.Id Evergreen.V358.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V358.Id.Id Evergreen.V358.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V358.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V358.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V358.NonemptyDict.NonemptyDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Evergreen.V358.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V358.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V358.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V358.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V358.DmChannelId.DmChannelId Evergreen.V358.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId) Evergreen.V358.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) Evergreen.V358.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) Evergreen.V358.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) Evergreen.V358.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V358.Pagination.Pagination Evergreen.V358.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V358.SessionIdHash.SessionIdHash (Evergreen.V358.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V358.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V358.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V358.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V358.SessionIdHash.SessionIdHash Evergreen.V358.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V358.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V358.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
        }
    | ExpandSection Evergreen.V358.User.AdminUiSection
    | CollapseSection Evergreen.V358.User.AdminUiSection
    | LogPageChanged (Evergreen.V358.Id.Id Evergreen.V358.Pagination.PageId) (Evergreen.V358.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V358.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V358.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V358.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V358.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
    | DeleteGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | RestoreGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) (Evergreen.V358.UserSession.ToBeFilledInByBackend (Result Evergreen.V358.Discord.HttpError (List Evergreen.V358.Discord.Role)))
    | ExpandGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | CollapseGuild (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId)
    | HideLog (Evergreen.V358.Id.Id Evergreen.V358.Pagination.ItemId)
    | UnhideLog (Evergreen.V358.Id.Id Evergreen.V358.Pagination.ItemId)
    | DisconnectClient Evergreen.V358.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V358.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V358.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V358.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
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
    | ExportingFinalStep Bytes.Bytes


type alias ExportSubsetSelection =
    { dmChannels : SeqSet.SeqSet Evergreen.V358.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V358.Id.Id Evergreen.V358.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V358.Id.Id Evergreen.V358.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V358.Editable.Model
    , publicVapidKey : Evergreen.V358.Editable.Model
    , privateVapidKey : Evergreen.V358.Editable.Model
    , openRouterKey : Evergreen.V358.Editable.Model
    , postmarkKey : Evergreen.V358.Editable.Model
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
