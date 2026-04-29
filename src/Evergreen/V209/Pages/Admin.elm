module Evergreen.V209.Pages.Admin exposing (..)

import Array
import Bytes
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V209.Discord
import Evergreen.V209.Editable
import Evergreen.V209.Id
import Evergreen.V209.LocalState
import Evergreen.V209.NonemptyDict
import Evergreen.V209.Pagination
import Evergreen.V209.Postmark
import Evergreen.V209.SessionIdHash
import Evergreen.V209.Slack
import Evergreen.V209.Table
import Evergreen.V209.ToBackendLog
import Evergreen.V209.User
import Evergreen.V209.UserSession
import SeqDict
import SeqSet


type alias InitAdminData =
    { users : Evergreen.V209.NonemptyDict.NonemptyDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.User.BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Effect.Time.Posix
    , privateVapidKey : Evergreen.V209.LocalState.PrivateVapidKey
    , slackClientSecret : Maybe Evergreen.V209.Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkApiKey : Evergreen.V209.Postmark.ApiKey
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) Evergreen.V209.LocalState.AdminData_DiscordDmChannel
    , discordUsers : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.LocalState.DiscordUserData_ForAdmin
    , discordGuilds : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.LocalState.AdminData_DiscordGuild
    , guilds : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) Evergreen.V209.LocalState.AdminData_Guild
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.LocalState.LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Evergreen.V209.Pagination.Pagination Evergreen.V209.LocalState.LogWithTime
    , connections : SeqDict.SeqDict Evergreen.V209.SessionIdHash.SessionIdHash (Evergreen.V209.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V209.LocalState.LastRequest)
    , filesCount : Int
    , toBackendLogs : Array.Array Evergreen.V209.ToBackendLog.ToBackendLogData
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
        , changedUsers : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) EditedBackendUser
        , newUsers : Array.Array EditedBackendUser
        , deletedUsers : SeqSet.SeqSet (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
        }
    | ExpandSection Evergreen.V209.User.AdminUiSection
    | CollapseSection Evergreen.V209.User.AdminUiSection
    | LogPageChanged (Evergreen.V209.Id.Id Evergreen.V209.Pagination.PageId) (Evergreen.V209.UserSession.ToBeFilledInByBackend (Array.Array Evergreen.V209.LocalState.LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey Evergreen.V209.LocalState.PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Evergreen.V209.Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | SetPostmarkKey Evergreen.V209.Postmark.ApiKey
    | DeleteDiscordDmChannel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId)
    | DeleteDiscordGuild (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
    | DeleteGuild (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    | StartReloadingDiscordGuildChannel Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId)
    | StartReloadingDiscordDmChannel Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId)
    | ExpandGuild (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    | CollapseGuild (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    | ExpandDiscordGuild (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
    | CollapseDiscordGuild (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
    | HideLog (Evergreen.V209.Id.Id Evergreen.V209.Pagination.ItemId)
    | UnhideLog (Evergreen.V209.Id.Id Evergreen.V209.Pagination.ItemId)
    | DisconnectClient Evergreen.V209.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | RegenerateServerSecret (Evergreen.V209.UserSession.ToBeFilledInByBackend (Result Effect.Http.Error Effect.Time.Posix))


type UserTableId
    = ExistingUserId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
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
    { table : Evergreen.V209.Table.Model
    , changedUsers : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array.Array EditedBackendUser
    , deletedUsers : SeqSet.SeqSet (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
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
    { highlightLog : Maybe (Evergreen.V209.Id.Id Evergreen.V209.Pagination.ItemId)
    , copiedLogLink : Maybe (Evergreen.V209.Id.Id Evergreen.V209.Pagination.ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Evergreen.V209.Editable.Model
    , publicVapidKey : Evergreen.V209.Editable.Model
    , privateVapidKey : Evergreen.V209.Editable.Model
    , openRouterKey : Evergreen.V209.Editable.Model
    , postmarkKey : Evergreen.V209.Editable.Model
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
    = PressedLogPage (Evergreen.V209.Id.Id Evergreen.V209.Pagination.PageId)
    | PressedCopyLogLink (Evergreen.V209.Id.Id Evergreen.V209.Pagination.ItemId)
    | PressedCollapseSection Evergreen.V209.User.AdminUiSection
    | DoublePressedCollapseSection Evergreen.V209.User.AdminUiSection
    | PressedExpandSection Evergreen.V209.User.AdminUiSection
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
    | PressedResetUser (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
    | ScrolledToSection
    | UserTableMsg Evergreen.V209.Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
    | PressedExpandDiscordGuild (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
    | PressedExpandGuild (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    | PressedDeleteGuild (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    | SlackClientSecretEditableMsg (Evergreen.V209.Editable.Msg (Maybe Evergreen.V209.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V209.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V209.Editable.Msg Evergreen.V209.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V209.Editable.Msg (Maybe String))
    | PostmarkKeyEditableMsg (Evergreen.V209.Editable.Msg Evergreen.V209.Postmark.ApiKey)
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected Effect.File.File
    | GotImportBackendFileContent Bytes.Bytes
    | PressedHideLog (Evergreen.V209.Id.Id Evergreen.V209.Pagination.ItemId)
    | PressedUnhideLog (Evergreen.V209.Id.Id Evergreen.V209.Pagination.ItemId)
    | PressedShowHiddenLogs Bool
    | PressedDisconnectClient Evergreen.V209.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | PressedRegenerateServerSecret


type ToBackend
    = ExportBackendRequest ExportSubset
    | ImportBackendRequest Bytes.Bytes
