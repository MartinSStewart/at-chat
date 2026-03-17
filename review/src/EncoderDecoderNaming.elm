module EncoderDecoderNaming exposing (rule)

{-| Enforces that encoder/decoder functions are named `encodeTypeName` and `decodeTypeName`
rather than `typeNameEncoder` and `typeNameDecoder`.
-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Node as Node exposing (Node(..))
import Review.Fix as Fix
import Review.Rule as Rule exposing (Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchema "EncoderDecoderNaming" ()
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.fromModuleRuleSchema


declarationVisitor : Node Declaration -> () -> ( List (Rule.Error {}), () )
declarationVisitor (Node _ declaration) context =
    case declaration of
        FunctionDeclaration function ->
            let
                nameNode : Node String
                nameNode =
                    Node.value function.declaration |> .name

                name : String
                name =
                    Node.value nameNode
            in
            ( checkName nameNode name, context )

        _ ->
            ( [], context )


checkName : Node String -> String -> List (Rule.Error {})
checkName nameNode name =
    if String.endsWith "Encoder" name && String.length name > 7 then
        let
            typeName : String
            typeName =
                String.dropRight 7 name

            suggested : String
            suggested =
                "encode" ++ capitalize typeName
        in
        [ Rule.errorWithFix
            { message = name ++ " should be named " ++ suggested
            , details =
                [ "Encoders should be named `encodeTypeName` instead of `typeNameEncoder` for consistency." ]
            }
            (Node.range nameNode)
            [ Fix.replaceRangeBy (Node.range nameNode) suggested ]
        ]

    else if String.endsWith "Decoder" name && String.length name > 7 then
        let
            typeName : String
            typeName =
                String.dropRight 7 name

            suggested : String
            suggested =
                "decode" ++ capitalize typeName
        in
        [ Rule.errorWithFix
            { message = name ++ " should be named " ++ suggested
            , details =
                [ "Decoders should be named `decodeTypeName` instead of `typeNameDecoder` for consistency." ]
            }
            (Node.range nameNode)
            [ Fix.replaceRangeBy (Node.range nameNode) suggested ]
        ]

    else if String.endsWith "Encode" name && String.length name > 6 then
        let
            typeName : String
            typeName =
                String.dropRight 6 name

            suggested : String
            suggested =
                "encode" ++ capitalize typeName
        in
        [ Rule.errorWithFix
            { message = name ++ " should be named " ++ suggested
            , details =
                [ "Encoders should be named `encodeTypeName` instead of `typeNameEncode` for consistency." ]
            }
            (Node.range nameNode)
            [ Fix.replaceRangeBy (Node.range nameNode) suggested ]
        ]

    else if String.endsWith "Decode" name && String.length name > 6 then
        let
            typeName : String
            typeName =
                String.dropRight 6 name

            suggested : String
            suggested =
                "decode" ++ capitalize typeName
        in
        [ Rule.errorWithFix
            { message = name ++ " should be named " ++ suggested
            , details =
                [ "Decoders should be named `decodeTypeName` instead of `typeNameDecode` for consistency." ]
            }
            (Node.range nameNode)
            [ Fix.replaceRangeBy (Node.range nameNode) suggested ]
        ]

    else
        []


capitalize : String -> String
capitalize str =
    case String.uncons str of
        Just ( first, rest ) ->
            String.fromChar (Char.toUpper first) ++ rest

        Nothing ->
            str
