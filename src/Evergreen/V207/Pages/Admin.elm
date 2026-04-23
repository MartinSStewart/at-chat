module Evergreen.V207.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V207.Discord
import Evergreen.V207.Editable
import Evergreen.V207.Id
import Evergreen.V207.LocalState
import Evergreen.V207.NonemptyDict
import Evergreen.V207.Pagination
import Evergreen.V207.Postmark
import Evergreen.V207.SessionIdHash
import Evergreen.V207.Slack
import Evergreen.V207.Table
import Evergreen.V207.ToBackendLog
import Evergreen.V207.User
import Evergreen.V207.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V207.NonemptyDict.NonemptyDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V207.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V207.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V207.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) Evergreen.V207.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) Evergreen.V207.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V207.Pagination.Pagination Evergreen.V207.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V207.SessionIdHash.SessionIdHash (Evergreen.V207.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V207.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V207.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
        }
    | ExpandSection Evergreen.V207.User.AdminUiSection
    | CollapseSection Evergreen.V207.User.AdminUiSection
    | LogPageChanged (Evergreen.V207.Id.Id Evergreen.V207.Pagination.PageId) (Evergreen.V207.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V207.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V207.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V207.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V207.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
    | DeleteGuild (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    | CollapseGuild (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
    | HideLog (Evergreen.V207.Id.Id Evergreen.V207.Pagination.ItemId)
    | UnhideLog (Evergreen.V207.Id.Id Evergreen.V207.Pagination.ItemId)
    | DisconnectClient Evergreen.V207.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V207.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
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
    { table : Evergreen.V207.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V207.Id.Id Evergreen.V207.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V207.Id.Id Evergreen.V207.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V207.Editable.Model
    , publicVapidKey : Evergreen.V207.Editable.Model
    , privateVapidKey : Evergreen.V207.Editable.Model
    , openRouterKey : Evergreen.V207.Editable.Model
    , postmarkKey : Evergreen.V207.Editable.Model
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
    = PressedLogPage (Evergreen.V207.Id.Id Evergreen.V207.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V207.Id.Id Evergreen.V207.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V207.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V207.User.AdminUiSection
    | PressedExpandSection Evergreen.V207.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V207.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V207.Editable.Msg (Maybe Evergreen.V207.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V207.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V207.Editable.Msg Evergreen.V207.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V207.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V207.Editable.Msg Evergreen.V207.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V207.Id.Id Evergreen.V207.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V207.Id.Id Evergreen.V207.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V207.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
