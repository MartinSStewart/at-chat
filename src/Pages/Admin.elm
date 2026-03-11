module Pages.Admin exposing
    ( AdminChange(..)
    , EditedBackendUser
    , EditingCell
    , ImportBackendStatus(..)
    , InitAdminData
    , Model
    , Msg(..)
    , OutMsg(..)
    , ToBackend(..)
    , ToFrontend(..)
    , UserColumn(..)
    , UserTable
    , UserTableId(..)
    , UsersChangeError(..)
    , applyChangesToBackendUsers
    , initForAdmin
    , initForUser
    , logSectionId
    , pendingChangesText
    , update
    , updateAdmin
    , updateFromBackend
    , view
    )

import Array exposing (Array)
import Array.Extra
import Bytes exposing (Bytes)
import ChannelName
import Discord
import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Navigation as BrowserNavigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File as File exposing (File)
import Effect.File.Download
import Effect.File.Select
import Effect.Lamdera as Lamdera
import Effect.Task as Task
import Effect.Time as Time
import EmailAddress
import Env
import GuildName
import Html.Attributes
import Html.Events
import Icons
import Id exposing (GuildId, Id, UserId)
import Json.Decode
import LocalState exposing (AdminData, AdminData_DiscordChannel, AdminData_DiscordDmChannel, AdminData_DiscordGuild, AdminData_Guild, AdminStatus(..), DiscordUserData_ForAdmin(..), LoadingDiscordChannel(..), LoadingDiscordChannelStep(..), LocalState, LogWithTime, PrivateVapidKey(..))
import Log
import Message exposing (Message)
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import Pagination exposing (ItemId, PageId, Pagination)
import PersonName
import Ports
import Route
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Set exposing (Set)
import Slack
import Table
import Toop exposing (T2(..), T3(..))
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Lazy
import Ui.Shadow
import Ui.Table
import User exposing (AdminUiSection(..), BackendUser)
import UserSession exposing (ToBeFilledInByBackend(..))


type Msg
    = PressedLogPage (Id PageId)
    | PressedCopyLogLink (Id ItemId)
    | PressedCollapseSection AdminUiSection
    | DoublePressedCollapseSection AdminUiSection
    | PressedExpandSection AdminUiSection
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
    | PressedResetUser (Id UserId)
    | ScrolledToSection
    | UserTableMsg Table.Msg
    | ToggledEmailNotifications Bool
    | ToggledSignupsEnabled Bool
    | ToggleIsAdmin UserTableId Bool
    | PressedDeleteDiscordDmChannel (Discord.Id Discord.PrivateChannelId)
    | PressedDeleteDiscordGuild (Discord.Id Discord.GuildId)
    | PressedExpandDiscordGuild (Discord.Id Discord.GuildId)
    | PressedExpandGuild (Id GuildId)
    | PressedDeleteGuild (Id GuildId)
    | SlackClientSecretEditableMsg (Editable.Msg (Maybe Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Editable.Msg PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Editable.Msg (Maybe String))
    | PressedHomepageLink
    | PressedReloadDiscordChannel (Discord.Id Discord.UserId) (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId)
    | PressedReloadDiscordDmChannel (Discord.Id Discord.UserId) (Discord.Id Discord.PrivateChannelId)
    | PressedCopyText String
    | TypedInReadOnlyTextInput
    | PressedExportBackend
    | PressedExportSubsetBackend
    | PressedImportBackend
    | ImportBackendFileSelected File
    | GotImportBackendFileContent Bytes
    | PressedHideLog (Id ItemId)
    | PressedUnhideLog (Id ItemId)
    | PressedShowHiddenLogs Bool


type ToBackend
    = ExportBackendRequest
    | ExportSubsetBackendRequest
    | ImportBackendRequest Bytes
    | GetDiscordUsersRequest


type ToFrontend
    = ExportBackendResponse Bytes
    | ExportSubsetBackendResponse Bytes
    | ImportBackendResponse (Result () ())
    | GetDiscordUsersResponse (SeqDict (Discord.Id Discord.UserId) DiscordUserData_ForAdmin)


type alias Model =
    { highlightLog : Maybe (Id ItemId)
    , copiedLogLink : Maybe (Id ItemId)
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , slackClientSecret : Editable.Model
    , publicVapidKey : Editable.Model
    , privateVapidKey : Editable.Model
    , openRouterKey : Editable.Model
    , importBackendStatus : ImportBackendStatus
    , showHiddenLogs : Bool
    }


type ImportBackendStatus
    = NotImportingBackend
    | ImportBackendFailed
    | ImportingBackend
    | ImportedBackendSuccessfully


type UserTableId
    = ExistingUserId (Id UserId)
    | NewUserId Int


type alias UserTable =
    { table : Table.Model
    , changedUsers : SeqDict (Id UserId) EditedBackendUser
    , editingCell : Maybe EditingCell
    , newUsers : Array EditedBackendUser
    , deletedUsers : SeqSet (Id UserId)
    }


type alias EditingCell =
    { userId : UserTableId, column : UserColumn, text : String }


type alias InitAdminData =
    { users : NonemptyDict (Id UserId) BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict (Id UserId) Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Slack.ClientSecret
    , openRouterKey : Maybe String
    , discordDmChannels : SeqDict (Discord.Id Discord.PrivateChannelId) AdminData_DiscordDmChannel
    , discordUsers : Maybe (SeqDict (Discord.Id Discord.UserId) DiscordUserData_ForAdmin)
    , discordGuilds : SeqDict (Discord.Id Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict (Id GuildId) AdminData_Guild
    , loadingDiscordChannels : SeqDict (Discord.Id Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , logs : Pagination LogWithTime
    }


type AdminChange
    = ChangeUsers
        { time : Time.Posix
        , changedUsers : SeqDict (Id UserId) EditedBackendUser
        , newUsers : Array EditedBackendUser
        , deletedUsers : SeqSet (Id UserId)
        }
    | ExpandSection AdminUiSection
    | CollapseSection AdminUiSection
    | LogPageChanged (Id PageId) (ToBeFilledInByBackend (Array LogWithTime))
    | SetEmailNotificationsEnabled Bool
    | SetSignupsEnabled Bool
    | SetPrivateVapidKey PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)
    | DeleteDiscordDmChannel (Discord.Id Discord.PrivateChannelId)
    | DeleteDiscordGuild (Discord.Id Discord.GuildId)
    | DeleteGuild (Id GuildId)
    | StartReloadingDiscordGuildChannel Time.Posix (Discord.Id Discord.UserId) (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId)
    | StartReloadingDiscordDmChannel Time.Posix (Discord.Id Discord.UserId) (Discord.Id Discord.PrivateChannelId)
    | ExpandGuild (Id GuildId)
    | CollapseGuild (Id GuildId)
    | ExpandDiscordGuild (Discord.Id Discord.GuildId)
    | CollapseDiscordGuild (Discord.Id Discord.GuildId)
    | HideLog (Id ItemId)
    | UnhideLog (Id ItemId)


type alias EditedBackendUser =
    { name : String
    , email : String
    , isAdmin : Bool
    , createdAt : Time.Posix
    }


type UsersChangeError
    = EmailAddressesAreNotUnique
    | InvalidChangesToUser
    | ChangesAppliedToNonExistentUser (Id UserId)
    | CantRemoveAdminRoleFromYourself
    | CantDeleteYourself
    | InvalidNewUser


initForUser : Model
initForUser =
    { highlightLog = Nothing
    , copiedLogLink = Nothing
    , userTable =
        { table = Table.init 1
        , changedUsers = SeqDict.empty
        , editingCell = Nothing
        , newUsers = Array.empty
        , deletedUsers = SeqSet.empty
        }
    , submitError = Nothing
    , slackClientSecret = Editable.init
    , publicVapidKey = Editable.init
    , privateVapidKey = Editable.init
    , openRouterKey = Editable.init
    , importBackendStatus = NotImportingBackend
    , showHiddenLogs = False
    }


initForAdmin : { highlightLog : Maybe (Id ItemId) } -> Model
initForAdmin { highlightLog } =
    { highlightLog = highlightLog
    , copiedLogLink = Nothing
    , userTable =
        { table = Table.init 1
        , changedUsers = SeqDict.empty
        , editingCell = Nothing
        , newUsers = Array.empty
        , deletedUsers = SeqSet.empty
        }
    , submitError = Nothing
    , slackClientSecret = Editable.init
    , publicVapidKey = Editable.init
    , privateVapidKey = Editable.init
    , openRouterKey = Editable.init
    , importBackendStatus = NotImportingBackend
    , showHiddenLogs = False
    }


updateAdmin : Id UserId -> AdminChange -> AdminData -> LocalState -> LocalState
updateAdmin changedBy change adminData local =
    case change of
        ChangeUsers changes ->
            { local
                | adminData =
                    IsAdmin
                        (case applyChangesToBackendUsers changedBy changes adminData.users of
                            Ok newUsers ->
                                { adminData | users = newUsers }

                            Err _ ->
                                adminData
                        )
            }

        ExpandSection section2 ->
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | users =
                                NonemptyDict.updateIfExists
                                    changedBy
                                    (\user -> { user | expandedSections = SeqSet.insert section2 user.expandedSections })
                                    adminData.users
                        }
            }

        CollapseSection section2 ->
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | users =
                                NonemptyDict.updateIfExists
                                    changedBy
                                    (\user -> { user | expandedSections = SeqSet.remove section2 user.expandedSections })
                                    adminData.users
                        }
            }

        LogPageChanged pageIndex filledInByBackend ->
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | users =
                                NonemptyDict.updateIfExists
                                    changedBy
                                    (\user -> { user | lastLogPageViewed = pageIndex })
                                    adminData.users
                            , logs = Pagination.setPage pageIndex filledInByBackend adminData.logs
                        }
            }

        SetEmailNotificationsEnabled isEnabled ->
            { local | adminData = IsAdmin { adminData | emailNotificationsEnabled = isEnabled } }

        SetSignupsEnabled isEnabled ->
            { local | adminData = IsAdmin { adminData | signupsEnabled = isEnabled } }

        SetPrivateVapidKey privateVapidKey ->
            { local | adminData = IsAdmin { adminData | privateVapidKey = privateVapidKey } }

        SetPublicVapidKey publicVapidKey ->
            { local | publicVapidKey = publicVapidKey }

        SetSlackClientSecret clientSecret ->
            { local | adminData = IsAdmin { adminData | slackClientSecret = clientSecret } }

        SetOpenRouterKey openRouterKey ->
            { local | adminData = IsAdmin { adminData | openRouterKey = openRouterKey } }

        DeleteDiscordDmChannel channelId ->
            { local | adminData = IsAdmin { adminData | discordDmChannels = SeqDict.remove channelId adminData.discordDmChannels } }

        DeleteDiscordGuild guildId ->
            { local | adminData = IsAdmin { adminData | discordGuilds = SeqDict.remove guildId adminData.discordGuilds } }

        DeleteGuild guildId ->
            { local | adminData = IsAdmin { adminData | guilds = SeqDict.remove guildId adminData.guilds } }

        StartReloadingDiscordGuildChannel time userId guildId channelId ->
            if LocalState.userIsLoadingDiscordChannel userId adminData.loadingDiscordChannels then
                local

            else
                { local
                    | adminData =
                        IsAdmin
                            { adminData
                                | loadingDiscordChannels =
                                    SeqDict.insert
                                        userId
                                        (LoadingDiscordGuildChannel
                                            time
                                            guildId
                                            channelId
                                            LoadingDiscordChannelMessages
                                        )
                                        adminData.loadingDiscordChannels
                            }
                }

        StartReloadingDiscordDmChannel time userId channelId ->
            if LocalState.userIsLoadingDiscordChannel userId adminData.loadingDiscordChannels then
                local

            else
                { local
                    | adminData =
                        IsAdmin
                            { adminData
                                | loadingDiscordChannels =
                                    SeqDict.insert
                                        userId
                                        (LoadingDiscordDmChannel time channelId LoadingDiscordChannelMessages)
                                        adminData.loadingDiscordChannels
                            }
                }

        ExpandGuild guildId ->
            let
                localUser =
                    local.localUser
            in
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | users = NonemptyDict.updateIfExists changedBy (expandGuild guildId) adminData.users
                        }
                , localUser = { localUser | user = expandGuild guildId localUser.user }
            }

        CollapseGuild guildId ->
            let
                localUser =
                    local.localUser
            in
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | users = NonemptyDict.updateIfExists changedBy (collapseGuild guildId) adminData.users
                        }
                , localUser = { localUser | user = collapseGuild guildId localUser.user }
            }

        ExpandDiscordGuild guildId ->
            let
                localUser =
                    local.localUser
            in
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | users = NonemptyDict.updateIfExists changedBy (expandDiscordGuild guildId) adminData.users
                        }
                , localUser = { localUser | user = expandDiscordGuild guildId localUser.user }
            }

        CollapseDiscordGuild guildId ->
            let
                localUser =
                    local.localUser
            in
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | users =
                                NonemptyDict.updateIfExists changedBy (collapseDiscordGuild guildId) adminData.users
                        }
                , localUser = { localUser | user = collapseDiscordGuild guildId localUser.user }
            }

        HideLog pageIndex ->
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | logs =
                                Pagination.updateItem pageIndex (\log -> { log | isHidden = True }) adminData.logs
                        }
            }

        UnhideLog pageIndex ->
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | logs =
                                Pagination.updateItem pageIndex (\log -> { log | isHidden = False }) adminData.logs
                        }
            }


