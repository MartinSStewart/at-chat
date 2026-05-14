module NoRedundantUiAttributes exposing (rule)

{-| Reports redundant or conflicting elm-ui attributes used together in the
same attribute list, and provides automatic fixes that remove the redundant
attribute(s) while keeping the last one (which is the one that takes effect
at runtime).

Examples of what gets flagged:

  - `Ui.paddingLeft` followed by `Ui.paddingWith` (the shorthand overrides the
    per-side value).
  - `Ui.alignTop` and `Ui.alignBottom` in the same list (an element can only
    align in one direction at a time).
  - `Ui.width Ui.fill` (this is already the default behavior).
  - `Ui.Font.color red` and `Ui.Font.color blue` in the same list (the second
    one overrides the first).

-}

import Array exposing (Array)
import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Review.Fix as Fix
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Rule)
import Set exposing (Set)


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
        Application ((Node _ (FunctionOrValue [ "Ui" ] _)) :: (Node _ (ListExpr elements)) :: _) ->
            ( checkAttributeList True context.lookupTable elements, context )

        Application (_ :: rest) ->
            ( List.concatMap
                (\expression2 ->
                    case Node.value (unwrapParens expression2) of
                        ListExpr elements ->
                            checkAttributeList False context.lookupTable elements

                        _ ->
                            []
                )
                rest
            , context
            )

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


type Removal
    = WidthFillDefault ClassifiedAttr
    | OverriddenBy ClassifiedAttr ClassifiedAttr


checkAttributeList : Bool -> ModuleNameLookupTable -> List (Node Expression) -> List (Rule.Error {})
checkAttributeList canRemoveWidthFill lookupTable elements =
    let
        rangeArray : Array Range
        rangeArray =
            Array.fromList (List.map Node.range elements)

        classified : List ( Int, ClassifiedAttr )
        classified =
            elements
                |> List.indexedMap Tuple.pair
                |> List.filterMap (\( i, el ) -> classify canRemoveWidthFill lookupTable el |> Maybe.map (Tuple.pair i))

        removals : List ( Int, Removal )
        removals =
            buildRemovals classified

        removalSet : Set Int
        removalSet =
            Set.fromList (List.map Tuple.first removals)
    in
    List.map (buildErrorForRemoval rangeArray removalSet) removals


buildRemovals : List ( Int, ClassifiedAttr ) -> List ( Int, Removal )
buildRemovals classified =
    List.filterMap
        (\( i, attr ) ->
            if attr.isWidthFillDefault then
                Just ( i, WidthFillDefault attr )

            else
                case findLaterOverride i attr.class classified of
                    Just later ->
                        Just ( i, OverriddenBy attr later )

                    Nothing ->
                        Nothing
        )
        classified


findLaterOverride : Int -> AttrClass -> List ( Int, ClassifiedAttr ) -> Maybe ClassifiedAttr
findLaterOverride i class classified =
    classified
        |> List.filter (\( j, other ) -> j > i && conflicts class other.class)
        |> List.head
        |> Maybe.map Tuple.second


buildErrorForRemoval : Array Range -> Set Int -> ( Int, Removal ) -> Rule.Error {}
buildErrorForRemoval rangeArray removalSet ( index, removal ) =
    let
        isLastInBlock : Bool
        isLastInBlock =
            not (Set.member (index + 1) removalSet)

        fixes : List Fix.Fix
        fixes =
            if isLastInBlock then
                case computeBlockRange index removalSet rangeArray of
                    Just range ->
                        [ Fix.removeRange range ]

                    Nothing ->
                        []

            else
                []
    in
    case removal of
        WidthFillDefault attr ->
            Rule.errorWithFix
                { message = "Ui.width Ui.fill is the default and can be removed"
                , details =
                    [ "Elements in elm-ui already have `Ui.width Ui.fill` applied by default, so adding this attribute explicitly has no effect."
                    , "Remove this attribute to reduce noise in the attribute list."
                    ]
                }
                attr.range
                fixes

        OverriddenBy earlier later ->
            Rule.errorWithFix
                { message = earlier.displayName ++ " is overridden by a later " ++ later.displayName
                , details =
                    [ "Both " ++ earlier.displayName ++ " and " ++ later.displayName ++ " appear in the same attribute list and either set the same property or conflict with each other."
                    , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                    ]
                }
                earlier.range
                fixes


computeBlockRange : Int -> Set Int -> Array Range -> Maybe Range
computeBlockRange endIndex removalSet rangeArray =
    let
        startIndex : Int
        startIndex =
            findBlockStart endIndex removalSet
    in
    case ( Array.get startIndex rangeArray, Array.get endIndex rangeArray ) of
        ( Just startRange, Just endRange ) ->
            if startIndex == 0 then
                case Array.get (endIndex + 1) rangeArray of
                    Just next ->
                        Just { start = startRange.start, end = next.start }

                    Nothing ->
                        Just { start = startRange.start, end = endRange.end }

            else
                case Array.get (startIndex - 1) rangeArray of
                    Just prev ->
                        Just { start = prev.end, end = endRange.end }

                    Nothing ->
                        Just { start = startRange.start, end = endRange.end }

        _ ->
            Nothing


findBlockStart : Int -> Set Int -> Int
findBlockStart i removalSet =
    if Set.member (i - 1) removalSet then
        findBlockStart (i - 1) removalSet

    else
        i


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


classify : Bool -> ModuleNameLookupTable -> Node Expression -> Maybe ClassifiedAttr
classify canRemoveWidthFill lookupTable rawNode =
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
                                                canRemoveWidthFill && moduleName == [ "Ui" ] && name == "width" && isUiFill lookupTable args
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
