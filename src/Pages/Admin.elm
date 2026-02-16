module Pages.Admin exposing
    ( AdminChange(..)
    , EditedBackendUser
    , EditingCell
    , InitAdminData
    , Model
    , Msg(..)
    , ToBackend(..)
    , ToFrontend(..)
    , UserColumn(..)
    , UserTable
    , UserTableId(..)
    , UsersChangeError(..)
    , applyChangesToBackendUsers
    , init
    , logSectionId
    , update
    , updateAdmin
    , updateFromBackend
    , view
    )

import Array exposing (Array)
import Array.Extra
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Navigation as BrowserNavigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Task as Task
import Effect.Time as Time
import EmailAddress
import Env
import Html.Events
import Icons
import Id exposing (Id, UserId)
import Json.Decode
import LocalState exposing (AdminData, AdminStatus(..), LocalState, LogWithTime, PrivateVapidKey)
import Log
import MyUi
import NonemptyDict exposing (NonemptyDict)
import Pagination exposing (Pagination)
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


type Msg
    = PressedLogPage Int
    | PressedCopyLogLink Int
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
    | ToggleIsAdmin UserTableId Bool


type ToBackend
    = LogPaginationToBackend Pagination.ToBackend


type ToFrontend
    = LogPaginationToFrontend (Pagination.ToFrontend LogWithTime)