expandGuild : Id GuildId -> BackendUser -> BackendUser
expandGuild guildId user =
    { user | expandedGuilds = SeqSet.insert guildId user.expandedGuilds }


collapseGuild : Id GuildId -> BackendUser -> BackendUser
collapseGuild guildId user =
    { user | expandedGuilds = SeqSet.remove guildId user.expandedGuilds }


expandDiscordGuild : Discord.Id Discord.GuildId -> BackendUser -> BackendUser
expandDiscordGuild guildId user =
    { user | expandedDiscordGuilds = SeqSet.insert guildId user.expandedDiscordGuilds }


collapseDiscordGuild : Discord.Id Discord.GuildId -> BackendUser -> BackendUser
collapseDiscordGuild guildId user =
    { user | expandedDiscordGuilds = SeqSet.remove guildId user.expandedDiscordGuilds }


type OutMsg
    = AdminChange AdminChange
    | GoToHomepage
    | NoOutMsg
    | CopyToClipboard String


update :
    BrowserNavigation.Key
    -> Time.Posix
    -> AdminData
    -> LocalState
    -> Msg
    -> Model
    -> ( Model, Command FrontendOnly ToBackend Msg, OutMsg )
update navigationKey time adminData localState msg model =
    case msg of
        PressedLogPage index ->
            ( model, Command.none, LogPageChanged index EmptyPlaceholder |> AdminChange )

        PressedCopyLogLink logIndex ->
            let
                route : String
                route =
                    Env.domain ++ Route.encode (Route.AdminRoute { highlightLog = Just logIndex })
            in
            ( { model | copiedLogLink = Just logIndex }
            , Command.batch
                [ Ports.copyToClipboard route
                , BrowserNavigation.replaceUrl navigationKey route
                ]
            , NoOutMsg
            )

        PressedHideLog logIndex ->
            ( model, Command.none, HideLog logIndex |> AdminChange )

        PressedUnhideLog logIndex ->
            ( model, Command.none, UnhideLog logIndex |> AdminChange )

        PressedShowHiddenLogs show ->
            ( { model | showHiddenLogs = show }, Command.none, NoOutMsg )

        PressedCollapseSection section2 ->
            ( model, Command.none, CollapseSection section2 |> AdminChange )

        PressedExpandSection section2 ->
            ( model
            , case section2 of
                DiscordUsersSection ->
                    if adminData.discordUsers == Nothing then
                        Lamdera.sendToBackend GetDiscordUsersRequest

                    else
                        Command.none

                _ ->
                    Command.none
            , ExpandSection section2 |> AdminChange
            )

        PressedEditCell userTableId column ->
            updateUserTable
                (\userTable ->
                    let
                        userTable2 : UserTable
                        userTable2 =
                            case userTable.editingCell of
                                Just editingCell ->
                                    applyEditCell userTable editingCell adminData

                                Nothing ->
                                    userTable

                        helper : EditedBackendUser -> ( UserTable, Command FrontendOnly ToBackend Msg, OutMsg )
                        helper change =
                            ( { userTable2
                                | editingCell =
                                    { userId = userTableId
                                    , column = column
                                    , text = localChangeToText column change
                                    }
                                        |> Just
                              }
                            , Dom.focus editCellTextInputId |> Task.attempt (\_ -> FocusedOnEditCell)
                            , NoOutMsg
                            )
                    in
                    case userTableId of
                        ExistingUserId userId ->
                            case SeqDict.get userId userTable2.changedUsers of
                                Just change ->
                                    helper change

                                Nothing ->
                                    case NonemptyDict.get userId adminData.users of
                                        Just user ->
                                            userToEditUser user |> helper

                                        Nothing ->
                                            ( userTable2, Command.none, NoOutMsg )

                        NewUserId index ->
                            case Array.get index userTable2.newUsers of
                                Just change ->
                                    helper change

                                Nothing ->
                                    ( userTable2, Command.none, NoOutMsg )
                )
                model

        TypedEditCell text ->
            updateUserTable
                (\userTableState ->
                    ( case userTableState.editingCell of
                        Just editingCell ->
                            { userTableState | editingCell = Just { editingCell | text = text } }

                        Nothing ->
                            userTableState
                    , Command.none
                    , NoOutMsg
                    )
                )
                model

        EditCellLostFocus userId column ->
            updateUserTable
                (\userTable ->
                    ( case userTable.editingCell of
                        Just editingCell ->
                            if editingCell.userId == userId && editingCell.column == column then
                                applyEditCell userTable editingCell adminData

                            else
                                userTable

                        Nothing ->
                            userTable
                    , Command.none
                    , NoOutMsg
                    )
                )
                model

        FocusedOnEditCell ->
            ( model, Ports.textInputSelectAll editCellTextInputId, NoOutMsg )

        EnterKeyInEditCell userId column ->
            updateUserTable
                (\userTable ->
                    ( case userTable.editingCell of
                        Just editingCell ->
                            if editingCell.userId == userId && editingCell.column == column then
                                applyEditCell userTable editingCell adminData

                            else
                                userTable

                        Nothing ->
                            userTable
                    , Command.none
                    , NoOutMsg
                    )
                )
                model

        PressedSaveUserChanges ->
            let
                userTable2 : UserTable
                userTable2 =
                    case model.userTable.editingCell of
                        Just editingCell ->
                            applyEditCell model.userTable editingCell adminData

                        Nothing ->
                            model.userTable

                result : Result UsersChangeError (NonemptyDict (Id UserId) BackendUser)
                result =
                    applyChangesToBackendUsers
                        localState.localUser.session.userId
                        { time = time
                        , newUsers = userTable2.newUsers
                        , deletedUsers = userTable2.deletedUsers
                        , changedUsers = userTable2.changedUsers
                        }
                        adminData.users
            in
            case result of
                Ok _ ->
                    ( { model
                        | submitError = Nothing
                        , userTable =
                            { userTable2
                                | editingCell = Nothing
                                , changedUsers = SeqDict.empty
                                , newUsers = Array.empty
                                , deletedUsers = SeqSet.empty
                            }
                      }
                    , Command.none
                    , ChangeUsers
                        { time = time
                        , changedUsers = userTable2.changedUsers
                        , newUsers = userTable2.newUsers
                        , deletedUsers = userTable2.deletedUsers
                        }
                        |> AdminChange
                    )

                Err error ->
                    ( { model | submitError = Just error }, Command.none, NoOutMsg )

        TabKeyInEditCell shiftKeyHeld ->
            updateUserTable
                (\userTable ->
                    case userTable.editingCell of
                        Just editingCell ->
                            let
                                oldUserTable =
                                    userTable

                                userTable2 : UserTable
                                userTable2 =
                                    applyEditCell userTable editingCell adminData

                                column : UserColumn
                                column =
                                    if shiftKeyHeld then
                                        previousUserColumn editingCell.column

                                    else
                                        nextUserColumn editingCell.column
                            in
                            ( { userTable2
                                | editingCell =
                                    { userId = editingCell.userId
                                    , column = column
                                    , text =
                                        case editingCell.userId of
                                            ExistingUserId userId ->
                                                case NonemptyDict.get userId adminData.users of
                                                    Just user ->
                                                        userToEditUser user
                                                            |> localChangeToText column

                                                    Nothing ->
                                                        ""

                                            NewUserId index ->
                                                case Array.get index oldUserTable.newUsers of
                                                    Just user ->
                                                        localChangeToText column user

                                                    Nothing ->
                                                        ""
                                    }
                                        |> Just
                              }
                            , Dom.focus editCellTextInputId |> Task.attempt (\_ -> FocusedOnEditCell)
                            , NoOutMsg
                            )

                        Nothing ->
                            ( userTable, Command.none, NoOutMsg )
                )
                model

        PressedResetUserChanges ->
            updateUserTable
                (\userTable ->
                    ( { userTable
                        | changedUsers = SeqDict.empty
                        , newUsers = Array.empty
                        , deletedUsers = SeqSet.empty
                      }
                    , Command.none
                    , NoOutMsg
                    )
                )
                model

        EscapeKeyInEditCell ->
            updateUserTable (\userTable -> ( { userTable | editingCell = Nothing }, Command.none, NoOutMsg )) model

        PressedAddUserRow ->
            updateUserTable
                (\userTable ->
                    ( { userTable
                        | newUsers =
                            Array.push
                                { name = ""
                                , email = ""
                                , isAdmin = False
                                , createdAt = time
                                }
                                userTable.newUsers
                      }
                    , Command.none
                    , NoOutMsg
                    )
                )
                model

        PressedDeleteUser userTableId ->
            updateUserTable
                (\userTable ->
                    case userTableId of
                        ExistingUserId userId ->
                            ( { userTable
                                | deletedUsers = SeqSet.insert userId userTable.deletedUsers
                                , changedUsers = SeqDict.remove userId userTable.changedUsers
                              }
                            , Command.none
                            , NoOutMsg
                            )

                        NewUserId index ->
                            ( { userTable | newUsers = Array.Extra.removeAt index userTable.newUsers }
                            , Command.none
                            , NoOutMsg
                            )
                )
                model

        PressedResetUser userId ->
            updateUserTable
                (\userTable ->
                    ( { userTable
                        | changedUsers = SeqDict.remove userId userTable.changedUsers
                        , deletedUsers = SeqSet.remove userId userTable.deletedUsers
                      }
                    , Command.none
                    , NoOutMsg
                    )
                )
                model

        DoublePressedCollapseSection section2 ->
            ( model
            , Dom.getElement (collapseSectionButtonId section2)
                |> Task.andThen (\{ element } -> Dom.setViewport 0 (element.y - 8))
                |> Task.attempt (\_ -> ScrolledToSection)
            , NoOutMsg
            )

        ScrolledToSection ->
            ( model, Command.none, NoOutMsg )

        UserTableMsg tableMsg ->
            updateUserTable
                (\userTable -> ( { userTable | table = Table.update tableMsg userTable.table }, Command.none, NoOutMsg ))
                model

        ToggledEmailNotifications isChecked ->
            ( model, Command.none, AdminChange (SetEmailNotificationsEnabled isChecked) )

        ToggledSignupsEnabled isChecked ->
            ( model, Command.none, AdminChange (SetSignupsEnabled isChecked) )

        ToggleIsAdmin userTableId isAdmin ->
            updateUserTable
                (\userTableState ->
                    ( handleTogglingAdmin userTableId userTableState isAdmin adminData
                    , Command.none
                    , NoOutMsg
                    )
                )
                model

        PressedDeleteDiscordDmChannel channelId ->
            ( model, Command.none, AdminChange (DeleteDiscordDmChannel channelId) )

        PressedDeleteDiscordGuild guildId ->
            ( model, Command.none, AdminChange (DeleteDiscordGuild guildId) )

        PressedExpandDiscordGuild guildId ->
            let
                user : User.FrontendCurrentUser
                user =
                    localState.localUser.user
            in
            ( model
            , Command.none
            , AdminChange
                (if SeqSet.member guildId user.expandedDiscordGuilds then
                    CollapseDiscordGuild guildId

                 else
                    ExpandDiscordGuild guildId
                )
            )

        PressedExpandGuild guildId ->
            let
                user =
                    localState.localUser.user
            in
            ( model
            , Command.none
            , AdminChange
                (if SeqSet.member guildId user.expandedGuilds then
                    CollapseGuild guildId

                 else
                    ExpandGuild guildId
                )
            )

        PressedDeleteGuild guildId ->
            ( model, Command.none, AdminChange (DeleteGuild guildId) )

        SlackClientSecretEditableMsg editableMsg ->
            case editableMsg of
                Editable.Edit editable ->
                    ( { model | slackClientSecret = editable }, Command.none, NoOutMsg )

                Editable.PressedAcceptEdit value ->
                    ( model, Command.none, SetSlackClientSecret value |> AdminChange )

        PublicVapidKeyEditableMsg editableMsg ->
            case editableMsg of
                Editable.Edit editable ->
                    ( { model | publicVapidKey = editable }, Command.none, NoOutMsg )

                Editable.PressedAcceptEdit value ->
                    ( model, Command.none, SetPublicVapidKey value |> AdminChange )

        PrivateVapidKeyEditableMsg editableMsg ->
            case editableMsg of
                Editable.Edit editable ->
                    ( { model | privateVapidKey = editable }, Command.none, NoOutMsg )

                Editable.PressedAcceptEdit value ->
                    ( model, Command.none, SetPrivateVapidKey value |> AdminChange )

        OpenRouterKeyEditableMsg editableMsg ->
            case editableMsg of
                Editable.Edit editable ->
                    ( { model | openRouterKey = editable }, Command.none, NoOutMsg )

                Editable.PressedAcceptEdit value ->
                    ( model, Command.none, SetOpenRouterKey value |> AdminChange )

        PressedHomepageLink ->
            ( model, Command.none, GoToHomepage )

        PressedReloadDiscordChannel currentUserId guildId channelId ->
            ( model, Command.none, StartReloadingDiscordGuildChannel time currentUserId guildId channelId |> AdminChange )

        PressedReloadDiscordDmChannel currentUserId channelId ->
            ( model, Command.none, StartReloadingDiscordDmChannel time currentUserId channelId |> AdminChange )

        PressedCopyText string ->
            ( model, Command.none, CopyToClipboard string )

        TypedInReadOnlyTextInput ->
            ( model, Command.none, NoOutMsg )

        PressedExportBackend ->
            ( model, Lamdera.sendToBackend ExportBackendRequest, NoOutMsg )

        PressedExportSubsetBackend ->
            ( model, Lamdera.sendToBackend ExportSubsetBackendRequest, NoOutMsg )

        PressedImportBackend ->
            case model.importBackendStatus of
                ImportingBackend ->
                    ( model, Command.none, NoOutMsg )

                _ ->
                    ( model, Effect.File.Select.file [] ImportBackendFileSelected, NoOutMsg )

        ImportBackendFileSelected file ->
            ( model
            , Task.perform GotImportBackendFileContent (File.toBytes file)
            , NoOutMsg
            )

        GotImportBackendFileContent content ->
            ( { model | importBackendStatus = ImportingBackend }
            , Lamdera.sendToBackend (ImportBackendRequest content)
            , NoOutMsg
            )


