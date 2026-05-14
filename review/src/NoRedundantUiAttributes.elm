module NoRedundantUiAttributes exposing (rule)

{-| Reports redundant or conflicting elm-ui attributes used together in the
same attribute list.

Examples of what gets flagged:

  - `Ui.paddingLeft` and `Ui.paddingWith` in the same list (the shorthand
    overrides the per-side value).
  - `Ui.alignTop` and `Ui.alignBottom` in the same list (an element can only
    align in one direction at a time).
  - `Ui.width Ui.fill` (this is already the default behavior).
  - `Ui.Font.color red` and `Ui.Font.color blue` in the same list (the second
    one overrides the first).

-}

import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchemaUsingContextCreator "NoRedundantUiAttributes" initContext
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


type alias Context =
    { lookupTable : ModuleNameLookupTable }


initContext : Rule.ContextCreator () Context
initContext =
    Rule.initContextCreator (\lookupTable () -> { lookupTable = lookupTable })
        |> Rule.withModuleNameLookupTable


expressionVisitor : Node Expression -> Context -> ( List (Rule.Error {}), Context )
expressionVisitor expression context =
    case Node.value (unwrapParens expression) of
        ListExpr elements ->
            ( checkAttributeList context.lookupTable elements, context )

        _ ->
            ( [], context )


unwrapParens : Node Expression -> Node Expression
unwrapParens node =
    case Node.value node of
        ParenthesizedExpression inner ->
            unwrapParens inner

        _ ->
            node


type AttrClass
    = Width
    | Height
    | WidthMin
    | WidthMax
    | HeightMin
    | HeightMax
    | Spacing
    | PaddingShorthand
    | PaddingSide Side
    | BorderShorthand
    | BorderColor
    | BorderGradient
    | BorderRounded
    | BackgroundColor
    | BackgroundGradient
    | Opacity
    | Move
    | Rotate
    | Scale
    | AlignX
    | AlignY
    | ContentAlignX
    | ContentAlignY
    | FontColor
    | FontGradient
    | FontSize
    | FontFamily
    | FontLineHeight
    | FontLetterSpacing
    | FontWordSpacing
    | FontAlign
    | FontWeight
    | FontVariants
    | FontItalic
    | FontUnderline
    | FontStrike


type Side
    = SideLeft
    | SideRight
    | SideTop
    | SideBottom


type alias ClassifiedAttr =
    { range : Range
    , class : AttrClass
    , displayName : String
    , isWidthFillDefault : Bool
    }


checkAttributeList : ModuleNameLookupTable -> List (Node Expression) -> List (Rule.Error {})
checkAttributeList lookupTable elements =
    let
        classified : List ClassifiedAttr
        classified =
            List.filterMap (classify lookupTable) elements

        defaultErrors : List (Rule.Error {})
        defaultErrors =
            classified
                |> List.filter .isWidthFillDefault
                |> List.map widthFillDefaultError

        conflictErrors : List (Rule.Error {})
        conflictErrors =
            findConflicts classified
    in
    defaultErrors ++ conflictErrors


widthFillDefaultError : ClassifiedAttr -> Rule.Error {}
widthFillDefaultError attr =
    Rule.error
        { message = "Ui.width Ui.fill is the default and can be removed"
        , details =
            [ "Elements in elm-ui already have `Ui.width Ui.fill` applied by default, so adding this attribute explicitly has no effect."
            , "Remove this attribute to reduce noise in the attribute list."
            ]
        }
        attr.range


findConflicts : List ClassifiedAttr -> List (Rule.Error {})
findConflicts attrs =
    findConflictsHelp [] attrs []


findConflictsHelp : List ClassifiedAttr -> List ClassifiedAttr -> List (Rule.Error {}) -> List (Rule.Error {})
findConflictsHelp seen remaining acc =
    case remaining of
        [] ->
            List.reverse acc

        current :: rest ->
            case firstConflict current seen of
                Just earlier ->
                    findConflictsHelp (current :: seen) rest (conflictError earlier current :: acc)

                Nothing ->
                    findConflictsHelp (current :: seen) rest acc


firstConflict : ClassifiedAttr -> List ClassifiedAttr -> Maybe ClassifiedAttr
firstConflict current seen =
    case seen of
        [] ->
            Nothing

        prior :: rest ->
            if conflicts current.class prior.class then
                Just prior

            else
                firstConflict current rest


conflictError : ClassifiedAttr -> ClassifiedAttr -> Rule.Error {}
conflictError earlier current =
    Rule.error
        { message = current.displayName ++ " is redundant with " ++ earlier.displayName
        , details =
            [ "Both " ++ earlier.displayName ++ " and " ++ current.displayName ++ " appear in the same attribute list and either set the same property or conflict with each other."
            , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
            ]
        }
        current.range


conflicts : AttrClass -> AttrClass -> Bool
conflicts a b =
    case ( a, b ) of
        ( PaddingShorthand, PaddingShorthand ) ->
            True

        ( PaddingShorthand, PaddingSide _ ) ->
            True

        ( PaddingSide _, PaddingShorthand ) ->
            True

        ( PaddingSide s1, PaddingSide s2 ) ->
            s1 == s2

        ( BackgroundColor, BackgroundGradient ) ->
            True

        ( BackgroundGradient, BackgroundColor ) ->
            True

        ( FontColor, FontGradient ) ->
            True

        ( FontGradient, FontColor ) ->
            True

        _ ->
            a == b