type alias Model =
    { highlightLog : Maybe Int
    , copiedLogLink : Maybe Int
    , userTable : UserTable
    , submitError : Maybe UsersChangeError
    , logs : Pagination LogWithTime
    }


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
    { lastLogPageViewed : Int
    , users : NonemptyDict (Id UserId) BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict (Id UserId) Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Slack.ClientSecret
    , openRouterKey : Maybe String
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
    | LogPageChanged Int
    | SetEmailNotificationsEnabled Bool
    | SetPrivateVapidKey PrivateVapidKey
    | SetPublicVapidKey String
    | SetSlackClientSecret (Maybe Slack.ClientSecret)
    | SetOpenRouterKey (Maybe String)


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


init : Pagination LogWithTime -> { highlightLog : Maybe Int } -> ( Model, Maybe AdminChange )
init logs { highlightLog } =
    ( { highlightLog = highlightLog
      , copiedLogLink = Nothing
      , userTable =
            { table = Table.init 1
            , changedUsers = SeqDict.empty
            , editingCell = Nothing
            , newUsers = Array.empty
            , deletedUsers = SeqSet.empty
            }
      , submitError = Nothing
      , logs = logs
      }
    , case highlightLog of
        Just index ->
            LogPageChanged (index // Pagination.pageSize) |> Just

        Nothing ->
            Nothing
    )


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

        LogPageChanged logPageIndex ->
            { local
                | adminData =
                    IsAdmin
                        { adminData
                            | users =
                                NonemptyDict.updateIfExists changedBy (\user -> { user | lastLogPageViewed = logPageIndex }) adminData.users
                        }
            }

        SetEmailNotificationsEnabled isEnabled ->
            { local | adminData = IsAdmin { adminData | emailNotificationsEnabled = isEnabled } }

        SetPrivateVapidKey privateVapidKey ->
            { local | adminData = IsAdmin { adminData | privateVapidKey = privateVapidKey } }

        SetPublicVapidKey publicVapidKey ->
            { local | publicVapidKey = publicVapidKey }

        SetSlackClientSecret clientSecret ->
            { local | adminData = IsAdmin { adminData | slackClientSecret = clientSecret } }

        SetOpenRouterKey openRouterKey ->
            { local | adminData = IsAdmin { adminData | openRouterKey = openRouterKey } }


update :
    BrowserNavigation.Key
    -> Time.Posix
    -> AdminData
    -> LocalState
    -> Msg
    -> Model
    -> ( Model, Command FrontendOnly ToBackend Msg, Maybe AdminChange )
update navigationKey time adminData localState msg model =
    case msg of
        PressedLogPage index ->
            let
                ( logs, cmd ) =
                    Pagination.setPage index model.logs
            in
            ( { model | logs = logs }
            , Command.map LogPaginationToBackend identity cmd
            , LogPageChanged index |> Just
            )

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
            , Nothing
            )

        PressedCollapseSection section2 ->
            ( model
            , Command.none
            , CollapseSection section2 |> Just
            )

        PressedExpandSection section2 ->
            ( model
            , Command.none
            , ExpandSection section2 |> Just
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

                        helper : EditedBackendUser -> ( UserTable, Command FrontendOnly ToBackend Msg, Maybe AdminChange )
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
                            , Nothing
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
                                            ( userTable2, Command.none, Nothing )

                        NewUserId index ->
                            case Array.get index userTable2.newUsers of
                                Just change ->
                                    helper change

                                Nothing ->
                                    ( userTable2, Command.none, Nothing )
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
                    , Nothing
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
                    , Nothing
                    )
                )
                model

        FocusedOnEditCell ->
            ( model, Ports.textInputSelectAll editCellTextInputId, Nothing )

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
                    , Nothing
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
                        |> Just
                    )

                Err error ->
                    ( { model | submitError = Just error }, Command.none, Nothing )

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
                            , Nothing
                            )

                        Nothing ->
                            ( userTable, Command.none, Nothing )
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
                    , Nothing
                    )
                )
                model

        EscapeKeyInEditCell ->
            updateUserTable (\userTable -> ( { userTable | editingCell = Nothing }, Command.none, Nothing )) model

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
                    , Nothing
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
                            , Nothing
                            )

                        NewUserId index ->
                            ( { userTable | newUsers = Array.Extra.removeAt index userTable.newUsers }
                            , Command.none
                            , Nothing
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
                    , Nothing
                    )
                )
                model

        DoublePressedCollapseSection section2 ->
            ( model
            , Dom.getElement (collapseSectionButtonId section2)
                |> Task.andThen (\{ element } -> Dom.setViewport 0 (element.y - 8))
                |> Task.attempt (\_ -> ScrolledToSection)
            , Nothing
            )

        ScrolledToSection ->
            ( model, Command.none, Nothing )

        UserTableMsg tableMsg ->
            updateUserTable
                (\userTable -> ( { userTable | table = Table.update tableMsg userTable.table }, Command.none, Nothing ))
                model

        ToggledEmailNotifications isChecked ->
            ( model, Command.none, Just (SetEmailNotificationsEnabled isChecked) )

        ToggleIsAdmin userTableId isAdmin ->
            updateUserTable
                (\userTableState ->
                    ( handleTogglingAdmin userTableId userTableState isAdmin adminData
                    , Command.none
                    , Nothing
                    )
                )
                model


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
    (UserTable -> ( UserTable, Command FrontendOnly ToBackend Msg, Maybe AdminChange ))
    -> Model
    -> ( Model, Command FrontendOnly ToBackend Msg, Maybe AdminChange )
updateUserTable updateFunc model =
    let
        ( userTable, cmd, localChange ) =
            updateFunc model.userTable
    in
    ( { model | userTable = userTable }, cmd, localChange )


updateFromBackend : ToFrontend -> Model -> ( Model, Command FrontendOnly ToBackend Msg )
updateFromBackend toFrontend model =
    case toFrontend of
        LogPaginationToFrontend data ->
            ( { model | logs = Pagination.updateFromBackend data model.logs }, Command.none )


logSectionId : HtmlId
logSectionId =
    Dom.id "Pages.Admin_logSection"


deleteUserButtonId : UserTableId -> HtmlId
deleteUserButtonId userTableId =
    "Admin_deleteUserButton_" ++ userTableIdToDomId userTableId |> Dom.id


view : Time.Zone -> AdminData -> BackendUser -> Model -> Element Msg
view timezone adminData user model =
    Ui.el
        (if Env.isProduction then
            [ Ui.borderWith { left = 6, right = 0, top = 0, bottom = 0 }, Ui.borderColor MyUi.errorColor ]

         else
            []
        )
        (MyUi.column
            [ Ui.scrollable, Ui.paddingWith { left = 8, right = 8, top = 16, bottom = 64 }, Ui.Font.color (Ui.rgb 0 0 0) ]
            [ userSection user adminData model
            , logSection timezone user model
            ]
        )