handleTogglingAdmin : UserTableId -> UserTable -> Bool -> AdminData -> UserTable
handleTogglingAdmin userTableId userTableState isAdmin adminData =
    case userTableId of
        ExistingUserId userId ->
            { userTableState
                | changedUsers =
                    SeqDict.update
                        userId
                        (\maybe ->
                            case maybe of
                                Just change ->
                                    Just { change | isAdmin = isAdmin }

                                Nothing ->
                                    case NonemptyDict.get userId adminData.users of
                                        Just user ->
                                            let
                                                change : EditedBackendUser
                                                change =
                                                    userToEditUser user
                                            in
                                            Just { change | isAdmin = isAdmin }

                                        Nothing ->
                                            Nothing
                        )
                        userTableState.changedUsers
            }

        NewUserId index ->
            { userTableState
                | newUsers =
                    Array.Extra.update
                        index
                        (\newUser -> { newUser | isAdmin = isAdmin })
                        userTableState.newUsers
            }


applyEditCell : UserTable -> EditingCell -> AdminData -> UserTable
applyEditCell userTable editingCell adminData =
    case editingCell.userId of
        ExistingUserId userId ->
            case NonemptyDict.get userId adminData.users of
                Just user ->
                    { userTable
                        | changedUsers =
                            SeqDict.update
                                userId
                                (\maybeChange ->
                                    let
                                        changeA : EditedBackendUser
                                        changeA =
                                            Maybe.withDefault
                                                (userToEditUser
                                                    user
                                                )
                                                maybeChange

                                        changeB : EditedBackendUser
                                        changeB =
                                            updateEditUserField editingCell.column editingCell.text changeA
                                    in
                                    if maybeChange == Nothing && changeB == changeA then
                                        Nothing

                                    else
                                        Just changeB
                                )
                                userTable.changedUsers
                        , editingCell = Nothing
                        , deletedUsers = SeqSet.remove userId userTable.deletedUsers
                    }

                Nothing ->
                    userTable

        NewUserId index ->
            { userTable
                | newUsers =
                    Array.Extra.update
                        index
                        (updateEditUserField editingCell.column editingCell.text)
                        userTable.newUsers
                , editingCell = Nothing
            }


