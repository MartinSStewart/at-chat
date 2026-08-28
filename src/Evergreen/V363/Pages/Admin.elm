module Evergreen.V363.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V363.Discord
import Evergreen.V363.DmChannelId
import Evergreen.V363.Editable
import Evergreen.V363.Id
import Evergreen.V363.LocalState
import Evergreen.V363.NonemptyDict
import Evergreen.V363.Pagination
import Evergreen.V363.Postmark
import Evergreen.V363.SessionIdHash
import Evergreen.V363.Slack
import Evergreen.V363.Table
import Evergreen.V363.ToBackendLog
import Evergreen.V363.User
import Evergreen.V363.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V363.Id.Id Evergreen.V363.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V363.Id.Id Evergreen.V363.Pagination.ItemId)
    | PressedExpandSection Evergreen.V363.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
    | UserTableMsg Evergreen.V363.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V363.Editable.Msg (Maybe Evergreen.V363.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V363.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V363.Editable.Msg Evergreen.V363.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V363.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V363.Editable.Msg Evergreen.V363.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Bool
    | ToggledExportSubsetDmChannel Evergreen.V363.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V363.Id.Id Evergreen.V363.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V363.Id.Id Evergreen.V363.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V363.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V363.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V363.NonemptyDict.NonemptyDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V363.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V363.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V363.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V363.DmChannelId.DmChannelId Evergreen.V363.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId) Evergreen.V363.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) Evergreen.V363.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) Evergreen.V363.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) Evergreen.V363.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V363.Pagination.Pagination Evergreen.V363.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V363.SessionIdHash.SessionIdHash (Evergreen.V363.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V363.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V363.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V363.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V363.SessionIdHash.SessionIdHash Evergreen.V363.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V363.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V363.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
        }
    | ExpandSection Evergreen.V363.User.AdminUiSection
    | CollapseSection Evergreen.V363.User.AdminUiSection
    | LogPageChanged (Evergreen.V363.Id.Id Evergreen.V363.Pagination.PageId) (Evergreen.V363.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V363.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V363.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V363.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V363.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    | DeleteGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | RestoreGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) (Evergreen.V363.UserSession.ToBeFilledInByBackend (Result Evergreen.V363.Discord.HttpError (List Evergreen.V363.Discord.Role)))
    | ExpandGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | CollapseGuild (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    | HideLog (Evergreen.V363.Id.Id Evergreen.V363.Pagination.ItemId)
    | UnhideLog (Evergreen.V363.Id.Id Evergreen.V363.Pagination.ItemId)
    | DisconnectClient Evergreen.V363.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V363.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V363.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V363.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
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
    { guilds : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId)
    , dmChannels : SeqSet.SeqSet Evergreen.V363.DmChannelId.DmChannelId
    , discordGuilds : SeqSet.SeqSet (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId)
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V363.Id.Id Evergreen.V363.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V363.Id.Id Evergreen.V363.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V363.Editable.Model
    , publicVapidKey : Evergreen.V363.Editable.Model
    , privateVapidKey : Evergreen.V363.Editable.Model
    , openRouterKey : Evergreen.V363.Editable.Model
    , postmarkKey : Evergreen.V363.Editable.Model
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