userSection : BackendUser -> AdminData -> Model -> Element Msg
userSection user adminData model =
    let
        emailNotificationsLabel : { element : Element msg, id : Ui.Input.Label }
        emailNotificationsLabel =
            MyUi.label
                (Dom.id "emailNotificationsId")
                []
                (Ui.text "Email notifications enabled (does not affect login emails)")
    in
    section
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
                        , MyUi.primaryButton saveUserChangesButtonId PressedSaveUserChanges "Save changes"
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
    , Ui.background (Ui.rgb 255 255 255)
    ]


cellBorderColor : Ui.Attribute msg
cellBorderColor =
    Ui.borderColor (Ui.rgb 237 242 247)


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
    Ui.rgb 200 255 200


localChangeToText : UserColumn -> EditedBackendUser -> String
localChangeToText column localChange =
    case column of
        NameColumn ->
            localChange.name

        EmailAddressColumn ->
            localChange.email


editColor : Ui.Color
editColor =
    Ui.rgb 250 240 210


deleteColor : Ui.Color
deleteColor =
    Ui.rgb 250 220 220


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
                                Ui.el
                                    [ Ui.Input.button (PressedResetUser userId)
                                    , Ui.id "Admin_resetUser"
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


logSection : Time.Zone -> BackendUser -> Model -> Element Msg
logSection timezone user model =
    case Pagination.currentPage model.logs of
        Just logs ->
            let
                pageIndex =
                    Pagination.currentPageIndex model.logs

                pageCount : Int
                pageCount =
                    Maybe.withDefault 1 (Pagination.totalPages model.logs)
            in
            section
                user.expandedSections
                LogSection
                [ List.indexedMap
                    (\index log ->
                        let
                            logIndex : Int
                            logIndex =
                                Pagination.pageSize * pageIndex + index
                        in
                        Log.view
                            timezone
                            (PressedCopyLogLink logIndex)
                            (Just logIndex == model.copiedLogLink)
                            (Just logIndex == model.highlightLog)
                            log
                    )
                    (Array.toList logs)
                    |> Ui.column [ Ui.id (Dom.idToString logSectionId) ]
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
                        PressedLogPage
                        (Ui.el [ Ui.paddingXY 2 0 ] (Ui.text "..."))
                ]

        Nothing ->
            section user.expandedSections LogSection [ Ui.text "Loading..." ]


logPageRange : number
logPageRange =
    4


maxVisiblePages : number
maxVisiblePages =
    20


section : SeqSet AdminUiSection -> AdminUiSection -> List (Element Msg) -> Element Msg
section expandedSections section2 content =
    let
        title : Element msg
        title =
            User.sectionToString section2
                |> Ui.text
                |> Ui.el [ Ui.Font.size 20, Ui.Font.bold ]
    in
    MyUi.column
        [ Ui.background MyUi.secondaryGray
        , Ui.rounded 8
        , Ui.padding 8
        ]
        (if SeqSet.member section2 expandedSections then
            Ui.el
                [ Ui.Events.onDoubleClick (DoublePressedCollapseSection section2) ]
                (Ui.row
                    [ Ui.Input.button (PressedCollapseSection section2)
                    , Ui.spacing 4
                    , Ui.width Ui.shrink
                    , Dom.idToString (collapseSectionButtonId section2) |> Ui.id
                    ]
                    [ Ui.el [ Ui.move (Ui.up 2), Ui.width Ui.shrink ] Icons.collapseContainer
                    , title
                    ]
                )
                :: content

         else
            [ Ui.row
                [ Ui.Input.button (PressedExpandSection section2)
                , Ui.spacing 4
                , Dom.idToString (expandSectionButtonId section2) |> Ui.id
                ]
                [ Ui.el [ Ui.move (Ui.up 2), Ui.width Ui.shrink ] Icons.expandContainer
                , title
                ]
            ]
        )


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