updateEditUserField : UserColumn -> String -> EditedBackendUser -> EditedBackendUser
updateEditUserField userColumn text change =
    case userColumn of
        NameColumn ->
            { change | name = text }

        EmailAddressColumn ->
            { change | email = text }


nextUserColumn : UserColumn -> UserColumn
nextUserColumn column =
    case column of
        NameColumn ->
            EmailAddressColumn

        EmailAddressColumn ->
            NameColumn


previousUserColumn : UserColumn -> UserColumn
previousUserColumn column =
    case column of
        NameColumn ->
            EmailAddressColumn

        EmailAddressColumn ->
            NameColumn


userToEditUser : BackendUser -> EditedBackendUser
userToEditUser user =
    { name = PersonName.toString user.name
    , email = EmailAddress.toString user.email
    , isAdmin = user.isAdmin
    , createdAt = user.createdAt
    }


updateUserTable :
    (UserTable -> ( UserTable, Command FrontendOnly ToBackend Msg, OutMsg ))
    -> Model
    -> ( Model, Command FrontendOnly ToBackend Msg, OutMsg )
updateUserTable updateFunc model =
    let
        ( userTable, cmd, localChange ) =
            updateFunc model.userTable
    in
    ( { model | userTable = userTable }, cmd, localChange )


updateFromBackend : ToFrontend -> Model -> ( Model, Command FrontendOnly ToBackend Msg )
updateFromBackend toFrontend model =
    case toFrontend of
        ExportBackendResponse bytes ->
            ( model, Effect.File.Download.bytes "backend-export.bin" "application/octet-stream" bytes )

        ExportSubsetBackendResponse bytes ->
            ( model, Effect.File.Download.bytes "backend-export-subset.bin" "application/octet-stream" bytes )

        ImportBackendResponse result ->
            case result of
                Ok () ->
                    ( { model | importBackendStatus = ImportedBackendSuccessfully }, Command.none )

                Err () ->
                    ( { model | importBackendStatus = ImportBackendFailed }, Command.none )

        GetDiscordUsersResponse _ ->
            ( model, Command.none )


logSectionId : HtmlId
logSectionId =
    Dom.id "Pages.Admin_logSection"


deleteUserButtonId : UserTableId -> HtmlId
deleteUserButtonId userTableId =
    "Admin_deleteUserButton_" ++ userTableIdToDomId userTableId |> Dom.id


deleteGuildButtonId : Id GuildId -> HtmlId
deleteGuildButtonId guildId =
    "Admin_deleteGuildButton_" ++ Id.toString guildId |> Dom.id


deleteDiscordGuildButtonId : Discord.Id Discord.GuildId -> HtmlId
deleteDiscordGuildButtonId guildId =
    "Admin_deleteDiscordGuildButton_" ++ Discord.idToString guildId |> Dom.id


deleteDiscordDmChannelButtonId : Discord.Id Discord.PrivateChannelId -> HtmlId
deleteDiscordDmChannelButtonId channelId =
    "Admin_deleteDiscordDmChannelButton_" ++ Discord.idToString channelId |> Dom.id


pendingChangesText : AdminChange -> String
pendingChangesText change =
    case change of
        ChangeUsers _ ->
            "Changed users via admin page"

        ExpandSection _ ->
            "Expanded section in admin page"

        CollapseSection _ ->
            "Collapsed section in admin page"

        LogPageChanged pageId _ ->
            "Switched to log page " ++ Id.toString pageId

        SetEmailNotificationsEnabled isEnabled ->
            if isEnabled then
                "Enabled email notifications"

            else
                "Disabled email notifications"

        SetSignupsEnabled isEnabled ->
            if isEnabled then
                "Enabled sign ups"

            else
                "Disabled sign ups"

        SetPrivateVapidKey _ ->
            "Set private vapid key"

        SetPublicVapidKey _ ->
            "Set public vapid key"

        SetSlackClientSecret _ ->
            "Set slack client secret"

        SetOpenRouterKey _ ->
            "Set OpenRouter key"

        DeleteDiscordDmChannel _ ->
            "Deleted Discord DM channel"

        DeleteDiscordGuild _ ->
            "Deleted Discord guild"

        DeleteGuild _ ->
            "Deleted guild"

        StartReloadingDiscordGuildChannel _ _ _ _ ->
            "Reset Discord channel"

        StartReloadingDiscordDmChannel _ _ _ ->
            "Reset Discord DM channel"

        ExpandGuild _ ->
            "Expanded guild in admin page"

        CollapseGuild _ ->
            "Collapsed guild in admin page"

        ExpandDiscordGuild _ ->
            "Expanded Discord guild in admin page"

        CollapseDiscordGuild _ ->
            "Collapsed Discord guild in admin page"

        HideLog logIndex ->
            "Hid log " ++ Id.toString logIndex

        UnhideLog logIndex ->
            "Unhid log " ++ Id.toString logIndex


view : Bool -> Maybe Int -> LocalState -> AdminData -> BackendUser -> Model -> Element Msg
view isMobile2 version local adminData user model =
    Ui.el
        [ Ui.scrollable
        , Ui.background MyUi.background1
        , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 " ++ MyUi.insetBottom ++ " 0")
        ]
        (MyUi.column
            [ Ui.paddingWith { left = 8, right = 8, top = 16, bottom = 64 } ]
            [ Ui.row
                []
                [ MyUi.simpleButton (Dom.id "admin_goToHomepage") PressedHomepageLink (Ui.text "Go to homepage")
                , Ui.el
                    [ Ui.alignRight, Ui.width Ui.shrink ]
                    (case version of
                        Just version2 ->
                            Ui.text ("Version " ++ String.fromInt version2)

                        Nothing ->
                            Ui.text "Version unknown"
                    )
                ]
            , userSection user adminData model
            , guildsSection user adminData
            , discordGuildsSection user adminData
            , discordDmChannelsSection user adminData
            , discordUsersSection user adminData
            , logSection isMobile2 local.localUser.timezone user adminData model
            , apiKeysSection local user adminData model
            , exportSection user model
            ]
        )


exportSection : BackendUser -> Model -> Element Msg
exportSection user model =
    section
        8
        user.expandedSections
        ExportSection
        [ MyUi.simpleButton
            (Dom.id "admin_exportBackendButton")
            PressedExportBackend
            (Ui.text "Export backend")
        , MyUi.simpleButton
            (Dom.id "admin_exportSubsetBackendButton")
            PressedExportSubsetBackend
            (Ui.text "Export subset")
        , Ui.row
            [ Ui.spacing 8 ]
            [ MyUi.simpleButton
                (Dom.id "admin_importBackendButton")
                PressedImportBackend
                (Ui.text "Import backend")
            , case model.importBackendStatus of
                NotImportingBackend ->
                    Ui.none

                ImportBackendFailed ->
                    Ui.text "Failed to import backend"

                ImportingBackend ->
                    Ui.text "Importing..."

                ImportedBackendSuccessfully ->
                    Ui.text "Imported!"
            ]
        ]


