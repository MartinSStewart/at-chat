module Evergreen.V351.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V351.Discord
import Evergreen.V351.DmChannelId
import Evergreen.V351.Editable
import Evergreen.V351.Id
import Evergreen.V351.LocalState
import Evergreen.V351.NonemptyDict
import Evergreen.V351.Pagination
import Evergreen.V351.Postmark
import Evergreen.V351.SessionIdHash
import Evergreen.V351.Slack
import Evergreen.V351.Table
import Evergreen.V351.ToBackendLog
import Evergreen.V351.User
import Evergreen.V351.UserSession
import SeqDict
import SeqSet


type UserTableId
    = ExistingUserId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type Msg
    = PressedLogPage (Evergreen.V351.Id.Id Evergreen.V351.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V351.Id.Id Evergreen.V351.Pagination.ItemId)
    | PressedExpandSection Evergreen.V351.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
    | UserTableMsg Evergreen.V351.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggledDiscordLinkingEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | PressedRestoreGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V351.Editable.Msg (Maybe Evergreen.V351.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V351.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V351.Editable.Msg Evergreen.V351.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V351.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V351.Editable.Msg Evergreen.V351.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    | PressedReloadDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | ToggledExportSubsetDmChannel Evergreen.V351.DmChannelId.DmChannelId Bool
    | ToggledExportSubsetDiscordDmChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) Bool
    | PressedConfirmExportSubset
    | PressedCancelExportSubset
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V351.Id.Id Evergreen.V351.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V351.Id.Id Evergreen.V351.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V351.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedDeleteSession Evergreen.V351.SessionIdHash.SessionIdHash
    | PressedRegenerateServerSecret
    | PressedWebsocketCloseEventsPage Int
    | PressedStartWebCodecsTest
    | PressedStopWebCodecsTest


type alias InitAdminData =
    { users : Evergreen.V351.NonemptyDict.NonemptyDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V351.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V351.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V351.Postmark.ApiKey
    , dmChannels : SeqDict.SeqDict Evergreen.V351.DmChannelId.DmChannelId Evergreen.V351.LocalState.AdminData_DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId) Evergreen.V351.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) Evergreen.V351.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) Evergreen.V351.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.LocalState.AdminData_Guild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) Evergreen.V351.LocalState.AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Evergreen.V351.Pagination.Pagination Evergreen.V351.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V351.SessionIdHash.SessionIdHash (Evergreen.V351.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V351.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V351.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V351.LocalState.WebsocketClosedEvent
    , sessions : SeqDict.SeqDict Evergreen.V351.SessionIdHash.SessionIdHash Evergreen.V351.UserSession.UserSession
    , wordSpellingGameEnglish : Evergreen.V351.LocalState.WordSpellingGameStatus
    , wordSpellingGameSwedish : Evergreen.V351.LocalState.WordSpellingGameStatus
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
        }
    | ExpandSection Evergreen.V351.User.AdminUiSection
    | CollapseSection Evergreen.V351.User.AdminUiSection
    | LogPageChanged (Evergreen.V351.Id.Id Evergreen.V351.Pagination.PageId) (Evergreen.V351.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V351.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetDiscordLinkingEnabled Bool
    | SetPrivateVapidKey Evergreen.V351.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V351.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V351.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
    | DeleteGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | RestoreGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    | ReloadDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) (Evergreen.V351.UserSession.ToBeFilledInByBackend (Result Evergreen.V351.Discord.HttpError (List Evergreen.V351.Discord.Role)))
    | ExpandGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | CollapseGuild (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId)
    | HideLog (Evergreen.V351.Id.Id Evergreen.V351.Pagination.ItemId)
    | UnhideLog (Evergreen.V351.Id.Id Evergreen.V351.Pagination.ItemId)
    | DisconnectClient Evergreen.V351.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | DeleteSession Evergreen.V351.SessionIdHash.SessionIdHash
    | RegenerateServerSecret (Evergreen.V351.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V351.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
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
    { dmChannels : SeqSet.SeqSet Evergreen.V351.DmChannelId.DmChannelId
    , discordDmChannels : SeqSet.SeqSet (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    }


type alias Model =
    { highlightLog : Maybe (Evergreen.V351.Id.Id Evergreen.V351.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V351.Id.Id Evergreen.V351.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V351.Editable.Model
    , publicVapidKey : Evergreen.V351.Editable.Model
    , privateVapidKey : Evergreen.V351.Editable.Model
    , openRouterKey : Evergreen.V351.Editable.Model
    , postmarkKey : Evergreen.V351.Editable.Model
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
