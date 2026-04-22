module Evergreen.V206.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Lamdera
import Effect.Time
import Evergreen.V206.Discord
import Evergreen.V206.Editable
import Evergreen.V206.Id
import Evergreen.V206.LocalState
import Evergreen.V206.NonemptyDict
import Evergreen.V206.Pagination
import Evergreen.V206.Postmark
import Evergreen.V206.SessionIdHash
import Evergreen.V206.Slack
import Evergreen.V206.Table
import Evergreen.V206.ToBackendLog
import Evergreen.V206.User
import Evergreen.V206.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V206.NonemptyDict.NonemptyDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V206.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V206.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V206.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) Evergreen.V206.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) Evergreen.V206.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V206.Pagination.Pagination Evergreen.V206.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V206.SessionIdHash.SessionIdHash (Evergreen.V206.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V206.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V206.ToBackendLog.ToBackendLogData
    , vulnerabilityChecks : String
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
        }
    | ExpandSection Evergreen.V206.User.AdminUiSection
    | CollapseSection Evergreen.V206.User.AdminUiSection
    | LogPageChanged (Evergreen.V206.Id.Id Evergreen.V206.Pagination.PageId) (Evergreen.V206.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V206.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V206.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V206.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V206.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
    | DeleteGuild (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    | CollapseGuild (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
    | HideLog (Evergreen.V206.Id.Id Evergreen.V206.Pagination.ItemId)
    | UnhideLog (Evergreen.V206.Id.Id Evergreen.V206.Pagination.ItemId)
    | DisconnectClient Evergreen.V206.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type UserTableId
    = ExistingUserId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
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
    { table : Evergreen.V206.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V206.Id.Id Evergreen.V206.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V206.Id.Id Evergreen.V206.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V206.Editable.Model
    , publicVapidKey : Evergreen.V206.Editable.Model
    , privateVapidKey : Evergreen.V206.Editable.Model
    , openRouterKey : Evergreen.V206.Editable.Model
    , postmarkKey : Evergreen.V206.Editable.Model
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
    = PressedLogPage (Evergreen.V206.Id.Id Evergreen.V206.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V206.Id.Id Evergreen.V206.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V206.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V206.User.AdminUiSection
    | PressedExpandSection Evergreen.V206.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V206.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V206.Editable.Msg (Maybe Evergreen.V206.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V206.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V206.Editable.Msg Evergreen.V206.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V206.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V206.Editable.Msg Evergreen.V206.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V206.Id.Id Evergreen.V206.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V206.Id.Id Evergreen.V206.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V206.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