apiKeysSection : LocalState -> BackendUser -> AdminData -> Model -> Element Msg
apiKeysSection local user adminData2 model =
    section
        8
        user.expandedSections
        ApiKeysSection
        [ Editable.view
            (Dom.id "userOptions_slackClientSecret")
            True
            "Slack client secret"
            (\text ->
                let
                    text2 =
                        String.trim text
                in
                if text2 == "" then
                    Ok Nothing

                else
                    Just (Slack.ClientSecret text2) |> Ok
            )
            SlackClientSecretEditableMsg
            (case adminData2.slackClientSecret of
                Just (Slack.ClientSecret a) ->
                    a

                Nothing ->
                    ""
            )
            model.slackClientSecret
        , Editable.view
            (Dom.id "userOptions_publicVapidKey")
            True
            "Public VAPID key"
            (\text -> String.trim text |> Ok)
            PublicVapidKeyEditableMsg
            local.publicVapidKey
            model.publicVapidKey
        , Editable.view
            (Dom.id "userOptions_privateVapidKey")
            True
            "Private VAPID key"
            (\text -> String.trim text |> PrivateVapidKey |> Ok)
            PrivateVapidKeyEditableMsg
            (adminData2.privateVapidKey |> (\(PrivateVapidKey a) -> a))
            model.privateVapidKey
        , Editable.view
            (Dom.id "userOptions_openRouterKey")
            True
            "OpenRouter API key"
            (\text ->
                let
                    text2 =
                        String.trim text
                in
                if text2 == "" then
                    Ok Nothing

                else
                    Just text2 |> Ok
            )
            OpenRouterKeyEditableMsg
            (case adminData2.openRouterKey of
                Just key ->
                    key

                Nothing ->
                    ""
            )
            model.openRouterKey
        ]


userSection : BackendUser -> AdminData -> Model -> Element Msg
userSection user adminData model =
    let
        emailNotificationsLabel : { element : Element msg, id : Ui.Input.Label }
        emailNotificationsLabel =
            MyUi.label
                (Dom.id "emailNotificationsId")
                []
                (Ui.text "Email notifications enabled (does not affect login emails)")

        signupsEnabledLabel : { element : Element msg, id : Ui.Input.Label }
        signupsEnabledLabel =
            MyUi.label
                (Dom.id "signupsEnabledId")
                []
                (Ui.text "New sign ups enabled")
    in
    section
        8
        user.expandedSections
        UsersSection
        [ Ui.row
            [ Ui.spacing 4 ]
            [ Ui.Input.checkbox
                []
                { onChange = ToggledEmailNotifications
                , checked = adminData.emailNotificationsEnabled
                , icon = Nothing
                , label = emailNotificationsLabel.id
                }
            , emailNotificationsLabel.element
            ]
        , Ui.row
            [ Ui.spacing 4 ]
            [ Ui.Input.checkbox
                []
                { onChange = ToggledSignupsEnabled
                , checked = adminData.signupsEnabled
                , icon = Nothing
                , label = signupsEnabledLabel.id
                }
            , signupsEnabledLabel.element
            ]
        , Ui.Lazy.lazy3 userTableView model.userTable adminData.users adminData.twoFactorAuthentication
        , Ui.row
            [ Ui.spacing 16 ]
            (MyUi.simpleButton
                addUserRowButtonId
                PressedAddUserRow
                (Ui.text "Add new user")
                :: (if
                        SeqDict.isEmpty model.userTable.changedUsers
                            && Array.isEmpty model.userTable.newUsers
                            && SeqSet.isEmpty model.userTable.deletedUsers
                    then
                        []

                    else
                        [ MyUi.simpleButton
                            (Dom.id "Admin_resetUserChanges")
                            PressedResetUserChanges
                            (Ui.text "Reset")
                        , MyUi.simpleButton saveUserChangesButtonId PressedSaveUserChanges (Ui.text "Save changes")
                        , case model.submitError of
                            Just error ->
                                (case error of
                                    EmailAddressesAreNotUnique ->
                                        "Email addresses are not unique"

                                    InvalidChangesToUser ->
                                        "One or more user rows have invalid fields"

                                    ChangesAppliedToNonExistentUser id ->
                                        "User ID " ++ Id.toString id ++ " not found. Try reloading the page."

                                    CantRemoveAdminRoleFromYourself ->
                                        "You can't remove your own admin role"

                                    CantDeleteYourself ->
                                        "You can't delete your own account"

                                    InvalidNewUser ->
                                        "One or more new user rows have invalid fields"
                                )
                                    |> Ui.text
                                    |> Ui.el [ Ui.Font.color MyUi.errorColor ]

                            Nothing ->
                                Ui.none
                        ]
                   )
            )
        ]


guildsSection : BackendUser -> AdminData -> Element Msg
guildsSection user adminData =
    section
        8
        user.expandedSections
        GuildsSection
        [ if SeqDict.isEmpty adminData.guilds then
            Ui.text "No guilds"

          else
            Ui.column
                [ Ui.spacing 4 ]
                (List.map
                    (\( guildId, guild ) ->
                        let
                            isExpanded : Bool
                            isExpanded =
                                SeqSet.member guildId user.expandedGuilds

                            channelCount : Int
                            channelCount =
                                SeqDict.size guild.channels
                        in
                        Ui.column
                            [ Ui.spacing 4 ]
                            [ Ui.row
                                [ Ui.spacing 8, Ui.Font.size 14 ]
                                [ Ui.el
                                    [ Ui.width Ui.shrink, Ui.Input.button (PressedExpandGuild guildId) ]
                                    (if isExpanded then
                                        Icons.collapseContainer

                                     else
                                        Icons.expandContainer
                                    )
                                , Ui.text (Id.toString guildId)
                                , Ui.text (GuildName.toString guild.name)
                                , Ui.row
                                    [ Ui.spacing 8 ]
                                    [ Ui.text "Owner:"
                                    , case NonemptyDict.get guild.owner adminData.users of
                                        Just user2 ->
                                            userLabel user2

                                        Nothing ->
                                            Ui.text (Id.toString guild.owner)
                                    ]
                                , Ui.text ("Channels: " ++ String.fromInt channelCount)
                                , Ui.text ("Members: " ++ String.fromInt guild.memberCount)
                                , MyUi.deleteButton (deleteGuildButtonId guildId) (PressedDeleteGuild guildId)
                                ]
                            , if isExpanded then
                                Ui.column
                                    [ Ui.spacing 2, Ui.paddingWith { left = 32, right = 0, top = 0, bottom = 0 } ]
                                    (List.map
                                        (\( _, channel ) ->
                                            Ui.row
                                                [ Ui.spacing 8, Ui.Font.size 13 ]
                                                [ Ui.text ("#" ++ ChannelName.toString channel.name)
                                                , Ui.text ("Messages: " ++ String.fromInt channel.messageCount)
                                                ]
                                        )
                                        (SeqDict.toList guild.channels)
                                    )

                              else
                                Ui.none
                            ]
                    )
                    (SeqDict.toList adminData.guilds)
                )
        ]


discordGuildsSection : BackendUser -> AdminData -> Element Msg
discordGuildsSection user adminData =
    section
        8
        user.expandedSections
        DiscordGuildsSection
        [ if SeqDict.isEmpty adminData.discordGuilds then
            Ui.text "No Discord guilds"

          else
            Ui.column
                [ Ui.spacing 4 ]
                (List.map
                    (\( guildId, guild ) ->
                        let
                            isExpanded : Bool
                            isExpanded =
                                SeqSet.member guildId user.expandedDiscordGuilds

                            channelCount : Int
                            channelCount =
                                SeqDict.size guild.channels
                        in
                        Ui.column
                            [ Ui.spacing 4 ]
                            [ Ui.row
                                [ Ui.spacing 8, Ui.Font.size 14 ]
                                [ Ui.el
                                    [ Ui.width Ui.shrink, Ui.Input.button (PressedExpandDiscordGuild guildId) ]
                                    (if isExpanded then
                                        Icons.collapseContainer

                                     else
                                        Icons.expandContainer
                                    )
                                , Ui.text (Discord.idToString guildId)
                                , Ui.text (GuildName.toString guild.name)
                                , Ui.row
                                    [ Ui.spacing 8 ]
                                    [ Ui.text "Owner:"
                                    , case Maybe.andThen (SeqDict.get guild.owner) adminData.discordUsers of
                                        Just discordUser ->
                                            discordUserLabel discordUser

                                        Nothing ->
                                            Ui.text (Discord.idToString guild.owner)
                                    ]
                                , Ui.text ("Channels: " ++ String.fromInt channelCount)
                                , Ui.text ("Members: " ++ String.fromInt (SeqDict.size guild.members))
                                , MyUi.deleteButton (deleteDiscordGuildButtonId guildId) (PressedDeleteDiscordGuild guildId)
                                ]
                            , if isExpanded then
                                let
                                    userThatCanReload : Maybe (Discord.Id Discord.UserId)
                                    userThatCanReload =
                                        SeqDict.intersect
                                            (SeqDict.filter
                                                (\_ discordUser ->
                                                    case discordUser of
                                                        FullData_ForAdmin _ ->
                                                            True

                                                        _ ->
                                                            False
                                                )
                                                (Maybe.withDefault SeqDict.empty adminData.discordUsers)
                                            )
                                            (SeqDict.insert guild.owner { joinedAt = Nothing } guild.members)
                                            |> SeqDict.keys
                                            |> List.head
                                in
                                Ui.column
                                    [ Ui.spacing 2, Ui.paddingWith { left = 32, right = 0, top = 0, bottom = 0 } ]
                                    (List.map (discordGuildChannel userThatCanReload guildId adminData) (SeqDict.toList guild.channels))

                              else
                                Ui.none
                            ]
                    )
                    (SeqDict.toList adminData.discordGuilds)
                )
        ]


