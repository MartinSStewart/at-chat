module Evergreen.V228.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V228.Discord
import Evergreen.V228.Editable
import Evergreen.V228.Id
import Evergreen.V228.LocalState
import Evergreen.V228.NonemptyDict
import Evergreen.V228.Pagination
import Evergreen.V228.Postmark
import Evergreen.V228.SessionIdHash
import Evergreen.V228.Slack
import Evergreen.V228.Table
import Evergreen.V228.ToBackendLog
import Evergreen.V228.User
import Evergreen.V228.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V228.NonemptyDict.NonemptyDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Evergreen.V228.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V228.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V228.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V228.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId) Evergreen.V228.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) Evergreen.V228.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) Evergreen.V228.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) Evergreen.V228.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V228.Pagination.Pagination Evergreen.V228.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V228.SessionIdHash.SessionIdHash (Evergreen.V228.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V228.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V228.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
        }
    | ExpandSection Evergreen.V228.User.AdminUiSection
    | CollapseSection Evergreen.V228.User.AdminUiSection
    | LogPageChanged (Evergreen.V228.Id.Id Evergreen.V228.Pagination.PageId) (Evergreen.V228.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V228.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V228.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V228.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V228.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
    | DeleteGuild (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    | CollapseGuild (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
    | HideLog (Evergreen.V228.Id.Id Evergreen.V228.Pagination.ItemId)
    | UnhideLog (Evergreen.V228.Id.Id Evergreen.V228.Pagination.ItemId)
    | DisconnectClient Evergreen.V228.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V228.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
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
    { table : Evergreen.V228.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V228.Id.Id Evergreen.V228.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V228.Id.Id Evergreen.V228.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V228.Editable.Model
    , publicVapidKey : Evergreen.V228.Editable.Model
    , privateVapidKey : Evergreen.V228.Editable.Model
    , openRouterKey : Evergreen.V228.Editable.Model
    , postmarkKey : Evergreen.V228.Editable.Model
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
    = PressedLogPage (Evergreen.V228.Id.Id Evergreen.V228.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V228.Id.Id Evergreen.V228.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V228.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V228.User.AdminUiSection
    | PressedExpandSection Evergreen.V228.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V228.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V228.Editable.Msg (Maybe Evergreen.V228.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V228.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V228.Editable.Msg Evergreen.V228.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V228.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V228.Editable.Msg Evergreen.V228.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V228.Id.Id Evergreen.V228.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V228.Id.Id Evergreen.V228.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V228.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
