module Evergreen.V215.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V215.Discord
import Evergreen.V215.Editable
import Evergreen.V215.Id
import Evergreen.V215.LocalState
import Evergreen.V215.NonemptyDict
import Evergreen.V215.Pagination
import Evergreen.V215.Postmark
import Evergreen.V215.SessionIdHash
import Evergreen.V215.Slack
import Evergreen.V215.Table
import Evergreen.V215.ToBackendLog
import Evergreen.V215.User
import Evergreen.V215.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V215.NonemptyDict.NonemptyDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V215.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V215.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V215.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) Evergreen.V215.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Evergreen.V215.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) Evergreen.V215.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V215.Pagination.Pagination Evergreen.V215.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V215.SessionIdHash.SessionIdHash (Evergreen.V215.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V215.LocalState.ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V215.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
        }
    | ExpandSection Evergreen.V215.User.AdminUiSection
    | CollapseSection Evergreen.V215.User.AdminUiSection
    | LogPageChanged (Evergreen.V215.Id.Id Evergreen.V215.Pagination.PageId) (Evergreen.V215.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V215.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V215.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V215.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V215.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
    | DeleteGuild (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    | CollapseGuild (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
    | HideLog (Evergreen.V215.Id.Id Evergreen.V215.Pagination.ItemId)
    | UnhideLog (Evergreen.V215.Id.Id Evergreen.V215.Pagination.ItemId)
    | DisconnectClient Evergreen.V215.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V215.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
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
    { table : Evergreen.V215.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V215.Id.Id Evergreen.V215.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V215.Id.Id Evergreen.V215.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V215.Editable.Model
    , publicVapidKey : Evergreen.V215.Editable.Model
    , privateVapidKey : Evergreen.V215.Editable.Model
    , openRouterKey : Evergreen.V215.Editable.Model
    , postmarkKey : Evergreen.V215.Editable.Model
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
    = PressedLogPage (Evergreen.V215.Id.Id Evergreen.V215.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V215.Id.Id Evergreen.V215.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V215.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V215.User.AdminUiSection
    | PressedExpandSection Evergreen.V215.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V215.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V215.Editable.Msg (Maybe Evergreen.V215.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V215.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V215.Editable.Msg Evergreen.V215.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V215.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V215.Editable.Msg Evergreen.V215.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V215.Id.Id Evergreen.V215.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V215.Id.Id Evergreen.V215.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V215.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
