module Evergreen.V352.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V352.Discord
import Evergreen.V352.DmChannelId
import Evergreen.V352.Editable
import Evergreen.V352.Id
import Evergreen.V352.LocalState
import Evergreen.V352.NonemptyDict
import Evergreen.V352.Pagination
import Evergreen.V352.Postmark
import Evergreen.V352.SessionIdHash
import Evergreen.V352.Slack
import Evergreen.V352.Table
import Evergreen.V352.ToBackendLog
import Evergreen.V352.User
import Evergreen.V352.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V352.Id.Id Evergreen.V352.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V352.Id.Id Evergreen.V352.Pagination.ItemId)
    | PressedExpandSection Evergreen.V352.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
    | UserTableMsg Evergreen.V352.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V352.Editable.Msg (Maybe Evergreen.V352.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V352.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V352.Editable.Msg Evergreen.V352.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V352.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V352.Editable.Msg Evergreen.V352.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V352.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V352.Id.Id Evergreen.V352.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V352.Id.Id Evergreen.V352.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V352.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V352.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest


type alias InitAdminData =
    { users : Evergreen.V352.NonemptyDict.NonemptyDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Evergreen.V352.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V352.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V352.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V352.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V352.DmChannelId.DmChannelId Evergreen.V352.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId) Evergreen.V352.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) Evergreen.V352.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) Evergreen.V352.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) Evergreen.V352.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V352.Pagination.Pagination Evergreen.V352.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V352.SessionIdHash.SessionIdHash (Evergreen.V352.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V352.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V352.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V352.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V352.SessionIdHash.SessionIdHash Evergreen.V352.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V352.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V352.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
        }
    | ExpandSection Evergreen.V352.User.AdminUiSection
    | CollapseSection Evergreen.V352.User.AdminUiSection
    | LogPageChanged (Evergreen.V352.Id.Id Evergreen.V352.Pagination.PageId) (Evergreen.V352.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V352.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V352.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V352.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V352.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
    | DeleteGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | RestoreGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId) (Evergreen.V352.UserSession.ToBeFilledInByBackend (Result Evergreen.V352.Discord.HttpError (List Evergreen.V352.Discord.Role)))
    | ExpandGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | CollapseGuild (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId)
    | HideLog (Evergreen.V352.Id.Id Evergreen.V352.Pagination.ItemId)
    | UnhideLog (Evergreen.V352.Id.Id Evergreen.V352.Pagination.ItemId)
    | DisconnectClient Evergreen.V352.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V352.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V352.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V352.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V352.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V352.Id.Id Evergreen.V352.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V352.Id.Id Evergreen.V352.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V352.Editable.Model
    , publicVapidKey : Evergreen.V352.Editable.Model
    , privateVapidKey : Evergreen.V352.Editable.Model
    , openRouterKey : Evergreen.V352.Editable.Model
    , postmarkKey : Evergreen.V352.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    , exportSubsetSelection : Maybe ExportSubsetSelection
    , websocketCloseEventsPage : Int
    }


type ExportSubset
    = ExportSubset ExportSubsetSelection
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
