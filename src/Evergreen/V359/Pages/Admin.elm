module Evergreen.V359.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V359.Discord
import Evergreen.V359.DmChannelId
import Evergreen.V359.Editable
import Evergreen.V359.Id
import Evergreen.V359.LocalState
import Evergreen.V359.NonemptyDict
import Evergreen.V359.Pagination
import Evergreen.V359.Postmark
import Evergreen.V359.SessionIdHash
import Evergreen.V359.Slack
import Evergreen.V359.Table
import Evergreen.V359.ToBackendLog
import Evergreen.V359.User
import Evergreen.V359.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V359.Id.Id Evergreen.V359.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V359.Id.Id Evergreen.V359.Pagination.ItemId)
    | PressedExpandSection Evergreen.V359.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
    | UserTableMsg Evergreen.V359.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V359.Editable.Msg (Maybe Evergreen.V359.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V359.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V359.Editable.Msg Evergreen.V359.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V359.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V359.Editable.Msg Evergreen.V359.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V359.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V359.Id.Id Evergreen.V359.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V359.Id.Id Evergreen.V359.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V359.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V359.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V359.NonemptyDict.NonemptyDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V359.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V359.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V359.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V359.DmChannelId.DmChannelId Evergreen.V359.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId) Evergreen.V359.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) Evergreen.V359.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) Evergreen.V359.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) Evergreen.V359.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V359.Pagination.Pagination Evergreen.V359.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V359.SessionIdHash.SessionIdHash (Evergreen.V359.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V359.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V359.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V359.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V359.SessionIdHash.SessionIdHash Evergreen.V359.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V359.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V359.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
        }
    | ExpandSection Evergreen.V359.User.AdminUiSection
    | CollapseSection Evergreen.V359.User.AdminUiSection
    | LogPageChanged (Evergreen.V359.Id.Id Evergreen.V359.Pagination.PageId) (Evergreen.V359.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V359.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V359.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V359.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V359.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    | DeleteGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | RestoreGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) (Evergreen.V359.UserSession.ToBeFilledInByBackend (Result Evergreen.V359.Discord.HttpError (List Evergreen.V359.Discord.Role)))
    | ExpandGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | CollapseGuild (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    | HideLog (Evergreen.V359.Id.Id Evergreen.V359.Pagination.ItemId)
    | UnhideLog (Evergreen.V359.Id.Id Evergreen.V359.Pagination.ItemId)
    | DisconnectClient Evergreen.V359.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V359.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V359.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V359.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V359.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V359.Id.Id Evergreen.V359.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V359.Id.Id Evergreen.V359.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V359.Editable.Model
    , publicVapidKey : Evergreen.V359.Editable.Model
    , privateVapidKey : Evergreen.V359.Editable.Model
    , openRouterKey : Evergreen.V359.Editable.Model
    , postmarkKey : Evergreen.V359.Editable.Model
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
