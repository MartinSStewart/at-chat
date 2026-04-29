module Evergreen.V210.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V210.Discord
import Evergreen.V210.Editable
import Evergreen.V210.Id
import Evergreen.V210.LocalState
import Evergreen.V210.NonemptyDict
import Evergreen.V210.Pagination
import Evergreen.V210.Postmark
import Evergreen.V210.SessionIdHash
import Evergreen.V210.Slack
import Evergreen.V210.Table
import Evergreen.V210.ToBackendLog
import Evergreen.V210.User
import Evergreen.V210.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V210.NonemptyDict.NonemptyDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Evergreen.V210.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V210.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V210.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V210.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId) Evergreen.V210.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) Evergreen.V210.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) Evergreen.V210.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) Evergreen.V210.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V210.Pagination.Pagination Evergreen.V210.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V210.SessionIdHash.SessionIdHash (Evergreen.V210.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V210.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V210.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
        }
    | ExpandSection Evergreen.V210.User.AdminUiSection
    | CollapseSection Evergreen.V210.User.AdminUiSection
    | LogPageChanged (Evergreen.V210.Id.Id Evergreen.V210.Pagination.PageId) (Evergreen.V210.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V210.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V210.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V210.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V210.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
    | DeleteGuild (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    | CollapseGuild (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
    | HideLog (Evergreen.V210.Id.Id Evergreen.V210.Pagination.ItemId)
    | UnhideLog (Evergreen.V210.Id.Id Evergreen.V210.Pagination.ItemId)
    | DisconnectClient Evergreen.V210.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V210.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
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
    { table : Evergreen.V210.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V210.Id.Id Evergreen.V210.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V210.Id.Id Evergreen.V210.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V210.Editable.Model
    , publicVapidKey : Evergreen.V210.Editable.Model
    , privateVapidKey : Evergreen.V210.Editable.Model
    , openRouterKey : Evergreen.V210.Editable.Model
    , postmarkKey : Evergreen.V210.Editable.Model
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
    = PressedLogPage (Evergreen.V210.Id.Id Evergreen.V210.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V210.Id.Id Evergreen.V210.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V210.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V210.User.AdminUiSection
    | PressedExpandSection Evergreen.V210.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V210.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V210.Editable.Msg (Maybe Evergreen.V210.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V210.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V210.Editable.Msg Evergreen.V210.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V210.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V210.Editable.Msg Evergreen.V210.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V210.Id.Id Evergreen.V210.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V210.Id.Id Evergreen.V210.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V210.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