classify : ModuleNameLookupTable -> Node Expression -> Maybe ClassifiedAttr
classify lookupTable rawNode =
    let
        node : Node Expression
        node =
            unwrapParens rawNode
    in
    case Node.value node of
        FunctionOrValue _ name ->
            ModuleNameLookupTable.moduleNameFor lookupTable node
                |> Maybe.andThen
                    (\moduleName ->
                        classNameOf moduleName name
                            |> Maybe.map
                                (\class ->
                                    { range = Node.range rawNode
                                    , class = class
                                    , displayName = displayNameOf moduleName name
                                    , isWidthFillDefault = False
                                    }
                                )
                    )

        Application (fnNode :: args) ->
            case Node.value fnNode of
                FunctionOrValue _ name ->
                    ModuleNameLookupTable.moduleNameFor lookupTable fnNode
                        |> Maybe.andThen
                            (\moduleName ->
                                classNameOf moduleName name
                                    |> Maybe.map
                                        (\class ->
                                            { range = Node.range rawNode
                                            , class = class
                                            , displayName = displayNameOf moduleName name
                                            , isWidthFillDefault =
                                                moduleName == [ "Ui" ] && name == "width" && isUiFill lookupTable args
                                            }
                                        )
                            )

                _ ->
                    Nothing

        _ ->
            Nothing


isUiFill : ModuleNameLookupTable -> List (Node Expression) -> Bool
isUiFill lookupTable args =
    case args of
        [ singleArg ] ->
            let
                arg : Node Expression
                arg =
                    unwrapParens singleArg
            in
            case Node.value arg of
                FunctionOrValue _ "fill" ->
                    ModuleNameLookupTable.moduleNameFor lookupTable arg == Just [ "Ui" ]

                _ ->
                    False

        _ ->
            False


displayNameOf : ModuleName -> String -> String
displayNameOf moduleName name =
    String.join "." (moduleName ++ [ name ])


classNameOf : ModuleName -> String -> Maybe AttrClass
classNameOf moduleName name =
    case moduleName of
        [ "Ui" ] ->
            uiClass name

        [ "Ui", "Font" ] ->
            uiFontClass name

        _ ->
            Nothing


uiClass : String -> Maybe AttrClass
uiClass name =
    case name of
        "width" ->
            Just Width

        "height" ->
            Just Height

        "widthMin" ->
            Just WidthMin

        "widthMax" ->
            Just WidthMax

        "heightMin" ->
            Just HeightMin

        "heightMax" ->
            Just HeightMax

        "spacing" ->
            Just Spacing

        "spacingWith" ->
            Just Spacing

        "padding" ->
            Just PaddingShorthand

        "paddingXY" ->
            Just PaddingShorthand

        "paddingWith" ->
            Just PaddingShorthand

        "paddingLeft" ->
            Just (PaddingSide SideLeft)

        "paddingRight" ->
            Just (PaddingSide SideRight)

        "paddingTop" ->
            Just (PaddingSide SideTop)

        "paddingBottom" ->
            Just (PaddingSide SideBottom)

        "border" ->
            Just BorderShorthand

        "borderWith" ->
            Just BorderShorthand

        "borderColor" ->
            Just BorderColor

        "borderGradient" ->
            Just BorderGradient

        "rounded" ->
            Just BorderRounded

        "roundedWith" ->
            Just BorderRounded

        "background" ->
            Just BackgroundColor

        "backgroundGradient" ->
            Just BackgroundGradient

        "opacity" ->
            Just Opacity

        "move" ->
            Just Move

        "rotate" ->
            Just Rotate

        "scale" ->
            Just Scale

        "alignTop" ->
            Just AlignY

        "alignBottom" ->
            Just AlignY

        "centerY" ->
            Just AlignY

        "alignLeft" ->
            Just AlignX

        "alignRight" ->
            Just AlignX

        "centerX" ->
            Just AlignX

        "contentTop" ->
            Just ContentAlignY

        "contentBottom" ->
            Just ContentAlignY

        "contentCenterY" ->
            Just ContentAlignY

        "contentLeft" ->
            Just ContentAlignX

        "contentRight" ->
            Just ContentAlignX

        "contentCenterX" ->
            Just ContentAlignX

        _ ->
            Nothing


uiFontClass : String -> Maybe AttrClass
uiFontClass name =
    case name of
        "color" ->
            Just FontColor

        "gradient" ->
            Just FontGradient

        "size" ->
            Just FontSize

        "family" ->
            Just FontFamily

        "lineHeight" ->
            Just FontLineHeight

        "letterSpacing" ->
            Just FontLetterSpacing

        "wordSpacing" ->
            Just FontWordSpacing

        "alignLeft" ->
            Just FontAlign

        "alignRight" ->
            Just FontAlign

        "center" ->
            Just FontAlign

        "justify" ->
            Just FontAlign

        "weight" ->
            Just FontWeight

        "bold" ->
            Just FontWeight

        "variants" ->
            Just FontVariants

        "italic" ->
            Just FontItalic

        "underline" ->
            Just FontUnderline

        "strike" ->
            Just FontStrike

        _ ->
            Nothing