spinner : Element msg
spinner =
    Ui.el
        [ Ui.width (Ui.px channelRowHeight)
        , Ui.height (Ui.px channelRowHeight)
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        Icons.spinner


loadingChannelView : Maybe (LoadingDiscordChannelStep Int) -> Element msg -> Element msg
loadingChannelView isReloading resetButton2 =
    case isReloading of
        Just LoadingDiscordChannelMessages ->
            Ui.row
                [ Ui.contentCenterY, Ui.spacing 8 ]
                [ spinner, Ui.text "Loading messages" ]

        Just (LoadingDiscordChannelAttachments _ attachmentCount) ->
            Ui.row
                [ Ui.contentCenterY, Ui.spacing 8 ]
                [ spinner, Ui.text ("Loading " ++ String.fromInt attachmentCount ++ " attachments") ]

        _ ->
            resetButton2


loadingChannelErrorView : String -> Maybe (LoadingDiscordChannelStep Int) -> Element Msg
loadingChannelErrorView channelId isReloading =
    case isReloading of
        Just (LoadingDiscordChannelMessagesFailed error) ->
            MyUi.errorBox
                (Dom.id ("Admin_errorBox_" ++ channelId))
                PressedCopyText
                ("Loading messages failed: " ++ Discord.httpErrorToString error)

        _ ->
            Ui.none


discordGuildChannel :
    Maybe (Discord.Id Discord.UserId)
    -> Discord.Id Discord.GuildId
    -> AdminData
    -> ( Discord.Id Discord.ChannelId, AdminData_DiscordChannel )
    -> Element Msg
discordGuildChannel maybeUserId guildId adminData ( channelId, channel ) =
    let
        isReloading : Maybe (LoadingDiscordChannelStep Int)
        isReloading =
            LocalState.isDiscordGuildChannelReloading channelId adminData.loadingDiscordChannels
    in
    Ui.row
        [ Ui.spacing 8, Ui.Font.size 13 ]
        [ loadingChannelView
            isReloading
            (case maybeUserId of
                Just userId ->
                    resetButton
                        (Dom.id ("admin_reloadDiscordChannel_" ++ Discord.idToString channelId))
                        (PressedReloadDiscordChannel userId guildId channelId)

                Nothing ->
                    Ui.none
            )
        , Ui.text ("#" ++ ChannelName.toString channel.name)
        , Ui.text ("Messages: " ++ String.fromInt channel.messageCount)
        , firstMessageView channel
        , Ui.text ("Threads: " ++ String.fromInt channel.threadCount)
        , loadingChannelErrorView (Discord.idToString channelId) isReloading
        ]


firstMessageView : { a | firstMessage : Maybe (Message messageId userId) } -> Element Msg
firstMessageView channel =
    case channel.firstMessage of
        Just firstMessage ->
            let
                firstMessageLabel : { element : Element msg, id : Ui.Input.Label }
                firstMessageLabel =
                    Ui.Input.label "admin_discordGuildChannelFirstMessage" [ Ui.width Ui.shrink ] (Ui.text "First message:")
            in
            Ui.row
                [ Ui.spacing 8 ]
                [ firstMessageLabel.element
                , Ui.Input.text
                    [ Html.Attributes.readonly True |> Ui.htmlAttribute
                    , Ui.paddingXY 4 0
                    , Ui.background MyUi.background2
                    , Ui.height (Ui.px channelRowHeight)
                    ]
                    { text = LocalState.messageToString SeqDict.empty firstMessage
                    , onChange = \_ -> TypedInReadOnlyTextInput
                    , label = firstMessageLabel.id
                    , placeholder = Nothing
                    }
                ]

        Nothing ->
            Ui.none


channelRowHeight : number
channelRowHeight =
    30


discordDmChannelsSection : BackendUser -> AdminData -> Element Msg
discordDmChannelsSection user adminData =
    section
        8
        user.expandedSections
        DiscordDmChannelsSection
        [ if SeqDict.isEmpty adminData.discordDmChannels then
            Ui.text "No Discord DM channels"

          else
            Ui.column
                [ Ui.spacing 4 ]
                (List.map
                    (\( channelId, channel ) ->
                        let
                            isReloading : Maybe (LoadingDiscordChannelStep Int)
                            isReloading =
                                LocalState.isDiscordDmChannelReloading channelId adminData.loadingDiscordChannels

                            userThatCanReload : Maybe (Discord.Id Discord.UserId)
                            userThatCanReload =
                                SeqSet.intersect
                                    (SeqDict.filter
                                        (\_ discordUser ->
                                            case discordUser of
                                                FullData_ForAdmin _ ->
                                                    True

                                                _ ->
                                                    False
                                        )
                                        (Maybe.withDefault SeqDict.empty adminData.discordUsers)
                                        |> SeqDict.keys
                                        |> SeqSet.fromList
                                    )
                                    (NonemptySet.toSeqSet channel.members)
                                    |> SeqSet.toList
                                    |> List.head
                        in
                        Ui.row
                            [ Ui.spacing 8, Ui.Font.size 14 ]
                            [ loadingChannelView
                                isReloading
                                (case userThatCanReload of
                                    Just userId ->
                                        resetButton
                                            (Dom.id ("admin_reloadDiscordDmChannel_" ++ Discord.idToString channelId))
                                            (PressedReloadDiscordDmChannel userId channelId)

                                    Nothing ->
                                        Ui.none
                                )
                            , Ui.text (Discord.idToString channelId)
                            , Ui.row
                                [ Ui.spacing 8 ]
                                [ Ui.text "Members:"
                                , NonemptySet.toList channel.members
                                    |> List.map
                                        (\discordUserId ->
                                            case Maybe.andThen (SeqDict.get discordUserId) adminData.discordUsers of
                                                Just discordUser ->
                                                    discordUserLabel discordUser

                                                Nothing ->
                                                    Ui.text (Discord.idToString discordUserId)
                                        )
                                    |> Ui.row [ Ui.spacing 8, Ui.width Ui.shrink ]
                                ]
                            , Ui.text ("Messages: " ++ String.fromInt channel.messageCount)
                            , firstMessageView channel
                            , loadingChannelErrorView (Discord.idToString channelId) isReloading
                            , MyUi.deleteButton (deleteDiscordDmChannelButtonId channelId) (PressedDeleteDiscordDmChannel channelId)
                            ]
                    )
                    (SeqDict.toList adminData.discordDmChannels)
                )
        ]


discordUsersSection : BackendUser -> AdminData -> Element Msg
discordUsersSection user adminData =
    section
        8
        user.expandedSections
        DiscordUsersSection
        [ case adminData.discordUsers of
            Nothing ->
                Ui.text "Loading..."

            Just discordUsers ->
                if SeqDict.isEmpty discordUsers then
                    Ui.text "No Discord user"

                else
                    Ui.column
                        [ Ui.spacing 4 ]
                        (List.map
                            (\( discordUserId, discordUser ) ->
                                Ui.row
                                    [ Ui.spacing 8, Ui.Font.size 14 ]
                                    [ Ui.el [ Ui.width (Ui.px 150) ] (Ui.text (Discord.idToString discordUserId))
                                    , discordUserLabel discordUser
                                    , Ui.el
                                        [ Ui.width (Ui.px 200) ]
                                        (case discordUser of
                                            FullData_ForAdmin data ->
                                                linkedToView adminData data.linkedTo

                                            BasicData_ForAdmin _ ->
                                                Ui.none

                                            NeedsAuthAgain_ForAdmin data ->
                                                linkedToView adminData data.linkedTo
                                        )
                                    ]
                            )
                            (SeqDict.toList discordUsers)
                        )
        ]


userLabel : BackendUser -> Element msg
userLabel user =
    Ui.row
        [ Ui.spacing 8, Ui.width Ui.shrink ]
        [ User.profileImage user.icon
        , Ui.el
            [ Ui.width Ui.shrink ]
            (Ui.text (PersonName.toString user.name))
        ]


discordUserLabel : DiscordUserData_ForAdmin -> Element msg
discordUserLabel discordUser =
    Ui.row
        [ Ui.spacing 8, Ui.width Ui.shrink ]
        [ User.profileImage
            (case discordUser of
                FullData_ForAdmin data ->
                    data.icon

                BasicData_ForAdmin data ->
                    data.icon

                NeedsAuthAgain_ForAdmin data ->
                    data.icon
            )
        , Ui.el
            [ Ui.width Ui.shrink ]
            (case discordUser of
                FullData_ForAdmin data ->
                    Ui.text data.user.username

                BasicData_ForAdmin data ->
                    Ui.text data.user.username

                NeedsAuthAgain_ForAdmin data ->
                    Ui.text data.user.username
            )
        ]


linkedToView : AdminData -> Id UserId -> Element msg
linkedToView adminData userId =
    case NonemptyDict.get userId adminData.users of
        Just user ->
            Ui.row [ Ui.spacing 8, Ui.width Ui.shrink ] [ User.profileImage user.icon, Ui.text (PersonName.toString user.name) ]

        Nothing ->
            Ui.none


addUserRowButtonId : HtmlId
addUserRowButtonId =
    Dom.id "admin_adduserRowButton"


userTableCellButtonId : UserTableId -> UserColumn -> HtmlId
userTableCellButtonId userTableId userColumn =
    "admin_userTableCellButton_"
        ++ userTableIdToDomId userTableId
        ++ userColumnToTitle userColumn
        |> Dom.id


userTableIdToDomId : UserTableId -> String
userTableIdToDomId userTableId =
    case userTableId of
        ExistingUserId userId ->
            "a_" ++ Id.toString userId ++ "_"

        NewUserId index ->
            "b_" ++ String.fromInt index ++ "_"


saveUserChangesButtonId : HtmlId
saveUserChangesButtonId =
    Dom.id "admin_saveUserChangesButton"


userTableView :
    UserTable
    -> NonemptyDict (Id UserId) BackendUser
    -> SeqDict (Id UserId) Time.Posix
    -> Element Msg
userTableView tableState users twoFactorAuthentication =
    Ui.Table.viewWithState
        tableAttributes
        (userTableColumns tableState twoFactorAuthentication)
        tableState.table
        (List.map
            (\( userId, user ) ->
                ( ExistingUserId userId
                , case SeqDict.get userId tableState.changedUsers of
                    Just change ->
                        change

                    Nothing ->
                        userToEditUser user
                )
            )
            (NonemptyDict.toList users)
            ++ List.indexedMap (\index user -> ( NewUserId index, user )) (Array.toList tableState.newUsers)
        )


tableAttributes : List (Ui.Attribute msg)
tableAttributes =
    [ Ui.width Ui.fill
    , Ui.borderWith { top = 1, bottom = 1, left = 0, right = 0 }
    , cellBorderColor
    ]


cellBorderColor : Ui.Attribute msg
cellBorderColor =
    Ui.borderColor MyUi.buttonBorder


type UserColumn
    = NameColumn
    | EmailAddressColumn


validateColumn : UserColumn -> String -> Result String ()
validateColumn column text =
    case column of
        NameColumn ->
            case PersonName.fromString text of
                Ok _ ->
                    Ok ()

                Err error ->
                    Err error

        EmailAddressColumn ->
            case EmailAddress.fromString text of
                Just _ ->
                    Ok ()

                Nothing ->
                    Err "Invalid email"


editCellTextInputId : HtmlId
editCellTextInputId =
    Dom.id "admin_editCellTextInput"


tableCell :
    Bool
    -> UserTable
    -> UserColumn
    -> ( UserTableId, EditedBackendUser )
    -> Element Msg
tableCell isEmail state column ( userTableId, user ) =
    let
        isEditing : Maybe String
        isEditing =
            case state.editingCell of
                Just editingCell ->
                    if editingCell.column == column && editingCell.userId == userTableId then
                        Just editingCell.text

                    else
                        Nothing

                Nothing ->
                    Nothing
    in
    case isEditing of
        Just text ->
            Ui.el
                [ Ui.Font.size 14 ]
                ((if isEmail then
                    Ui.Input.email

                  else
                    Ui.Input.text
                 )
                    [ Ui.width Ui.fill
                    , Ui.height Ui.fill
                    , Ui.paddingXY 8 4
                    , Ui.Events.onLoseFocus (EditCellLostFocus userTableId column)
                    , Dom.idToString editCellTextInputId |> Ui.id
                    , Ui.rounded 0
                    , Html.Events.on "keydown"
                        (Json.Decode.map2 Tuple.pair
                            (Json.Decode.field "shiftKey" Json.Decode.bool)
                            (Json.Decode.field "key" Json.Decode.string)
                            |> Json.Decode.andThen
                                (\( shift, key ) ->
                                    if key == "Enter" then
                                        Json.Decode.succeed (EnterKeyInEditCell userTableId column)

                                    else if key == "Tab" then
                                        Json.Decode.succeed (TabKeyInEditCell shift)

                                    else if key == "Escape" then
                                        Json.Decode.succeed EscapeKeyInEditCell

                                    else
                                        Json.Decode.fail ""
                                )
                        )
                        |> Ui.htmlAttribute
                    ]
                    { onChange = TypedEditCell
                    , text = text
                    , placeholder = Nothing
                    , label = Ui.Input.labelHidden "Edit cell"
                    }
                )

        Nothing ->
            let
                text : String
                text =
                    localChangeToText column user
            in
            case validateColumn column text of
                Ok _ ->
                    Ui.el
                        [ Ui.Events.onMouseDown (PressedEditCell userTableId column)
                        , Ui.Font.size 14
                        , Ui.paddingXY 8 4
                        , cellBackgroundColor userTableId state
                        , Ui.height Ui.fill
                        , Ui.contentCenterY
                        , userTableCellButtonId userTableId column |> Dom.idToString |> Ui.id
                        ]
                        (Ui.text text)

                Err error ->
                    Ui.el
                        [ Ui.Events.onMouseDown (PressedEditCell userTableId column)
                        , Ui.height Ui.fill
                        , Ui.contentCenterY
                        , Ui.Font.size 14
                        , Ui.paddingWith { left = 8, right = 8, top = 4, bottom = 16 }
                        , cellBackgroundColor userTableId state
                        , Ui.borderColor MyUi.errorColor
                        , Ui.border 1
                        , userTableCellButtonId userTableId column |> Dom.idToString |> Ui.id
                        , Ui.inFront
                            (Ui.el
                                [ Ui.alignBottom
                                , Ui.Font.size 12
                                , Ui.Font.color MyUi.white
                                , Ui.background MyUi.errorColor
                                , Ui.move (Ui.down 1)
                                , Ui.width Ui.shrink
                                , Ui.paddingXY 4 0
                                ]
                                (Ui.text error)
                            )
                        ]
                        (Ui.text text)


cellBackgroundColor : UserTableId -> UserTable -> Ui.Attribute msg
cellBackgroundColor userTableId state =
    case userTableId of
        ExistingUserId userId ->
            if SeqSet.member userId state.deletedUsers then
                Ui.background deleteColor

            else if SeqDict.member userId state.changedUsers then
                Ui.background editColor

            else
                Ui.noAttr

        NewUserId _ ->
            Ui.background newRowColor


newRowColor : Ui.Color
newRowColor =
    Ui.rgb 63 89 63


localChangeToText : UserColumn -> EditedBackendUser -> String
localChangeToText column localChange =
    case column of
        NameColumn ->
            localChange.name

        EmailAddressColumn ->
            localChange.email


editColor : Ui.Color
editColor =
    Ui.rgb 122 115 87


deleteColor : Ui.Color
deleteColor =
    Ui.rgb 126 90 90


type RowButtonType
    = DeleteButton
    | ResetButton (Id UserId)


userColumnToTitle : UserColumn -> String
userColumnToTitle userColumn =
    case userColumn of
        NameColumn ->
            "Name"

        EmailAddressColumn ->
            "Email"


userTableColumns :
    UserTable
    -> SeqDict (Id UserId) Time.Posix
    -> Ui.Table.Config Table.Model rowState ( UserTableId, EditedBackendUser ) Msg
userTableColumns tableState twoFactorAuthentication =
    Table.tableConfig
        (Dom.id "Admin_userTable")
        True
        UserTableMsg
        identity
        [ { title = ""
          , view =
                \( userTableId, _ ) ->
                    let
                        showButton : RowButtonType
                        showButton =
                            case userTableId of
                                ExistingUserId userId ->
                                    if SeqDict.member userId tableState.changedUsers then
                                        ResetButton userId

                                    else if SeqSet.member userId tableState.deletedUsers then
                                        ResetButton userId

                                    else
                                        DeleteButton

                                NewUserId _ ->
                                    DeleteButton
                    in
                    Ui.el
                        [ cellBackgroundColor userTableId tableState
                        , Ui.paddingWith { left = 8, right = 4, top = 0, bottom = 0 }
                        , Ui.height Ui.fill
                        , Ui.contentCenterY
                        ]
                        (case showButton of
                            DeleteButton ->
                                MyUi.deleteButton (deleteUserButtonId userTableId) (PressedDeleteUser userTableId)

                            ResetButton userId ->
                                resetButton (Dom.id "Admin_resetUser") (PressedResetUser userId)
                        )
          , sortBy = Nothing
          }
        , { title = userColumnToTitle NameColumn
          , view = tableCell False tableState NameColumn
          , sortBy = Just (List.sortBy (\( _, user ) -> user.name))
          }
        , { title = userColumnToTitle EmailAddressColumn
          , view = tableCell True tableState EmailAddressColumn
          , sortBy = Just (List.sortBy (\( _, user ) -> user.email))
          }
        , { title = "Created at"
          , view =
                \( userTableId, user ) ->
                    Ui.el
                        [ Ui.paddingXY 8 4
                        , Ui.Font.size 14
                        , Ui.contentCenterY
                        , cellBackgroundColor userTableId tableState
                        , Ui.height Ui.fill
                        ]
                        (Ui.text (MyUi.datestamp user.createdAt))
          , sortBy = Just (List.sortBy (\( _, user ) -> Time.posixToMillis user.createdAt))
          }
        , { title = "Admin"
          , view =
                \( userTableId, user ) ->
                    Ui.el
                        [ cellBackgroundColor userTableId tableState, Ui.height Ui.fill ]
                        (Ui.el
                            [ Ui.width Ui.shrink, Ui.centerX, Ui.centerY ]
                            (Ui.Input.checkbox
                                [ Ui.id ("admin_isAdmin_" ++ userTableIdToDomId userTableId) ]
                                { onChange = ToggleIsAdmin userTableId
                                , icon = Nothing
                                , checked = user.isAdmin
                                , label = Ui.Input.labelHidden "Is admin"
                                }
                            )
                        )
          , sortBy = Nothing
          }
        , { title = "Has 2FA"
          , view =
                \( userTableId, _ ) ->
                    Ui.el
                        [ cellBackgroundColor userTableId tableState
                        , Ui.Font.size 14
                        , Ui.paddingXY 8 4
                        , Ui.height Ui.fill
                        ]
                        (case userTableId of
                            ExistingUserId userId ->
                                case SeqDict.get userId twoFactorAuthentication of
                                    Just enabledAt ->
                                        Ui.text (MyUi.datestamp enabledAt)

                                    Nothing ->
                                        Ui.none

                            NewUserId _ ->
                                Ui.none
                        )
          , sortBy = Nothing
          }
        ]


resetButton : HtmlId -> msg -> Element msg
resetButton htmlId onPress =
    Ui.el
        [ Ui.Input.button onPress
        , Ui.id (Dom.idToString htmlId)
        , MyUi.hoverText "Reset"
        , Ui.padding 3
        , Ui.background (Ui.rgb 50 100 255)
        , Ui.Font.color MyUi.white
        , Ui.rounded 4
        , Ui.width Ui.shrink
        , Ui.Shadow.shadows
            [ { x = 0, y = 1, size = 0, blur = 2, color = Ui.rgba 0 0 0 0.1 } ]
        ]
        Icons.reset


logSection : Bool -> Time.Zone -> BackendUser -> AdminData -> Model -> Element Msg
logSection isMobile2 timezone user adminData model =
    let
        pageIndex : Int
        pageIndex =
            Id.toInt adminData.logs.currentPage

        pageCount : Int
        pageCount =
            Pagination.pageCount adminData.logs
    in
    section
        0
        user.expandedSections
        LogSection
        [ MyUi.simpleButton
            (Dom.id "admin_toggleHiddenLogs")
            (PressedShowHiddenLogs (not model.showHiddenLogs))
            (Ui.text
                (if model.showHiddenLogs then
                    "Hide hidden logs"

                 else
                    "Show hidden logs"
                )
            )
            |> Ui.el [ Ui.paddingXY 8 0 ]
        , Pagination.viewPage
            logSectionId
            (\logId log ->
                if log.isHidden && not model.showHiddenLogs then
                    Ui.none

                else
                    Log.view
                        isMobile2
                        log.isHidden
                        timezone
                        { onPressCopyLink = PressedCopyLogLink logId
                        , onPressCopy = PressedCopyText
                        , onPressHide = PressedHideLog logId
                        , onPressUnhide = PressedUnhideLog logId
                        }
                        (Just logId == model.copiedLogLink)
                        (Just logId == model.highlightLog)
                        { time = log.time, log = log.log }
            )
            adminData.logs
        , (if pageCount <= 1 then
            []

           else if pageCount <= maxVisiblePages then
            [ List.range 0 (pageCount - 1) ]

           else if pageIndex - logPageRange <= 2 then
            [ List.range 0 (2 + logPageRange * 2)
            , List.range (pageCount - 3) (pageCount - 1)
            ]

           else if pageIndex + logPageRange >= pageCount - 2 then
            [ List.range 0 2
            , List.range (pageCount - 3 - logPageRange * 2) (pageCount - 1)
            ]

           else
            [ List.range 0 2
            , List.range (pageIndex - logPageRange) (pageIndex + logPageRange)
            , List.range (pageCount - 3) (pageCount - 1)
            ]
          )
            |> List.map (List.map (\index -> ( index, String.fromInt (index + 1) )))
            |> MyUi.radioRowWithSeparators
                [ Ui.width Ui.shrink, Ui.centerX ]
                pageIndex
                (\index -> Id.fromInt index |> PressedLogPage)
                (Ui.el [ Ui.paddingXY 2 0 ] (Ui.text "..."))
        ]


logPageRange : number
logPageRange =
    4


maxVisiblePages : number
maxVisiblePages =
    20


section : Int -> SeqSet AdminUiSection -> AdminUiSection -> List (Element Msg) -> Element Msg
section paddingX expandedSections section2 content =
    let
        title : Element msg
        title =
            User.sectionToString section2
                |> Ui.text
                |> Ui.el
                    [ Ui.Font.size 20
                    , Ui.Font.bold
                    , Ui.width Ui.shrink
                    , if Env.isProduction then
                        Ui.background MyUi.errorColor

                      else
                        Ui.noAttr
                    ]
    in
    if SeqSet.member section2 expandedSections then
        Ui.column
            [ Ui.Events.onDoubleClick (DoublePressedCollapseSection section2)
            , Ui.background MyUi.background3
            , Ui.rounded 8
            , Ui.paddingBottom 8
            ]
            [ Ui.row
                [ Ui.Input.button (PressedCollapseSection section2)
                , Ui.spacing 4
                , Dom.idToString (collapseSectionButtonId section2) |> Ui.id
                , Ui.padding 8
                ]
                [ Ui.el [ Ui.move (Ui.up 2), Ui.width Ui.shrink ] Icons.collapseContainer
                , title
                ]
            , Ui.column [ Ui.paddingXY paddingX 0, Ui.spacing 8 ] content
            ]

    else
        Ui.row
            [ Ui.Input.button (PressedExpandSection section2)
            , Ui.spacing 4
            , Dom.idToString (expandSectionButtonId section2) |> Ui.id
            , Ui.padding 8
            , Ui.background MyUi.background3
            , Ui.rounded 8
            ]
            [ Ui.el [ Ui.move (Ui.up 2), Ui.width Ui.shrink ] Icons.expandContainer
            , title
            ]


expandSectionButtonId : AdminUiSection -> HtmlId
expandSectionButtonId section2 =
    Dom.id ("admin_expandSectionButton_" ++ User.sectionToString section2)


collapseSectionButtonId : AdminUiSection -> HtmlId
collapseSectionButtonId section2 =
    Dom.id ("admin_collapseSectionButton_" ++ User.sectionToString section2)


applyChangesToBackendUsers :
    Id UserId
    ->
        { b
            | time : Time.Posix
            , changedUsers : SeqDict (Id UserId) EditedBackendUser
            , newUsers : Array EditedBackendUser
            , deletedUsers : SeqSet (Id UserId)
        }
    -> NonemptyDict (Id UserId) BackendUser
    -> Result UsersChangeError (NonemptyDict (Id UserId) BackendUser)
applyChangesToBackendUsers changedBy { time, changedUsers, newUsers, deletedUsers } users =
    let
        resultA : Result UsersChangeError (NonemptyDict (Id UserId) BackendUser)
        resultA =
            SeqDict.foldl
                (\userId change state ->
                    case state of
                        Ok users2 ->
                            case NonemptyDict.get userId users2 of
                                Just user ->
                                    case applyChangeToBackendUser change user of
                                        Ok newUser ->
                                            Ok (NonemptyDict.insert userId newUser users2)

                                        Err () ->
                                            Err InvalidChangesToUser

                                Nothing ->
                                    Err (ChangesAppliedToNonExistentUser userId)

                        Err _ ->
                            state
                )
                (Ok users)
                changedUsers

        resultB : Result UsersChangeError (SeqDict (Id UserId) BackendUser)
        resultB =
            Array.foldl
                (\a state ->
                    case
                        T3
                            state
                            (PersonName.fromString a.name)
                            (EmailAddress.fromString a.email)
                    of
                        T3 (Ok dict) (Ok name) (Just email) ->
                            let
                                getId : Int -> Id UserId
                                getId id =
                                    if
                                        NonemptyDict.member (Id.fromInt id) users
                                            || SeqDict.member (Id.fromInt id) dict
                                    then
                                        getId (id + 1)

                                    else
                                        Id.fromInt id
                            in
                            SeqDict.insert
                                (getId (SeqDict.size dict + NonemptyDict.size users))
                                (User.init time name email a.isAdmin)
                                dict
                                |> Ok

                        _ ->
                            Err InvalidNewUser
                )
                (Ok SeqDict.empty)
                newUsers
    in
    case ( resultB, resultA ) of
        ( Ok newUsersOk, Ok ok ) ->
            let
                deletedUsers2 : SeqDict (Id UserId) ()
                deletedUsers2 =
                    SeqSet.toList deletedUsers
                        |> List.map (\id -> ( id, () ))
                        |> SeqDict.fromList

                allUsers : SeqDict (Id UserId) BackendUser
                allUsers =
                    SeqDict.union (SeqDict.diff (NonemptyDict.toSeqDict ok) deletedUsers2) newUsersOk
            in
            case SeqDict.get changedBy allUsers of
                Just currentUser ->
                    if currentUser.isAdmin then
                        let
                            emailAddresses : Set String
                            emailAddresses =
                                SeqDict.values allUsers
                                    |> List.map (\user -> EmailAddress.toString user.email)
                                    |> Set.fromList
                        in
                        case ( NonemptyDict.fromSeqDict allUsers, Set.size emailAddresses == SeqDict.size allUsers ) of
                            ( Just nonempty, True ) ->
                                Ok nonempty

                            ( _, False ) ->
                                Err EmailAddressesAreNotUnique

                            ( Nothing, _ ) ->
                                Err CantDeleteYourself

                    else
                        Err CantRemoveAdminRoleFromYourself

                Nothing ->
                    Err CantDeleteYourself

        ( _, Err error ) ->
            Err error

        ( Err error, _ ) ->
            Err error


applyChangeToBackendUser :
    EditedBackendUser
    -> BackendUser
    -> Result () BackendUser
applyChangeToBackendUser change user =
    case T2 (PersonName.fromString change.name) (EmailAddress.fromString change.email) of
        T2 (Ok name) (Just email) ->
            { user
                | name = name
                , isAdmin = change.isAdmin
                , email = email
            }
                |> Ok

        _ ->
            Err ()
