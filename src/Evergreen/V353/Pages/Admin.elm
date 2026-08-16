module Evergreen.V353.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V353.Discord
import Evergreen.V353.DmChannelId
import Evergreen.V353.Editable
import Evergreen.V353.Id
import Evergreen.V353.LocalState
import Evergreen.V353.NonemptyDict
import Evergreen.V353.Pagination
import Evergreen.V353.Postmark
import Evergreen.V353.SessionIdHash
import Evergreen.V353.Slack
import Evergreen.V353.Table
import Evergreen.V353.ToBackendLog
import Evergreen.V353.User
import Evergreen.V353.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V353.Id.Id Evergreen.V353.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V353.Id.Id Evergreen.V353.Pagination.ItemId)
    | PressedExpandSection Evergreen.V353.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
    | UserTableMsg Evergreen.V353.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V353.Editable.Msg (Maybe Evergreen.V353.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V353.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V353.Editable.Msg Evergreen.V353.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V353.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V353.Editable.Msg Evergreen.V353.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V353.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V353.Id.Id Evergreen.V353.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V353.Id.Id Evergreen.V353.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V353.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V353.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest
    | PressedCountToBackend


type alias InitAdminData =
    { users : Evergreen.V353.NonemptyDict.NonemptyDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Evergreen.V353.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V353.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V353.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V353.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V353.DmChannelId.DmChannelId Evergreen.V353.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId) Evergreen.V353.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) Evergreen.V353.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) Evergreen.V353.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) Evergreen.V353.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V353.Pagination.Pagination Evergreen.V353.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V353.SessionIdHash.SessionIdHash (Evergreen.V353.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V353.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V353.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V353.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V353.SessionIdHash.SessionIdHash Evergreen.V353.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V353.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V353.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
        }
    | ExpandSection Evergreen.V353.User.AdminUiSection
    | CollapseSection Evergreen.V353.User.AdminUiSection
    | LogPageChanged (Evergreen.V353.Id.Id Evergreen.V353.Pagination.PageId) (Evergreen.V353.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V353.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V353.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V353.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V353.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
    | DeleteGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | RestoreGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.UserSession.ToBeFilledInByBackend (Result Evergreen.V353.Discord.HttpError (List Evergreen.V353.Discord.Role)))
    | ExpandGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | CollapseGuild (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId)
    | HideLog (Evergreen.V353.Id.Id Evergreen.V353.Pagination.ItemId)
    | UnhideLog (Evergreen.V353.Id.Id Evergreen.V353.Pagination.ItemId)
    | DisconnectClient Evergreen.V353.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V353.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V353.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V353.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V353.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V353.Id.Id Evergreen.V353.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V353.Id.Id Evergreen.V353.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V353.Editable.Model
    , publicVapidKey : Evergreen.V353.Editable.Model
    , privateVapidKey : Evergreen.V353.Editable.Model
    , openRouterKey : Evergreen.V353.Editable.Model
    , postmarkKey : Evergreen.V353.Editable.Model
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
