module Evergreen.V236.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V236.Discord
import Evergreen.V236.Editable
import Evergreen.V236.Id
import Evergreen.V236.LocalState
import Evergreen.V236.NonemptyDict
import Evergreen.V236.Pagination
import Evergreen.V236.Postmark
import Evergreen.V236.SessionIdHash
import Evergreen.V236.Slack
import Evergreen.V236.Table
import Evergreen.V236.ToBackendLog
import Evergreen.V236.User
import Evergreen.V236.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V236.NonemptyDict.NonemptyDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Evergreen.V236.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V236.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V236.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V236.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId) Evergreen.V236.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) Evergreen.V236.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) Evergreen.V236.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) Evergreen.V236.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V236.Pagination.Pagination Evergreen.V236.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V236.SessionIdHash.SessionIdHash (Evergreen.V236.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V236.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V236.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
        }
    | ExpandSection Evergreen.V236.User.AdminUiSection
    | CollapseSection Evergreen.V236.User.AdminUiSection
    | LogPageChanged (Evergreen.V236.Id.Id Evergreen.V236.Pagination.PageId) (Evergreen.V236.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V236.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V236.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V236.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V236.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
    | DeleteGuild (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    | CollapseGuild (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
    | HideLog (Evergreen.V236.Id.Id Evergreen.V236.Pagination.ItemId)
    | UnhideLog (Evergreen.V236.Id.Id Evergreen.V236.Pagination.ItemId)
    | DisconnectClient Evergreen.V236.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V236.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
    | NewUserId Int


type UserColumn
    = NameColumn
    | EmailAddressColumn


type alias EditingCell =
    { userId : UserTableId
    , column : UserColumn
    , text : String
    }


type alias UserTable =
    { table : Evergreen.V236.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
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


type alias Model =
    { highlightLog : Maybe (Evergreen.V236.Id.Id Evergreen.V236.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V236.Id.Id Evergreen.V236.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V236.Editable.Model
    , publicVapidKey : Evergreen.V236.Editable.Model
    , privateVapidKey : Evergreen.V236.Editable.Model
    , openRouterKey : Evergreen.V236.Editable.Model
    , postmarkKey : Evergreen.V236.Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    , exportProgress : Maybe ExportProgress
    }


type ExportSubset
    = ExportSubset
    | ExportAll


type ToFrontend
    = ImportBackendResponse (Result () ())
    | ExportBackendProgress ExportSubset ExportProgress


type Msg
    = PressedLogPage (Evergreen.V236.Id.Id Evergreen.V236.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V236.Id.Id Evergreen.V236.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V236.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V236.User.AdminUiSection
    | PressedExpandSection Evergreen.V236.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V236.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V236.Editable.Msg (Maybe Evergreen.V236.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V236.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V236.Editable.Msg Evergreen.V236.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V236.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V236.Editable.Msg Evergreen.V236.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V236.Id.Id Evergreen.V236.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V236.Id.Id Evergreen.V236.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V236.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
