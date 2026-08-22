module Evergreen.V360.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V360.Discord
import Evergreen.V360.DmChannelId
import Evergreen.V360.Editable
import Evergreen.V360.Id
import Evergreen.V360.LocalState
import Evergreen.V360.NonemptyDict
import Evergreen.V360.Pagination
import Evergreen.V360.Postmark
import Evergreen.V360.SessionIdHash
import Evergreen.V360.Slack
import Evergreen.V360.Table
import Evergreen.V360.ToBackendLog
import Evergreen.V360.User
import Evergreen.V360.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V360.Id.Id Evergreen.V360.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V360.Id.Id Evergreen.V360.Pagination.ItemId)
    | PressedExpandSection Evergreen.V360.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
    | UserTableMsg Evergreen.V360.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V360.Editable.Msg (Maybe Evergreen.V360.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V360.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V360.Editable.Msg Evergreen.V360.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V360.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V360.Editable.Msg Evergreen.V360.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V360.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V360.Id.Id Evergreen.V360.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V360.Id.Id Evergreen.V360.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V360.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V360.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V360.NonemptyDict.NonemptyDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V360.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V360.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V360.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V360.DmChannelId.DmChannelId Evergreen.V360.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId) Evergreen.V360.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) Evergreen.V360.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) Evergreen.V360.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) Evergreen.V360.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V360.Pagination.Pagination Evergreen.V360.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V360.SessionIdHash.SessionIdHash (Evergreen.V360.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V360.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V360.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V360.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V360.SessionIdHash.SessionIdHash Evergreen.V360.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V360.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V360.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
        }
    | ExpandSection Evergreen.V360.User.AdminUiSection
    | CollapseSection Evergreen.V360.User.AdminUiSection
    | LogPageChanged (Evergreen.V360.Id.Id Evergreen.V360.Pagination.PageId) (Evergreen.V360.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V360.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V360.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V360.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V360.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    | DeleteGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | RestoreGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) (Evergreen.V360.UserSession.ToBeFilledInByBackend (Result Evergreen.V360.Discord.HttpError (List Evergreen.V360.Discord.Role)))
    | ExpandGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | CollapseGuild (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    | HideLog (Evergreen.V360.Id.Id Evergreen.V360.Pagination.ItemId)
    | UnhideLog (Evergreen.V360.Id.Id Evergreen.V360.Pagination.ItemId)
    | DisconnectClient Evergreen.V360.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V360.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V360.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V360.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V360.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V360.Id.Id Evergreen.V360.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V360.Id.Id Evergreen.V360.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V360.Editable.Model
    , publicVapidKey : Evergreen.V360.Editable.Model
    , privateVapidKey : Evergreen.V360.Editable.Model
    , openRouterKey : Evergreen.V360.Editable.Model
    , postmarkKey : Evergreen.V360.Editable.Model
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
