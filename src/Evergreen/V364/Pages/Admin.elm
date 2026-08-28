module Evergreen.V364.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V364.Discord
import Evergreen.V364.DmChannelId
import Evergreen.V364.Editable
import Evergreen.V364.Id
import Evergreen.V364.LocalState
import Evergreen.V364.NonemptyDict
import Evergreen.V364.Pagination
import Evergreen.V364.Postmark
import Evergreen.V364.SessionIdHash
import Evergreen.V364.Slack
import Evergreen.V364.Table
import Evergreen.V364.ToBackendLog
import Evergreen.V364.User
import Evergreen.V364.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V364.Id.Id Evergreen.V364.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V364.Id.Id Evergreen.V364.Pagination.ItemId)
    | PressedExpandSection Evergreen.V364.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
    | UserTableMsg Evergreen.V364.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V364.Editable.Msg (Maybe Evergreen.V364.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V364.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V364.Editable.Msg Evergreen.V364.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V364.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V364.Editable.Msg Evergreen.V364.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V364.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V364.Id.Id Evergreen.V364.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V364.Id.Id Evergreen.V364.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V364.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V364.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V364.NonemptyDict.NonemptyDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V364.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V364.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V364.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V364.DmChannelId.DmChannelId Evergreen.V364.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId) Evergreen.V364.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) Evergreen.V364.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) Evergreen.V364.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) Evergreen.V364.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V364.Pagination.Pagination Evergreen.V364.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V364.SessionIdHash.SessionIdHash (Evergreen.V364.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V364.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V364.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V364.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V364.SessionIdHash.SessionIdHash Evergreen.V364.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V364.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V364.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
        }
    | ExpandSection Evergreen.V364.User.AdminUiSection
    | CollapseSection Evergreen.V364.User.AdminUiSection
    | LogPageChanged (Evergreen.V364.Id.Id Evergreen.V364.Pagination.PageId) (Evergreen.V364.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V364.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V364.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V364.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V364.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    | DeleteGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | RestoreGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) (Evergreen.V364.UserSession.ToBeFilledInByBackend (Result Evergreen.V364.Discord.HttpError (List Evergreen.V364.Discord.Role)))
    | ExpandGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | CollapseGuild (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    | HideLog (Evergreen.V364.Id.Id Evergreen.V364.Pagination.ItemId)
    | UnhideLog (Evergreen.V364.Id.Id Evergreen.V364.Pagination.ItemId)
    | DisconnectClient Evergreen.V364.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V364.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V364.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V364.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V364.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V364.Id.Id Evergreen.V364.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V364.Id.Id Evergreen.V364.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V364.Editable.Model
    , publicVapidKey : Evergreen.V364.Editable.Model
    , privateVapidKey : Evergreen.V364.Editable.Model
    , openRouterKey : Evergreen.V364.Editable.Model
    , postmarkKey : Evergreen.V364.Editable.Model
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
